
USE kaui;

-- Tabela de usuários
CREATE TABLE IF NOT EXISTS kaui_users (
  id int(11) NOT NULL AUTO_INCREMENT,
  kb_username varchar(255) DEFAULT NULL,
  kb_session_id varchar(255) DEFAULT NULL,
  password varchar(255) DEFAULT NULL,
  session_id varchar(255) DEFAULT NULL,
  email varchar(255) DEFAULT NULL,
  encrypted_password varchar(255) DEFAULT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY index_kaui_users_on_kb_username (kb_username),
  KEY index_kaui_users_on_kb_session_id (kb_session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Criar tabela de tenants do Kaui
CREATE TABLE IF NOT EXISTS kaui_tenants (
  id int(11) NOT NULL AUTO_INCREMENT,
  name varchar(255) NOT NULL,
  kb_tenant_id varchar(255) NOT NULL,
  api_key varchar(255) NOT NULL,
  api_secret varchar(255) NOT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY index_kaui_tenants_on_kb_tenant_id (kb_tenant_id),
  KEY index_kaui_tenants_on_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Criar tabela de usuários permitidos
CREATE TABLE IF NOT EXISTS kaui_allowed_users (
  id int(11) NOT NULL AUTO_INCREMENT,
  kb_username varchar(255) NOT NULL,
  kaui_tenant_id int(11) DEFAULT NULL COMMENT 'NULL permitido para criação inicial de tenant',
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id),
  KEY index_kaui_allowed_users_on_kb_username (kb_username),
  KEY index_kaui_allowed_users_on_kaui_tenant_id (kaui_tenant_id),
  KEY index_kaui_allowed_users_on_kb_username_and_kaui_tenant_id (kb_username, kaui_tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Criar tabela de schema migrations
CREATE TABLE IF NOT EXISTS schema_migrations (
  version varchar(255) NOT NULL,
  PRIMARY KEY (version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Criar tabela de sessões
CREATE TABLE IF NOT EXISTS sessions (
  id int(11) NOT NULL AUTO_INCREMENT,
  session_id varchar(255) NOT NULL,
  data text,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY index_sessions_on_session_id (session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Inserir usuário admin (senha: password)
-- A senha é o hash bcrypt de "password"
INSERT IGNORE INTO kaui_users (kb_username, password, created_at, updated_at)
VALUES ('admin', '$2a$10$kGXP.7gqmVUKPYREKCmRN.pXMBB3B8bZZGF3G7d5WB8F4j5mxZyKu', NOW(), NOW());

-- Inserir versões do schema
INSERT IGNORE INTO schema_migrations (version) VALUES
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
('20190329151559');

-- Mensagem de confirmação
SELECT 'Tabelas do Kaui criadas com sucesso!' as status;
SELECT COUNT(*) as total_users FROM users;

