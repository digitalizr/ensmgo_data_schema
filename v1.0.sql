-- PostgreSQL Database Schema for Energy Management SaaS Platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Audit trail for tracking changes
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(255) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by UUID,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address VARCHAR(50)
);

-- Roles and permissions
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(resource, action)
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

-- Users and authentication
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(50),
    password_hash VARCHAR(255),
    role_id UUID REFERENCES roles(id),
    is_active BOOLEAN DEFAULT TRUE,
    require_password_change BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID
);

-- Companies and organizational structure
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address TEXT,
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    status VARCHAR(50) NOT NULL DEFAULT 'lead',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE facilities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    location TEXT,
    address TEXT,
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- User-company relationships
CREATE TABLE user_companies (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, company_id)
);

-- Device models and manufacturers
CREATE TABLE manufacturers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    website VARCHAR(255),
    support_email VARCHAR(255),
    support_phone VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE device_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    manufacturer_id UUID NOT NULL REFERENCES manufacturers(id),
    model_name VARCHAR(255) NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    description TEXT,
    specifications JSONB,
    firmware_version VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(manufacturer_id, model_name)
);

-- Smart meters
CREATE TABLE smart_meters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    serial_number VARCHAR(255) NOT NULL UNIQUE,
    model_id UUID NOT NULL REFERENCES device_models(id),
    status VARCHAR(50) NOT NULL DEFAULT 'available',
    firmware_version VARCHAR(100),
    last_seen TIMESTAMP WITH TIME ZONE,
    last_reading JSONB,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Edge gateways
CREATE TABLE edge_gateways (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    serial_number VARCHAR(255) NOT NULL UNIQUE,
    model_id UUID NOT NULL REFERENCES device_models(id),
    mac_address VARCHAR(50),
    status VARCHAR(50) NOT NULL DEFAULT 'available',
    firmware_version VARCHAR(100),
    last_seen TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE edge_gateway_specifications (
    gateway_id UUID PRIMARY KEY REFERENCES edge_gateways(id) ON DELETE CASCADE,
    os VARCHAR(100),
    os_version VARCHAR(100),
    cpu VARCHAR(100),
    memory VARCHAR(100),
    storage VARCHAR(100),
    connectivity TEXT[],
    additional_specs TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE edge_gateway_ip_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gateway_id UUID NOT NULL REFERENCES edge_gateways(id) ON DELETE CASCADE,
    ip_address VARCHAR(50) NOT NULL,
    port INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE edge_gateway_connection_details (
    gateway_id UUID PRIMARY KEY REFERENCES edge_gateways(id) ON DELETE CASCADE,
    ssh_username VARCHAR(100),
    ssh_password VARCHAR(255),
    ssh_key TEXT,
    web_interface_url VARCHAR(255),
    web_username VARCHAR(100),
    web_password VARCHAR(255),
    api_key VARCHAR(255),
    notes TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Assignments
CREATE TABLE assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    edge_gateway_id UUID REFERENCES edge_gateways(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    UNIQUE(edge_gateway_id)
);

CREATE TABLE smart_meter_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    smart_meter_id UUID NOT NULL REFERENCES smart_meters(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    UNIQUE(smart_meter_id)
);

-- Subscription plans
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    price_monthly DECIMAL(10, 2) NOT NULL,
    price_annually DECIMAL(10, 2) NOT NULL,
    meters_allowed INTEGER NOT NULL,
    users_allowed INTEGER NOT NULL,
    features JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    start_date DATE NOT NULL,
    end_date DATE,
    billing_cycle VARCHAR(50) NOT NULL,
    next_billing_date DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50),
    payment_details JSONB,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Invoices
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    invoice_number VARCHAR(100) NOT NULL UNIQUE,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    payment_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payments
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255),
    status VARCHAR(50) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Settings and configurations
CREATE TABLE settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category VARCHAR(100) NOT NULL,
    key VARCHAR(100) NOT NULL,
    value TEXT,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(category, key)
);

-- Integration configurations
CREATE TABLE integration_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    integration_type VARCHAR(50) NOT NULL,
    config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Insert default roles
INSERT INTO roles (id, name, description, is_system) VALUES 
(uuid_generate_v4(), 'admin', 'Administrator with full access', TRUE),
(uuid_generate_v4(), 'operator', 'Operator with management access', TRUE),
(uuid_generate_v4(), 'technician', 'Technical staff with limited access', TRUE),
(uuid_generate_v4(), 'customer', 'Customer with access to their own data', TRUE);

