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



--

