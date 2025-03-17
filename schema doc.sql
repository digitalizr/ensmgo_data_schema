-- ==========================================================
-- 1. ENUM TYPES
-- ==========================================================
CREATE TYPE public.company_status AS ENUM (
    'lead',
    'contacted',
    'proposal',
    'contracted',
    'rejected'
);

-- ==========================================================
-- 2. AI MODELS & RECOMMENDATIONS
-- ==========================================================

CREATE TABLE public.ai_models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    model_type VARCHAR(50) NOT NULL CHECK (model_type IN ('prediction', 'anomaly_detection', 'recommendation')),
    parameters JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.ai_recommendations (
    id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    company_id UUID NOT NULL,
    facility_id UUID,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    recommendation_type VARCHAR(50) NOT NULL CHECK (recommendation_type IN ('efficiency', 'cost_saving', 'maintenance', 'operational')),
    potential_savings NUMERIC(15,2),
    implementation_cost NUMERIC(15,2),
    payback_period NUMERIC(10,2),
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high')),
    status VARCHAR(20) DEFAULT 'new' CHECK (status IN ('new', 'in_progress', 'implemented', 'rejected')),
    implemented_at TIMESTAMPTZ,
    implemented_by UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================================
-- 3. ALERTS & NOTIFICATIONS
-- ==========================================================

CREATE TABLE public.alert_rules (
    id SERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN ('consumption', 'demand', 'price', 'system', 'efficiency')),
    parameter VARCHAR(100) NOT NULL,
    operator VARCHAR(20) NOT NULL CHECK (operator IN ('gt', 'lt', 'eq', 'gte', 'lte', 'between', 'outside')),
    threshold_value NUMERIC(15,3) NOT NULL,
    threshold_value2 NUMERIC(15,3),
    time_window VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.alert_subscriptions (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    alert_rule_id INTEGER REFERENCES public.alert_rules(id),
    alert_type VARCHAR(50) CHECK (alert_type IN ('consumption', 'demand', 'price', 'system', 'efficiency')),
    severity VARCHAR(20) CHECK (severity IN ('info', 'warning', 'critical')),
    contact_point_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CHECK (alert_rule_id IS NOT NULL OR (alert_type IS NOT NULL AND severity IS NOT NULL))
);

CREATE TABLE public.alerts (
    id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    alert_rule_id INTEGER REFERENCES public.alert_rules(id),
    company_id UUID NOT NULL,
    smart_meter_id UUID,
    edge_gateway_id UUID,
    facility_id UUID,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN ('consumption', 'demand', 'price', 'system', 'efficiency')),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved')),
    value NUMERIC(15,3),
    threshold NUMERIC(15,3),
    triggered_at TIMESTAMPTZ NOT NULL,
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================================
-- 4. ASSIGNMENTS & LOGS
-- ==========================================================

CREATE TABLE public.assignments (
    id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    company_id UUID NOT NULL,
    facility_id UUID,
    department_id UUID,
    edge_gateway_id UUID,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID,
    updated_by UUID
);

CREATE TABLE public.audit_logs (
    id UUID DEFAULT public.uuid_generate_v4() PRIMARY KEY,
    table_name VARCHAR(255) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by UUID,
    changed_at TIMESTAMPTZ DEFAULT now(),
    ip_address VARCHAR(50)
);
