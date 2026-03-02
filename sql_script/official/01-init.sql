-- =====================================================================================
-- Kaui database

-- Criar banco de dados para Kaui
CREATE DATABASE IF NOT EXISTS kaui CHARACTER SET utf8 COLLATE utf8_bin;

USE mysql;

-- Dar permissões ao usuário killbill
GRANT ALL PRIVILEGES ON kaui.* TO 'killbill'@'%';
FLUSH PRIVILEGES;

-- =====================================================================================
-- CRIAR TABELAS DO KAUI
-- =====================================================================================

USE kaui;

-- Tabela de usuários (para login no Kaui)
DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id int(11) NOT NULL AUTO_INCREMENT,
  kb_username varchar(255) DEFAULT NULL,
  password varchar(255) DEFAULT NULL,
  session_id varchar(255) DEFAULT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY index_users_on_kb_username (kb_username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Tabela de tenants do Kaui
DROP TABLE IF EXISTS kaui_tenants;
CREATE TABLE kaui_tenants (
  id int(11) NOT NULL AUTO_INCREMENT,
  name varchar(255) NOT NULL,
  kb_tenant_id char(36) NOT NULL,
  api_key varchar(255) NOT NULL,
  api_secret varchar(255) DEFAULT NULL,
  encrypted_api_secret TEXT DEFAULT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY index_kaui_tenants_on_kb_tenant_id (kb_tenant_id),
  KEY index_kaui_tenants_on_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Tabela de usuários permitidos por tenant
DROP TABLE IF EXISTS kaui_allowed_users;
CREATE TABLE kaui_allowed_users (
  id int(11) NOT NULL AUTO_INCREMENT,
  kb_username varchar(255) NOT NULL,
  kaui_tenant_id int(11) NOT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id),
  KEY index_kaui_allowed_users_on_kb_username (kb_username),
  KEY index_kaui_allowed_users_on_kaui_tenant_id (kaui_tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Tabela de controle de migrations do Rails
DROP TABLE IF EXISTS schema_migrations;
CREATE TABLE schema_migrations (
  version varchar(255) NOT NULL,
  PRIMARY KEY (version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Tabela de sessões do Kaui
DROP TABLE IF EXISTS sessions;
CREATE TABLE sessions (
  id int(11) NOT NULL AUTO_INCREMENT,
  session_id varchar(255) NOT NULL,
  data text,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY index_sessions_on_session_id (session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Inserir usuário admin padrão
-- Senha: 'password' (hash BCrypt)
INSERT INTO users (kb_username, password, created_at, updated_at)
VALUES ('admin', '$2a$10$kGXP.7gqmVUKPYREKCmRN.pXMBB3B8bZZGF3G7d5WB8F4j5mxZyKu', NOW(), NOW())
ON DUPLICATE KEY UPDATE updated_at = NOW();

-- Inserir versão do schema (para o Rails não tentar rodar migrations)
INSERT INTO schema_migrations (version) VALUES
('20140221184226'),
('20140318151556'),
('20140512162622'),
('20140625201445'),
('20140717143906'),
('20140807182333'),
('20141126211032'),
('20150223205230'),
('20151103212939'),
('20160113225612'),
('20160519201328'),
('20160726230702'),
('20180619140056'),
('20190329151559')
ON DUPLICATE KEY UPDATE version = version;

-- =====================================================================================
-- FIM DAS TABELAS DO KAUI
-- =====================================================================================


-- =====================================================================================
-- Kill Bill Database 
-- =====================================================================================

USE killbill;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS tenants;
CREATE TABLE tenants (
    record_id serial unique,
    id varchar(36) NOT NULL,
    external_key varchar(255) NULL,
    api_key varchar(128) NULL,
    api_secret varchar(128) NULL,
    api_salt varchar(128) NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    account_record_id bigint unsigned DEFAULT NULL,
    tenant_record_id bigint unsigned DEFAULT NULL,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX tenants_id ON tenants(id);
CREATE UNIQUE INDEX tenants_api_key ON tenants(api_key);

DROP TABLE IF EXISTS tenant_kvs;
CREATE TABLE tenant_kvs (
    record_id serial unique,
    id varchar(36) NOT NULL,
    tenant_record_id bigint not null,
    tenant_key varchar(255) NOT NULL,
    tenant_value mediumtext NOT NULL,
    is_active boolean default 1,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX tenant_kvs_id ON tenant_kvs(id);
CREATE INDEX tenant_kvs_tenant_record_id ON tenant_kvs(tenant_record_id);
CREATE INDEX tenant_kvs_key ON tenant_kvs(tenant_key);

DROP TABLE IF EXISTS tenant_broadcasts;
CREATE TABLE tenant_broadcasts (
    record_id serial unique,
    id varchar(36) NOT NULL,
    target_record_id bigint not null,
    target_table_name varchar(50) NOT NULL,
    tenant_record_id bigint  not null,
    type varchar(64) NOT NULL,
    user_token varchar(36),
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX tenant_broadcasts_tenant_record_id ON tenant_broadcasts(tenant_record_id);

DROP TABLE IF EXISTS bus_events;
CREATE TABLE bus_events (
    record_id serial unique,
    id varchar(36) NOT NULL,
    class_name varchar(128) NOT NULL,
    event_json text NOT NULL,
    user_token varchar(36),
    created_date datetime NOT NULL,
    creating_owner varchar(50) NOT NULL,
    processing_owner varchar(50) DEFAULT NULL,
    processing_available_date datetime DEFAULT NULL,
    processing_state varchar(14) DEFAULT 'AVAILABLE',
    error_count int  DEFAULT 0,
    search_key1 bigint  not null,
    search_key2 bigint  not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX bus_events_id ON bus_events(id);
CREATE INDEX idx_bus_where ON bus_events(processing_state, processing_owner, creating_owner, processing_available_date);
CREATE INDEX idx_bus_ext_bus_id ON bus_events(search_key2, search_key1);

DROP TABLE IF EXISTS bus_events_history;
CREATE TABLE bus_events_history (
    record_id serial unique,
    id varchar(36) NOT NULL,
    class_name varchar(128) NOT NULL,
    event_json text NOT NULL,
    user_token varchar(36),
    created_date datetime NOT NULL,
    creating_owner varchar(50) NOT NULL,
    processing_owner varchar(50) DEFAULT NULL,
    processing_available_date datetime DEFAULT NULL,
    processing_state varchar(14) DEFAULT 'AVAILABLE',
    error_count int  DEFAULT 0,
    search_key1 bigint  not null,
    search_key2 bigint  not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX bus_events_history_id ON bus_events_history(id);

DROP TABLE IF EXISTS notifications;
CREATE TABLE notifications (
    record_id serial unique,
    id varchar(36) NOT NULL,
    class_name varchar(256) NOT NULL,
    event_json text NOT NULL,
    user_token varchar(36),
    created_date datetime NOT NULL,
    creating_owner varchar(50) NOT NULL,
    processing_owner varchar(50) DEFAULT NULL,
    processing_available_date datetime DEFAULT NULL,
    processing_state varchar(14) DEFAULT 'AVAILABLE',
    error_count int  DEFAULT 0,
    search_key1 bigint  not null,
    search_key2 bigint  not null default 0,
    queue_name varchar(64) NOT NULL,
    effective_date datetime NOT NULL,
    future_user_token varchar(36),
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX notifications_id ON notifications(id);
CREATE INDEX idx_comp_where ON notifications(effective_date, processing_state, processing_owner, creating_owner);
CREATE INDEX idx_update ON notifications(processing_state, processing_owner, processing_available_date);
CREATE INDEX idx_get_ready ON notifications(effective_date, created_date, record_id);
CREATE INDEX notifications_tenant_account_record_id ON notifications(search_key2, search_key1);

DROP TABLE IF EXISTS notifications_history;
CREATE TABLE notifications_history (
    record_id serial unique,
    id varchar(36) NOT NULL,
    class_name varchar(256) NOT NULL,
    event_json text NOT NULL,
    user_token varchar(36),
    created_date datetime NOT NULL,
    creating_owner varchar(50) NOT NULL,
    processing_owner varchar(50) DEFAULT NULL,
    processing_available_date datetime DEFAULT NULL,
    processing_state varchar(14) DEFAULT 'AVAILABLE',
    error_count int  DEFAULT 0,
    search_key1 bigint  not null,
    search_key2 bigint  not null default 0,
    queue_name varchar(64) NOT NULL,
    effective_date datetime NOT NULL,
    future_user_token varchar(36),
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX notifications_history_id ON notifications_history(id);

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
    record_id serial unique,
    id varchar(36) NOT NULL,
    external_key varchar(255) NOT NULL,
    email varchar(128) NOT NULL,
    name varchar(100) NOT NULL,
    first_name_length int,
    currency varchar(3) DEFAULT NULL,
    billing_cycle_day_local int DEFAULT 0,
    parent_account_id varchar(36),
    is_payment_delegated_to_parent boolean default FALSE,
    payment_method_id varchar(36) DEFAULT NULL,
    reference_time datetime NOT NULL,
    time_zone varchar(50) NOT NULL,
    locale varchar(5) DEFAULT NULL,
    address1 varchar(100) DEFAULT NULL,
    address2 varchar(100) DEFAULT NULL,
    company_name varchar(50) DEFAULT NULL,
    city varchar(50) DEFAULT NULL,
    state_or_province varchar(50) DEFAULT NULL,
    country varchar(50) DEFAULT NULL,
    postal_code varchar(16) DEFAULT NULL,
    phone varchar(25) DEFAULT NULL,
    notes varchar(4096) DEFAULT NULL,
    migrated boolean default false,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    tenant_record_id bigint  not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX accounts_id ON accounts(id);
CREATE UNIQUE INDEX accounts_external_key ON accounts(external_key, tenant_record_id);
CREATE INDEX accounts_tenant_record_id ON accounts(tenant_record_id);

DROP TABLE IF EXISTS account_history;
CREATE TABLE account_history (
    record_id serial unique,
    id varchar(36) NOT NULL,
    target_record_id bigint  not null,
    external_key varchar(255) NOT NULL,
    email varchar(128) NOT NULL,
    name varchar(100) NOT NULL,
    first_name_length int,
    currency varchar(3) DEFAULT NULL,
    billing_cycle_day_local int DEFAULT 0,
    parent_account_id varchar(36),
    is_payment_delegated_to_parent boolean default FALSE,
    payment_method_id varchar(36) DEFAULT NULL,
    reference_time datetime NOT NULL,
    time_zone varchar(50) NOT NULL,
    locale varchar(5) DEFAULT NULL,
    address1 varchar(100) DEFAULT NULL,
    address2 varchar(100) DEFAULT NULL,
    company_name varchar(50) DEFAULT NULL,
    city varchar(50) DEFAULT NULL,
    state_or_province varchar(50) DEFAULT NULL,
    country varchar(50) DEFAULT NULL,
    postal_code varchar(16) DEFAULT NULL,
    phone varchar(25) DEFAULT NULL,
    notes varchar(4096) DEFAULT NULL,
    migrated boolean default false,
    change_type varchar(6) NOT NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    tenant_record_id bigint  not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX account_history_target_record_id ON account_history(target_record_id);
CREATE INDEX account_history_tenant_record_id ON account_history(tenant_record_id);

DROP TABLE IF EXISTS sessions;
CREATE TABLE sessions (
    record_id serial unique,
    id varchar(128) NOT NULL,
    start_timestamp datetime NOT NULL,
    last_access_time datetime NOT NULL,
    timeout bigint NOT NULL,
    host varchar(100) DEFAULT NULL,
    session_data mediumblob,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX sessions_id ON sessions(id);

DROP TABLE IF EXISTS invoices;
CREATE TABLE invoices (
    record_id serial unique,
    id varchar(36) NOT NULL,
    account_id varchar(36) NOT NULL,
    invoice_date date NOT NULL,
    target_date date,
    currency varchar(3) NOT NULL,
    status varchar(15) NOT NULL DEFAULT 'COMMITTED',
    migrated boolean default false,
    parent_invoice boolean default false,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX invoices_id ON invoices(id);
CREATE INDEX invoices_account ON invoices(account_id);
CREATE INDEX invoices_tenant_account_record_id ON invoices(tenant_record_id, account_record_id);

DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
    record_id serial unique,
    id varchar(36) NOT NULL,
    table_name varchar(50) NOT NULL,
    target_record_id bigint  not null,
    change_type varchar(6) NOT NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    reason_code varchar(255) DEFAULT NULL,
    comments varchar(255) DEFAULT NULL,
    user_token varchar(36),
    account_record_id bigint  DEFAULT NULL,
    tenant_record_id bigint  not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX audit_log_id ON audit_log(id);
CREATE INDEX audit_log_fetch_target_record_id ON audit_log(table_name, target_record_id);
CREATE INDEX audit_log_tenant_record_id ON audit_log(tenant_record_id);
CREATE INDEX audit_log_user_name ON audit_log(created_by);
CREATE INDEX audit_log_via_history ON audit_log(target_record_id, table_name, tenant_record_id);

DROP TABLE IF EXISTS tag_definitions;
CREATE TABLE tag_definitions (
    record_id serial unique,
    id varchar(36) NOT NULL,
    name varchar(20) NOT NULL,
    applicable_object_types varchar(500),
    description varchar(200) NOT NULL,
    is_active boolean default true,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    tenant_record_id bigint  not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX tag_definitions_id ON tag_definitions(id);
CREATE INDEX tag_definitions_tenant_record_id ON tag_definitions(tenant_record_id);

DROP TABLE IF EXISTS tag_definition_history;
CREATE TABLE tag_definition_history (
    record_id serial unique,
    id varchar(36) NOT NULL,
    target_record_id bigint  not null,
    name varchar(20) NOT NULL,
    applicable_object_types varchar(500),
    description varchar(200) NOT NULL,
    is_active boolean default true,
    change_type varchar(6) NOT NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX tag_definition_history_target_record_id ON tag_definition_history(target_record_id);
CREATE INDEX tag_definition_history_tenant_record_id ON tag_definition_history(tenant_record_id);

DROP TABLE IF EXISTS tags;
CREATE TABLE tags (
    record_id serial unique,
    id varchar(36) NOT NULL,
    tag_definition_id varchar(36) NOT NULL,
    object_id varchar(36) NOT NULL,
    object_type varchar(30) NOT NULL,
    is_active boolean default true,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX tags_id ON tags(id);
CREATE INDEX tags_by_object ON tags(object_id);
CREATE INDEX tags_tenant_account_record_id ON tags(tenant_record_id, account_record_id);

DROP TABLE IF EXISTS tag_history;
CREATE TABLE tag_history (
    record_id serial unique,
    id varchar(36) NOT NULL,
    target_record_id bigint not null,
    tag_definition_id varchar(36) NOT NULL,
    object_id varchar(36) NOT NULL,
    object_type varchar(30) NOT NULL,
    is_active boolean default true,
    change_type varchar(6) NOT NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX tag_history_target_record_id ON tag_history(target_record_id);
CREATE INDEX tag_history_tenant_account_record_id ON tag_history(tenant_record_id, account_record_id);

DROP TABLE IF EXISTS custom_fields;
CREATE TABLE custom_fields (
    record_id serial unique,
    id varchar(36) NOT NULL,
    object_id varchar(36) NOT NULL,
    object_type varchar(30) NOT NULL,
    is_active boolean default true,
    field_name varchar(64) NOT NULL,
    field_value varchar(255),
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX custom_fields_id ON custom_fields(id);
CREATE INDEX custom_fields_object_id_object_type ON custom_fields(object_id, object_type);
CREATE INDEX custom_fields_tenant_account_record_id ON custom_fields(tenant_record_id, account_record_id);

DROP TABLE IF EXISTS custom_field_history;
CREATE TABLE custom_field_history (
    record_id serial unique,
    id varchar(36) NOT NULL,
    target_record_id bigint not null,
    object_id varchar(36) NOT NULL,
    object_type varchar(30) NOT NULL,
    is_active boolean default true,
    field_name varchar(64) NOT NULL,
    field_value varchar(255),
    change_type varchar(6) NOT NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX custom_field_history_target_record_id ON custom_field_history(target_record_id);
CREATE INDEX custom_field_history_object_id_object_type ON custom_field_history(object_id, object_type);
CREATE INDEX custom_field_history_tenant_account_record_id ON custom_field_history(tenant_record_id, account_record_id);

DROP TABLE IF EXISTS payment_methods;
CREATE TABLE payment_methods (
    record_id serial unique,
    id varchar(36) NOT NULL,
    external_key varchar(255) NOT NULL,
    account_id varchar(36) NOT NULL,
    plugin_name varchar(50) NOT NULL,
    is_active boolean default true,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX payment_methods_id ON payment_methods(id);
CREATE INDEX payment_methods_external_key ON payment_methods(external_key, tenant_record_id);
CREATE INDEX payment_methods_account_id_plugin_name ON payment_methods(account_id, plugin_name);
CREATE INDEX payment_methods_tenant_account_record_id ON payment_methods(tenant_record_id, account_record_id);

DROP TABLE IF EXISTS payment_method_history;
CREATE TABLE payment_method_history (
    record_id serial unique,
    id varchar(36) NOT NULL,
    target_record_id bigint not null,
    external_key varchar(255) NOT NULL,
    account_id varchar(36) NOT NULL,
    plugin_name varchar(50) NOT NULL,
    is_active boolean default true,
    change_type varchar(6) NOT NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    updated_date datetime DEFAULT NULL,
    updated_by varchar(50) DEFAULT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX payment_method_history_target_record_id ON payment_method_history(target_record_id);
CREATE INDEX payment_method_history_tenant_account_record_id ON payment_method_history(tenant_record_id, account_record_id);

DROP TABLE IF EXISTS invoice_items;
CREATE TABLE invoice_items (
    record_id serial unique,
    id varchar(36) NOT NULL,
    type varchar(24) NOT NULL,
    invoice_id varchar(36) NOT NULL,
    account_id varchar(36) NOT NULL,
    child_account_id varchar(36),
    bundle_id varchar(36),
    subscription_id varchar(36),
    description varchar(256),
    plan_name varchar(255),
    phase_name varchar(255),
    usage_name varchar(255),
    rate decimal(15,9) NULL,
    start_date date NOT NULL,
    end_date date,
    amount decimal(15,9) NULL,
    currency varchar(3) NOT NULL,
    linked_item_id varchar(36),
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX invoice_items_id ON invoice_items(id);
CREATE INDEX invoice_items_invoice_id ON invoice_items(invoice_id);
CREATE INDEX invoice_items_subscription_id ON invoice_items(subscription_id);
CREATE INDEX invoice_items_tenant_account_record_id ON invoice_items(tenant_record_id, account_record_id);

DROP TABLE IF EXISTS invoice_payments;
CREATE TABLE invoice_payments (
    record_id serial unique,
    id varchar(36) NOT NULL,
    type varchar(24) NOT NULL,
    invoice_id varchar(36) NOT NULL,
    payment_id varchar(36),
    payment_date datetime NOT NULL,
    amount decimal(15,9) NULL,
    currency varchar(3) NOT NULL,
    linked_invoice_payment_id varchar(36),
    payment_cookie_id varchar(255),
    processing_status varchar(50) NOT NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX invoice_payments_id ON invoice_payments(id);
CREATE INDEX invoice_payments_invoice_id ON invoice_payments(invoice_id);
CREATE INDEX invoice_payments_payment_id ON invoice_payments(payment_id);
CREATE INDEX invoice_payments_tenant_account_record_id ON invoice_payments(tenant_record_id, account_record_id);

DROP TABLE IF EXISTS node_infos;
CREATE TABLE node_infos (
    record_id serial unique,
    node_name varchar(50) NOT NULL,
    boot_date datetime NOT NULL,
    updated_date datetime NOT NULL,
    node_info varchar(4096) NOT NULL,
    is_active boolean default true,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX node_infos_node_name_boot_date ON node_infos(node_name, boot_date);

DROP TABLE IF EXISTS bus_ext_events;
CREATE TABLE bus_ext_events (
    record_id serial unique,
    id varchar(36) NOT NULL,
    class_name varchar(128) NOT NULL,
    event_json text NOT NULL,
    user_token varchar(36),
    created_date datetime NOT NULL,
    creating_owner varchar(50) NOT NULL,
    processing_owner varchar(50) DEFAULT NULL,
    processing_available_date datetime DEFAULT NULL,
    processing_state varchar(14) DEFAULT 'AVAILABLE',
    error_count int DEFAULT 0,
    search_key1 bigint not null,
    search_key2 bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX bus_ext_events_id ON bus_ext_events(id);
CREATE INDEX idx_bus_ext_where ON bus_ext_events(processing_state, processing_owner, creating_owner, processing_available_date);
CREATE INDEX idx_bus_ext_ext_bus_id ON bus_ext_events(search_key2, search_key1);

DROP TABLE IF EXISTS bus_ext_events_history;
CREATE TABLE bus_ext_events_history (
    record_id serial unique,
    id varchar(36) NOT NULL,
    class_name varchar(128) NOT NULL,
    event_json text NOT NULL,
    user_token varchar(36),
    created_date datetime NOT NULL,
    creating_owner varchar(50) NOT NULL,
    processing_owner varchar(50) DEFAULT NULL,
    processing_available_date datetime DEFAULT NULL,
    processing_state varchar(14) DEFAULT 'AVAILABLE',
    error_count int DEFAULT 0,
    search_key1 bigint not null,
    search_key2 bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX bus_ext_events_history_id ON bus_ext_events_history(id);

DROP TABLE IF EXISTS service_broadcasts;
CREATE TABLE service_broadcasts (
    record_id serial unique,
    service_name varchar(64) NOT NULL,
    type varchar(64) NOT NULL,
    event varchar(4096) NOT NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE INDEX service_broadcasts_service_name_type_created_date ON service_broadcasts(service_name, type, created_date);

DROP TABLE IF EXISTS rolled_up_usage;
CREATE TABLE rolled_up_usage (
    record_id serial unique,
    id varchar(36) NOT NULL,
    subscription_id varchar(36) NOT NULL,
    unit_type varchar(255) NOT NULL,
    record_date date NOT NULL,
    amount decimal(15,9) NULL,
    tracking_id varchar(128) NOT NULL,
    created_date datetime NOT NULL,
    created_by varchar(50) NOT NULL,
    account_record_id bigint not null,
    tenant_record_id bigint not null default 0,
    PRIMARY KEY(record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE UNIQUE INDEX rolled_up_usage_id ON rolled_up_usage(id);
CREATE INDEX rolled_up_usage_subscription_id ON rolled_up_usage(subscription_id);
CREATE INDEX rolled_up_usage_tenant_account_record_id ON rolled_up_usage(tenant_record_id, account_record_id);
CREATE INDEX rolled_up_usage_tracking_id ON rolled_up_usage(tracking_id);

SET FOREIGN_KEY_CHECKS = 1;


