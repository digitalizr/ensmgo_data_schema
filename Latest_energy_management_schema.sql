--
-- PostgreSQL database dump
--

-- Dumped from database version 15.12 (Debian 15.12-1.pgdg120+1)
-- Dumped by pg_dump version 15.12 (Debian 15.12-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: company_status; Type: TYPE; Schema: public; Owner: admin
--

CREATE TYPE public.company_status AS ENUM (
    'lead',
    'contacted',
    'proposal',
    'contracted',
    'rejected'
);


ALTER TYPE public.company_status OWNER TO admin;

--
-- Name: process_audit(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.process_audit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.process_audit() OWNER TO admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_models; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.ai_models (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    model_type character varying(50) NOT NULL,
    parameters jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ai_models_model_type_check CHECK (((model_type)::text = ANY ((ARRAY['prediction'::character varying, 'anomaly_detection'::character varying, 'recommendation'::character varying])::text[])))
);


ALTER TABLE public.ai_models OWNER TO admin;

--
-- Name: ai_models_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.ai_models_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ai_models_id_seq OWNER TO admin;

--
-- Name: ai_models_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.ai_models_id_seq OWNED BY public.ai_models.id;


--
-- Name: ai_recommendations; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.ai_recommendations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    company_id uuid NOT NULL,
    facility_id uuid,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    recommendation_type character varying(50) NOT NULL,
    potential_savings numeric(15,2),
    implementation_cost numeric(15,2),
    payback_period numeric(10,2),
    priority character varying(20),
    status character varying(20) DEFAULT 'new'::character varying,
    implemented_at timestamp with time zone,
    implemented_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ai_recommendations_priority_check CHECK (((priority)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying])::text[]))),
    CONSTRAINT ai_recommendations_recommendation_type_check CHECK (((recommendation_type)::text = ANY ((ARRAY['efficiency'::character varying, 'cost_saving'::character varying, 'maintenance'::character varying, 'operational'::character varying])::text[]))),
    CONSTRAINT ai_recommendations_status_check CHECK (((status)::text = ANY ((ARRAY['new'::character varying, 'in_progress'::character varying, 'implemented'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.ai_recommendations OWNER TO admin;

--
-- Name: alert_rules; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.alert_rules (
    id integer NOT NULL,
    company_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    alert_type character varying(50) NOT NULL,
    parameter character varying(100) NOT NULL,
    operator character varying(20) NOT NULL,
    threshold_value numeric(15,3) NOT NULL,
    threshold_value2 numeric(15,3),
    time_window character varying(50) NOT NULL,
    is_active boolean DEFAULT true,
    severity character varying(20) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT alert_rules_alert_type_check CHECK (((alert_type)::text = ANY ((ARRAY['consumption'::character varying, 'demand'::character varying, 'price'::character varying, 'system'::character varying, 'efficiency'::character varying])::text[]))),
    CONSTRAINT alert_rules_operator_check CHECK (((operator)::text = ANY ((ARRAY['gt'::character varying, 'lt'::character varying, 'eq'::character varying, 'gte'::character varying, 'lte'::character varying, 'between'::character varying, 'outside'::character varying])::text[]))),
    CONSTRAINT alert_rules_severity_check CHECK (((severity)::text = ANY ((ARRAY['info'::character varying, 'warning'::character varying, 'critical'::character varying])::text[])))
);


ALTER TABLE public.alert_rules OWNER TO admin;

--
-- Name: alert_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.alert_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alert_rules_id_seq OWNER TO admin;

--
-- Name: alert_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.alert_rules_id_seq OWNED BY public.alert_rules.id;


--
-- Name: alert_subscriptions; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.alert_subscriptions (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    alert_rule_id integer,
    alert_type character varying(50),
    severity character varying(20),
    contact_point_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT alert_subscriptions_alert_type_check CHECK (((alert_type)::text = ANY ((ARRAY['consumption'::character varying, 'demand'::character varying, 'price'::character varying, 'system'::character varying, 'efficiency'::character varying])::text[]))),
    CONSTRAINT alert_subscriptions_check CHECK (((alert_rule_id IS NOT NULL) OR ((alert_type IS NOT NULL) AND (severity IS NOT NULL)))),
    CONSTRAINT alert_subscriptions_severity_check CHECK (((severity)::text = ANY ((ARRAY['info'::character varying, 'warning'::character varying, 'critical'::character varying])::text[])))
);


ALTER TABLE public.alert_subscriptions OWNER TO admin;

--
-- Name: alert_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.alert_subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alert_subscriptions_id_seq OWNER TO admin;

--
-- Name: alert_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.alert_subscriptions_id_seq OWNED BY public.alert_subscriptions.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.alerts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    alert_rule_id integer,
    company_id uuid NOT NULL,
    smart_meter_id uuid,
    edge_gateway_id uuid,
    facility_id uuid,
    title character varying(255) NOT NULL,
    description text,
    alert_type character varying(50) NOT NULL,
    severity character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    value numeric(15,3),
    threshold numeric(15,3),
    triggered_at timestamp with time zone NOT NULL,
    acknowledged_at timestamp with time zone,
    acknowledged_by uuid,
    resolved_at timestamp with time zone,
    resolved_by uuid,
    resolution_notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT alerts_alert_type_check CHECK (((alert_type)::text = ANY ((ARRAY['consumption'::character varying, 'demand'::character varying, 'price'::character varying, 'system'::character varying, 'efficiency'::character varying])::text[]))),
    CONSTRAINT alerts_severity_check CHECK (((severity)::text = ANY ((ARRAY['info'::character varying, 'warning'::character varying, 'critical'::character varying])::text[]))),
    CONSTRAINT alerts_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'acknowledged'::character varying, 'resolved'::character varying])::text[])))
);