-- Insert default subscription plans
INSERT INTO subscription_plans (name, description, price_monthly, price_annually, meters_allowed, users_allowed, features, is_active) VALUES
('Basic', 'Basic monitoring and reporting', 299.99, 2999.90, 10, 5, '["Basic monitoring", "Standard reports", "Email support"]', TRUE),
('Professional', 'Advanced monitoring and custom reports', 699.99, 6999.90, 25, 15, '["Advanced monitoring", "Custom reports", "Priority email support", "API access"]', TRUE),
('Enterprise', 'Comprehensive solution for large organizations', 1299.99, 12999.90, 50, 25, '["Real-time monitoring", "Advanced analytics", "24/7 phone support", "API access", "Custom integrations"]', TRUE),
('Unlimited', 'Unlimited resources and dedicated support', 2499.99, 24999.90, 999, 100, '["Unlimited monitoring", "Advanced analytics", "24/7 dedicated support", "Full API access", "Custom integrations", "Dedicated account manager"]', TRUE);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_companies_name ON companies(name);
CREATE INDEX idx_facilities_company_id ON facilities(company_id);
CREATE INDEX idx_departments_facility_id ON departments(facility_id);
CREATE INDEX idx_smart_meters_serial_number ON smart_meters(serial_number);
CREATE INDEX idx_smart_meters_model_id ON smart_meters(model_id);
CREATE INDEX idx_edge_gateways_serial_number ON edge_gateways(serial_number);
CREATE INDEX idx_edge_gateways_model_id ON edge_gateways(model_id);
CREATE INDEX idx_assignments_company_id ON assignments(company_id);
CREATE INDEX idx_assignments_edge_gateway_id ON assignments(edge_gateway_id);
CREATE INDEX idx_smart_meter_assignments_assignment_id ON smart_meter_assignments(assignment_id);
CREATE INDEX idx_smart_meter_assignments_smart_meter_id ON smart_meter_assignments(smart_meter_id);
CREATE INDEX idx_subscriptions_company_id ON subscriptions(company_id);
CREATE INDEX idx_subscriptions_plan_id ON subscriptions(plan_id);
CREATE INDEX idx_invoices_subscription_id ON invoices(subscription_id);
CREATE INDEX idx_invoices_company_id ON invoices(company_id);
CREATE INDEX idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX idx_payments_company_id ON payments(company_id);

-- Create audit trigger function
CREATE OR REPLACE FUNCTION process_audit() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_data, changed_by)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', row_to_json(OLD), current_setting('app.current_user_id', TRUE)::uuid);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', row_to_json(OLD), row_to_json(NEW), current_setting('app.current_user_id', TRUE)::uuid);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs (table_name, record_id, action, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', row_to_json(NEW), current_setting('app.current_user_id', TRUE)::uuid);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to main tables
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users FOR EACH ROW EXECUTE FUNCTION process_audit();
CREATE TRIGGER audit_companies AFTER INSERT OR UPDATE OR DELETE ON companies FOR EACH ROW EXECUTE FUNCTION process_audit();
CREATE TRIGGER audit_facilities AFTER INSERT OR UPDATE OR DELETE ON facilities FOR EACH ROW EXECUTE FUNCTION process_audit();
CREATE TRIGGER audit_departments AFTER INSERT OR UPDATE OR DELETE ON departments FOR EACH ROW EXECUTE FUNCTION process_audit();
CREATE TRIGGER audit_smart_meters AFTER INSERT OR UPDATE OR DELETE ON smart_meters FOR EACH ROW EXECUTE FUNCTION process_audit();
CREATE TRIGGER audit_edge_gateways AFTER INSERT OR UPDATE OR DELETE ON edge_gateways FOR EACH ROW EXECUTE FUNCTION process_audit();
CREATE TRIGGER audit_assignments AFTER INSERT OR UPDATE OR DELETE ON assignments FOR EACH ROW EXECUTE FUNCTION process_audit();
CREATE TRIGGER audit_subscriptions AFTER INSERT OR UPDATE OR DELETE ON subscriptions FOR EACH ROW EXECUTE FUNCTION process_audit();
CREATE TRIGGER audit_invoices AFTER INSERT OR UPDATE OR DELETE ON invoices FOR EACH ROW EXECUTE FUNCTION process_audit();
CREATE TRIGGER audit_payments AFTER INSERT OR UPDATE OR DELETE ON payments FOR EACH ROW EXECUTE FUNCTION process_audit();