ALTER TABLE public.alerts OWNER TO admin;

--
-- Name: assignments; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.assignments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    company_id uuid NOT NULL,
    facility_id uuid,
    department_id uuid,
    edge_gateway_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.assignments OWNER TO admin;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    table_name character varying(255) NOT NULL,
    record_id uuid NOT NULL,
    action character varying(50) NOT NULL,
    old_data jsonb,
    new_data jsonb,
    changed_by uuid,
    changed_at timestamp with time zone DEFAULT now(),
    ip_address character varying(50)
);


ALTER TABLE public.audit_logs OWNER TO admin;

--
-- Name: companies; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.companies (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    address text,
    contact_name character varying(255),
    contact_email character varying(255),
    contact_phone character varying(50),
    status public.company_status DEFAULT 'lead'::public.company_status NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.companies OWNER TO admin;

--
-- Name: company_tariffs; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.company_tariffs (
    id integer NOT NULL,
    company_id uuid NOT NULL,
    tariff_plan_id integer NOT NULL,
    facility_id uuid,
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.company_tariffs OWNER TO admin;

--
-- Name: company_tariffs_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.company_tariffs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.company_tariffs_id_seq OWNER TO admin;

--
-- Name: company_tariffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.company_tariffs_id_seq OWNED BY public.company_tariffs.id;


--
-- Name: contact_points; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.contact_points (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    contact_type character varying(50) NOT NULL,
    contact_value character varying(255) NOT NULL,
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT contact_points_contact_type_check CHECK (((contact_type)::text = ANY ((ARRAY['email'::character varying, 'sms'::character varying, 'push'::character varying, 'webhook'::character varying])::text[])))
);


ALTER TABLE public.contact_points OWNER TO admin;

--
-- Name: contact_points_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.contact_points_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contact_points_id_seq OWNER TO admin;

--
-- Name: contact_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.contact_points_id_seq OWNED BY public.contact_points.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.departments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    facility_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.departments OWNER TO admin;

--
-- Name: device_models; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.device_models (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    manufacturer_id uuid NOT NULL,
    model_name character varying(255) NOT NULL,
    device_type character varying(50) NOT NULL,
    description text,
    specifications jsonb,
    firmware_version character varying(100),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.device_models OWNER TO admin;

--
-- Name: edge_gateway_connection_details; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.edge_gateway_connection_details (
    gateway_id uuid NOT NULL,
    ssh_username character varying(100),
    ssh_password character varying(255),
    ssh_key text,
    web_interface_url character varying(255),
    web_username character varying(100),
    web_password character varying(255),
    api_key character varying(255),
    notes text,
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.edge_gateway_connection_details OWNER TO admin;

--
-- Name: edge_gateway_ip_addresses; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.edge_gateway_ip_addresses (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    gateway_id uuid NOT NULL,
    ip_address character varying(50) NOT NULL,
    port integer,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.edge_gateway_ip_addresses OWNER TO admin;

--
-- Name: edge_gateway_specifications; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.edge_gateway_specifications (
    gateway_id uuid NOT NULL,
    os character varying(100),
    os_version character varying(100),
    cpu character varying(100),
    memory character varying(100),
    storage character varying(100),
    connectivity text[],
    additional_specs text,
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.edge_gateway_specifications OWNER TO admin;

--
-- Name: edge_gateways; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.edge_gateways (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    serial_number character varying(255) NOT NULL,
    model_id uuid NOT NULL,
    mac_address character varying(50),
    status character varying(50) DEFAULT 'available'::character varying NOT NULL,
    firmware_version character varying(100),
    last_seen timestamp with time zone,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.edge_gateways OWNER TO admin;

--
-- Name: facilities; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.facilities (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    company_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    location text,
    address text,
    contact_name character varying(255),
    contact_email character varying(255),
    contact_phone character varying(50),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.facilities OWNER TO admin;

--
-- Name: integration_configs; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.integration_configs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    integration_type character varying(255) NOT NULL,
    config_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.integration_configs OWNER TO admin;

--
-- Name: invoice_items; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.invoice_items (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    invoice_id uuid NOT NULL,
    description text,
    quantity integer,
    price numeric(10,2),
    amount numeric(10,2),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.invoice_items OWNER TO admin;

--
-- Name: invoices; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.invoices (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    company_id uuid NOT NULL,
    subscription_id uuid,
    amount numeric(10,2),
    due_date timestamp with time zone,
    status character varying(50) DEFAULT 'unpaid'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.invoices OWNER TO admin;

--
-- Name: ip_edge_gateways; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.ip_edge_gateways (
    id integer NOT NULL,
    edge_gateway_id uuid NOT NULL,
    ip_address character varying(45) NOT NULL,
    port integer NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ip_edge_gateways OWNER TO admin;

--
-- Name: ip_edge_gateways_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.ip_edge_gateways_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ip_edge_gateways_id_seq OWNER TO admin;

--
-- Name: ip_edge_gateways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.ip_edge_gateways_id_seq OWNED BY public.ip_edge_gateways.id;


--
-- Name: manufacturers; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.manufacturers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    website character varying(255),
    support_email character varying(255),
    support_phone character varying(50),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.manufacturers OWNER TO admin;

--
-- Name: payments; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.payments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    invoice_id uuid NOT NULL,
    payment_method character varying(50),
    payment_date timestamp with time zone DEFAULT now(),
    amount numeric(10,2),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.payments OWNER TO admin;

--
-- Name: permissions; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    resource character varying(100) NOT NULL,
    action character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.permissions OWNER TO admin;

--
-- Name: report_templates; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.report_templates (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    report_type character varying(50) NOT NULL,
    template_data jsonb NOT NULL,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT report_templates_report_type_check CHECK (((report_type)::text = ANY ((ARRAY['consumption'::character varying, 'demand'::character varying, 'cost'::character varying, 'efficiency'::character varying, 'sustainability'::character varying])::text[])))
);


ALTER TABLE public.report_templates OWNER TO admin;

--
-- Name: report_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.report_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.report_templates_id_seq OWNER TO admin;

--
-- Name: report_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.report_templates_id_seq OWNED BY public.report_templates.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.reports (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    report_template_id integer,
    company_id uuid NOT NULL,
    facility_id uuid,
    user_id uuid NOT NULL,
    report_type character varying(50) NOT NULL,
    format character varying(20) NOT NULL,
    parameters jsonb,
    time_range_start timestamp with time zone,
    time_range_end timestamp with time zone,
    file_path character varying(255),
    file_size integer,
    is_scheduled boolean DEFAULT false,
    schedule_frequency character varying(50),
    last_generated timestamp with time zone,
    next_generation timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reports_format_check CHECK (((format)::text = ANY ((ARRAY['pdf'::character varying, 'excel'::character varying, 'csv'::character varying])::text[]))),
    CONSTRAINT reports_report_type_check CHECK (((report_type)::text = ANY ((ARRAY['consumption'::character varying, 'demand'::character varying, 'cost'::character varying, 'efficiency'::character varying, 'sustainability'::character varying])::text[])))
);


ALTER TABLE public.reports OWNER TO admin;

--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.role_permissions (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.role_permissions OWNER TO admin;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.roles OWNER TO admin;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.settings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    key character varying(255) NOT NULL,
    value text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.settings OWNER TO admin;

--
-- Name: smart_meter_assignments; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.smart_meter_assignments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    assignment_id uuid NOT NULL,
    smart_meter_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.smart_meter_assignments OWNER TO admin;

--
-- Name: smart_meters; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.smart_meters (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    serial_number character varying(255) NOT NULL,
    model_id uuid NOT NULL,
    status character varying(50) DEFAULT 'available'::character varying NOT NULL,
    firmware_version character varying(100),
    last_seen timestamp with time zone,
    last_reading jsonb,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.smart_meters OWNER TO admin;

--
-- Name: smart_meters_edge_gateways; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.smart_meters_edge_gateways (
    id integer NOT NULL,
    smart_meter_id uuid NOT NULL,
    edge_gateway_id uuid NOT NULL,
    connection_type character varying(50) DEFAULT 'wired'::character varying NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT smart_meters_edge_gateways_connection_type_check CHECK (((connection_type)::text = ANY ((ARRAY['wired'::character varying, 'wireless'::character varying, 'modbus'::character varying, 'bacnet'::character varying])::text[])))
);


ALTER TABLE public.smart_meters_edge_gateways OWNER TO admin;

--
-- Name: smart_meters_edge_gateways_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.smart_meters_edge_gateways_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.smart_meters_edge_gateways_id_seq OWNER TO admin;

--
-- Name: smart_meters_edge_gateways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.smart_meters_edge_gateways_id_seq OWNED BY public.smart_meters_edge_gateways.id;


--
-- Name: subscription_plans; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.subscription_plans (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    price numeric(10,2),
    features jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.subscription_plans OWNER TO admin;

--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    company_id uuid NOT NULL,
    plan_id uuid NOT NULL,
    start_date timestamp with time zone DEFAULT now(),
    end_date timestamp with time zone,
    status character varying(50) DEFAULT 'active'::character varying NOT NULL,
    payment_method character varying(50),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.subscriptions OWNER TO admin;

--
-- Name: tariff_plans; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.tariff_plans (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    is_time_of_use boolean DEFAULT false,
    currency character varying(3) DEFAULT 'USD'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tariff_plans OWNER TO admin;

--
-- Name: tariff_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.tariff_plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tariff_plans_id_seq OWNER TO admin;

--
-- Name: tariff_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.tariff_plans_id_seq OWNED BY public.tariff_plans.id;


--
-- Name: tariff_rates; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.tariff_rates (
    id integer NOT NULL,
    tariff_plan_id integer NOT NULL,
    rate_type character varying(50) NOT NULL,
    time_of_use_period character varying(50),
    start_time time without time zone,
    end_time time without time zone,
    weekday_only boolean DEFAULT false,
    rate_value numeric(10,5) NOT NULL,
    unit character varying(20) DEFAULT 'kWh'::character varying,
    valid_from date,
    valid_to date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tariff_rates_rate_type_check CHECK (((rate_type)::text = ANY ((ARRAY['fixed'::character varying, 'consumption'::character varying, 'demand'::character varying, 'time_of_use'::character varying])::text[])))
);


ALTER TABLE public.tariff_rates OWNER TO admin;

--
-- Name: tariff_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.tariff_rates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tariff_rates_id_seq OWNER TO admin;

--
-- Name: tariff_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.tariff_rates_id_seq OWNED BY public.tariff_rates.id;


--
-- Name: team; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.team (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    role_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.team OWNER TO admin;

--
-- Name: team_credentials; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.team_credentials (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    team_id uuid NOT NULL,
    generated_password text NOT NULL,
    is_reset boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.team_credentials OWNER TO admin;

--
-- Name: team_permissions; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.team_permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    role_id uuid NOT NULL,
    permission_name character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.team_permissions OWNER TO admin;

--
-- Name: team_roles; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.team_roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    role_name character varying(50) NOT NULL
);


ALTER TABLE public.team_roles OWNER TO admin;

--
-- Name: user_companies; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.user_companies (
    user_id uuid NOT NULL,
    company_id uuid NOT NULL,
    facility_id uuid,
    department_id uuid,
    is_primary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_companies OWNER TO admin;

--
-- Name: user_edge_gateways; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.user_edge_gateways (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    edge_gateway_id uuid NOT NULL,
    access_level character varying(50) DEFAULT 'read'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_edge_gateways_access_level_check CHECK (((access_level)::text = ANY ((ARRAY['read'::character varying, 'write'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.user_edge_gateways OWNER TO admin;

--
-- Name: user_edge_gateways_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.user_edge_gateways_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_edge_gateways_id_seq OWNER TO admin;

--
-- Name: user_edge_gateways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.user_edge_gateways_id_seq OWNED BY public.user_edge_gateways.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    role_id uuid NOT NULL
);


ALTER TABLE public.user_roles OWNER TO admin;

--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_roles_id_seq OWNER TO admin;

--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: user_smart_meters; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.user_smart_meters (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    smart_meter_id uuid NOT NULL,
    access_level character varying(50) DEFAULT 'read'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_smart_meters_access_level_check CHECK (((access_level)::text = ANY ((ARRAY['read'::character varying, 'write'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.user_smart_meters OWNER TO admin;

--
-- Name: user_smart_meters_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.user_smart_meters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_smart_meters_id_seq OWNER TO admin;

--
-- Name: user_smart_meters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.user_smart_meters_id_seq OWNED BY public.user_smart_meters.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(50),
    password_hash character varying(255),
    role_id uuid,
    is_active boolean DEFAULT true,
    require_password_change boolean DEFAULT false,
    last_login timestamp with time zone,
    password_reset_token character varying(255),
    password_reset_expires timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.users OWNER TO admin;

--
-- Name: ai_models id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.ai_models ALTER COLUMN id SET DEFAULT nextval('public.ai_models_id_seq'::regclass);


--
-- Name: alert_rules id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.alert_rules ALTER COLUMN id SET DEFAULT nextval('public.alert_rules_id_seq'::regclass);


--
-- Name: alert_subscriptions id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.alert_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.alert_subscriptions_id_seq'::regclass);


--
-- Name: company_tariffs id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.company_tariffs ALTER COLUMN id SET DEFAULT nextval('public.company_tariffs_id_seq'::regclass);


--
-- Name: contact_points id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.contact_points ALTER COLUMN id SET DEFAULT nextval('public.contact_points_id_seq'::regclass);


--
-- Name: ip_edge_gateways id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.ip_edge_gateways ALTER COLUMN id SET DEFAULT nextval('public.ip_edge_gateways_id_seq'::regclass);


--
-- Name: report_templates id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.report_templates ALTER COLUMN id SET DEFAULT nextval('public.report_templates_id_seq'::regclass);


--
-- Name: smart_meters_edge_gateways id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meters_edge_gateways ALTER COLUMN id SET DEFAULT nextval('public.smart_meters_edge_gateways_id_seq'::regclass);


--
-- Name: tariff_plans id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.tariff_plans ALTER COLUMN id SET DEFAULT nextval('public.tariff_plans_id_seq'::regclass);


--
-- Name: tariff_rates id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.tariff_rates ALTER COLUMN id SET DEFAULT nextval('public.tariff_rates_id_seq'::regclass);


--
-- Name: user_edge_gateways id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_edge_gateways ALTER COLUMN id SET DEFAULT nextval('public.user_edge_gateways_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: user_smart_meters id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_smart_meters ALTER COLUMN id SET DEFAULT nextval('public.user_smart_meters_id_seq'::regclass);


--
-- Name: ai_models ai_models_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.ai_models
    ADD CONSTRAINT ai_models_pkey PRIMARY KEY (id);


--
-- Name: ai_recommendations ai_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.ai_recommendations
    ADD CONSTRAINT ai_recommendations_pkey PRIMARY KEY (id);


--
-- Name: alert_rules alert_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- Name: alert_subscriptions alert_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.alert_subscriptions
    ADD CONSTRAINT alert_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: assignments assignments_edge_gateway_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_edge_gateway_id_key UNIQUE (edge_gateway_id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_tariffs company_tariffs_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.company_tariffs
    ADD CONSTRAINT company_tariffs_pkey PRIMARY KEY (id);


--
-- Name: contact_points contact_points_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.contact_points
    ADD CONSTRAINT contact_points_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: device_models device_models_manufacturer_id_model_name_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.device_models
    ADD CONSTRAINT device_models_manufacturer_id_model_name_key UNIQUE (manufacturer_id, model_name);


--
-- Name: device_models device_models_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.device_models
    ADD CONSTRAINT device_models_pkey PRIMARY KEY (id);


--
-- Name: edge_gateway_connection_details edge_gateway_connection_details_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateway_connection_details
    ADD CONSTRAINT edge_gateway_connection_details_pkey PRIMARY KEY (gateway_id);


--
-- Name: edge_gateway_ip_addresses edge_gateway_ip_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateway_ip_addresses
    ADD CONSTRAINT edge_gateway_ip_addresses_pkey PRIMARY KEY (id);


--
-- Name: edge_gateway_specifications edge_gateway_specifications_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateway_specifications
    ADD CONSTRAINT edge_gateway_specifications_pkey PRIMARY KEY (gateway_id);


--
-- Name: edge_gateways edge_gateways_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateways
    ADD CONSTRAINT edge_gateways_pkey PRIMARY KEY (id);


--
-- Name: edge_gateways edge_gateways_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateways
    ADD CONSTRAINT edge_gateways_serial_number_key UNIQUE (serial_number);


--
-- Name: facilities facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT facilities_pkey PRIMARY KEY (id);


--
-- Name: integration_configs integration_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.integration_configs
    ADD CONSTRAINT integration_configs_pkey PRIMARY KEY (id);


--
-- Name: invoice_items invoice_items_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: ip_edge_gateways ip_edge_gateways_edge_gateway_id_ip_address_port_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.ip_edge_gateways
    ADD CONSTRAINT ip_edge_gateways_edge_gateway_id_ip_address_port_key UNIQUE (edge_gateway_id, ip_address, port);


--
-- Name: ip_edge_gateways ip_edge_gateways_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.ip_edge_gateways
    ADD CONSTRAINT ip_edge_gateways_pkey PRIMARY KEY (id);


--
-- Name: manufacturers manufacturers_name_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.manufacturers
    ADD CONSTRAINT manufacturers_name_key UNIQUE (name);


--
-- Name: manufacturers manufacturers_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.manufacturers
    ADD CONSTRAINT manufacturers_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_name_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_name_key UNIQUE (name);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_resource_action_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_resource_action_key UNIQUE (resource, action);


--
-- Name: report_templates report_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.report_templates
    ADD CONSTRAINT report_templates_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: settings settings_key_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_key_key UNIQUE (key);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: smart_meter_assignments smart_meter_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meter_assignments
    ADD CONSTRAINT smart_meter_assignments_pkey PRIMARY KEY (id);


--
-- Name: smart_meters_edge_gateways smart_meters_edge_gateways_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meters_edge_gateways
    ADD CONSTRAINT smart_meters_edge_gateways_pkey PRIMARY KEY (id);


--
-- Name: smart_meters_edge_gateways smart_meters_edge_gateways_smart_meter_id_edge_gateway_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meters_edge_gateways
    ADD CONSTRAINT smart_meters_edge_gateways_smart_meter_id_edge_gateway_id_key UNIQUE (smart_meter_id, edge_gateway_id);


--
-- Name: smart_meters smart_meters_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meters
    ADD CONSTRAINT smart_meters_pkey PRIMARY KEY (id);


--
-- Name: smart_meters smart_meters_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meters
    ADD CONSTRAINT smart_meters_serial_number_key UNIQUE (serial_number);


--
-- Name: subscription_plans subscription_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: tariff_plans tariff_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.tariff_plans
    ADD CONSTRAINT tariff_plans_pkey PRIMARY KEY (id);


--
-- Name: tariff_rates tariff_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.tariff_rates
    ADD CONSTRAINT tariff_rates_pkey PRIMARY KEY (id);


--
-- Name: team_credentials team_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team_credentials
    ADD CONSTRAINT team_credentials_pkey PRIMARY KEY (id);


--
-- Name: team_credentials team_credentials_team_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team_credentials
    ADD CONSTRAINT team_credentials_team_id_key UNIQUE (team_id);


--
-- Name: team team_email_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_email_key UNIQUE (email);


--
-- Name: team_permissions team_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team_permissions
    ADD CONSTRAINT team_permissions_pkey PRIMARY KEY (id);


--
-- Name: team team_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_pkey PRIMARY KEY (id);


--
-- Name: team_roles team_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team_roles
    ADD CONSTRAINT team_roles_pkey PRIMARY KEY (id);


--
-- Name: team_roles team_roles_role_name_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team_roles
    ADD CONSTRAINT team_roles_role_name_key UNIQUE (role_name);


--
-- Name: user_companies user_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_companies
    ADD CONSTRAINT user_companies_pkey PRIMARY KEY (user_id, company_id);


--
-- Name: user_edge_gateways user_edge_gateways_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_edge_gateways
    ADD CONSTRAINT user_edge_gateways_pkey PRIMARY KEY (id);


--
-- Name: user_edge_gateways user_edge_gateways_user_id_edge_gateway_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_edge_gateways
    ADD CONSTRAINT user_edge_gateways_user_id_edge_gateway_id_key UNIQUE (user_id, edge_gateway_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_smart_meters user_smart_meters_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_smart_meters
    ADD CONSTRAINT user_smart_meters_pkey PRIMARY KEY (id);


--
-- Name: user_smart_meters user_smart_meters_user_id_smart_meter_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_smart_meters
    ADD CONSTRAINT user_smart_meters_user_id_smart_meter_id_key UNIQUE (user_id, smart_meter_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_ai_recommendations_company_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_ai_recommendations_company_id ON public.ai_recommendations USING btree (company_id);


--
-- Name: idx_alert_rules_company_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_alert_rules_company_id ON public.alert_rules USING btree (company_id);


--
-- Name: idx_alert_subscriptions_user_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_alert_subscriptions_user_id ON public.alert_subscriptions USING btree (user_id);


--
-- Name: idx_alerts_company_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_alerts_company_id ON public.alerts USING btree (company_id);


--
-- Name: idx_alerts_edge_gateway_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_alerts_edge_gateway_id ON public.alerts USING btree (edge_gateway_id);


--
-- Name: idx_alerts_severity; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_alerts_severity ON public.alerts USING btree (severity);


--
-- Name: idx_alerts_smart_meter_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_alerts_smart_meter_id ON public.alerts USING btree (smart_meter_id);


--
-- Name: idx_alerts_status; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_alerts_status ON public.alerts USING btree (status);


--
-- Name: idx_alerts_triggered_at; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_alerts_triggered_at ON public.alerts USING btree (triggered_at);


--
-- Name: idx_contact_points_user_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_contact_points_user_id ON public.contact_points USING btree (user_id);


--
-- Name: idx_ip_edge_gateways_gateway_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_ip_edge_gateways_gateway_id ON public.ip_edge_gateways USING btree (edge_gateway_id);


--
-- Name: idx_reports_company_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_reports_company_id ON public.reports USING btree (company_id);


--
-- Name: idx_reports_created_at; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_reports_created_at ON public.reports USING btree (created_at);


--
-- Name: idx_reports_user_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_reports_user_id ON public.reports USING btree (user_id);


--
-- Name: idx_smart_meters_edge_gateways_gateway_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_smart_meters_edge_gateways_gateway_id ON public.smart_meters_edge_gateways USING btree (edge_gateway_id);


--
-- Name: idx_smart_meters_edge_gateways_meter_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_smart_meters_edge_gateways_meter_id ON public.smart_meters_edge_gateways USING btree (smart_meter_id);


--
-- Name: idx_user_edge_gateways_gateway_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_user_edge_gateways_gateway_id ON public.user_edge_gateways USING btree (edge_gateway_id);


--
-- Name: idx_user_edge_gateways_user_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_user_edge_gateways_user_id ON public.user_edge_gateways USING btree (user_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: idx_user_smart_meters_meter_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_user_smart_meters_meter_id ON public.user_smart_meters USING btree (smart_meter_id);


--
-- Name: idx_user_smart_meters_user_id; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_user_smart_meters_user_id ON public.user_smart_meters USING btree (user_id);


--
-- Name: alert_subscriptions alert_subscriptions_alert_rule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.alert_subscriptions
    ADD CONSTRAINT alert_subscriptions_alert_rule_id_fkey FOREIGN KEY (alert_rule_id) REFERENCES public.alert_rules(id) ON DELETE CASCADE;


--
-- Name: alert_subscriptions alert_subscriptions_contact_point_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.alert_subscriptions
    ADD CONSTRAINT alert_subscriptions_contact_point_id_fkey FOREIGN KEY (contact_point_id) REFERENCES public.contact_points(id) ON DELETE CASCADE;


--
-- Name: alerts alerts_alert_rule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_alert_rule_id_fkey FOREIGN KEY (alert_rule_id) REFERENCES public.alert_rules(id) ON DELETE SET NULL;


--
-- Name: assignments assignments_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: assignments assignments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: assignments assignments_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE CASCADE;


--
-- Name: assignments assignments_edge_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_edge_gateway_id_fkey FOREIGN KEY (edge_gateway_id) REFERENCES public.edge_gateways(id) ON DELETE CASCADE;


--
-- Name: assignments assignments_facility_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id) ON DELETE CASCADE;


--
-- Name: assignments assignments_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: companies companies_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: companies companies_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: company_tariffs company_tariffs_tariff_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.company_tariffs
    ADD CONSTRAINT company_tariffs_tariff_plan_id_fkey FOREIGN KEY (tariff_plan_id) REFERENCES public.tariff_plans(id) ON DELETE CASCADE;


--
-- Name: departments departments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: departments departments_facility_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id) ON DELETE CASCADE;


--
-- Name: departments departments_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: device_models device_models_manufacturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.device_models
    ADD CONSTRAINT device_models_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES public.manufacturers(id);


--
-- Name: edge_gateway_connection_details edge_gateway_connection_details_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateway_connection_details
    ADD CONSTRAINT edge_gateway_connection_details_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.edge_gateways(id) ON DELETE CASCADE;


--
-- Name: edge_gateway_ip_addresses edge_gateway_ip_addresses_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateway_ip_addresses
    ADD CONSTRAINT edge_gateway_ip_addresses_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.edge_gateways(id) ON DELETE CASCADE;


--
-- Name: edge_gateway_specifications edge_gateway_specifications_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateway_specifications
    ADD CONSTRAINT edge_gateway_specifications_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.edge_gateways(id) ON DELETE CASCADE;


--
-- Name: edge_gateways edge_gateways_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateways
    ADD CONSTRAINT edge_gateways_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: edge_gateways edge_gateways_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateways
    ADD CONSTRAINT edge_gateways_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.device_models(id);


--
-- Name: edge_gateways edge_gateways_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.edge_gateways
    ADD CONSTRAINT edge_gateways_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: facilities facilities_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT facilities_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: facilities facilities_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT facilities_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: facilities facilities_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT facilities_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: user_roles fk_user_roles_role; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: invoice_items invoice_items_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id) ON DELETE CASCADE;


--
-- Name: invoices invoices_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: invoices invoices_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id) ON DELETE CASCADE;


--
-- Name: payments payments_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id) ON DELETE CASCADE;


--
-- Name: reports reports_report_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_report_template_id_fkey FOREIGN KEY (report_template_id) REFERENCES public.report_templates(id) ON DELETE SET NULL;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: smart_meter_assignments smart_meter_assignments_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meter_assignments
    ADD CONSTRAINT smart_meter_assignments_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id) ON DELETE CASCADE;


--
-- Name: smart_meter_assignments smart_meter_assignments_smart_meter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meter_assignments
    ADD CONSTRAINT smart_meter_assignments_smart_meter_id_fkey FOREIGN KEY (smart_meter_id) REFERENCES public.smart_meters(id) ON DELETE CASCADE;


--
-- Name: smart_meters smart_meters_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meters
    ADD CONSTRAINT smart_meters_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: smart_meters smart_meters_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meters
    ADD CONSTRAINT smart_meters_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.device_models(id);


--
-- Name: smart_meters smart_meters_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.smart_meters
    ADD CONSTRAINT smart_meters_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: subscriptions subscriptions_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.subscription_plans(id);


--
-- Name: tariff_rates tariff_rates_tariff_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.tariff_rates
    ADD CONSTRAINT tariff_rates_tariff_plan_id_fkey FOREIGN KEY (tariff_plan_id) REFERENCES public.tariff_plans(id) ON DELETE CASCADE;


--
-- Name: team_credentials team_credentials_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team_credentials
    ADD CONSTRAINT team_credentials_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: team_permissions team_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team_permissions
    ADD CONSTRAINT team_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.team_roles(id) ON DELETE CASCADE;


--
-- Name: team team_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.team_roles(id) ON DELETE CASCADE;


--
-- Name: user_companies user_companies_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_companies
    ADD CONSTRAINT user_companies_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: user_companies user_companies_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_companies
    ADD CONSTRAINT user_companies_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE CASCADE;


--
-- Name: user_companies user_companies_facility_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_companies
    ADD CONSTRAINT user_companies_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id) ON DELETE CASCADE;


--
-- Name: user_companies user_companies_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_companies
    ADD CONSTRAINT user_companies_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- PostgreSQL database dump complete
--

