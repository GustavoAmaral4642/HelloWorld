-- Script para criar o banco kaui automaticamente na inicialização do MySQL
-- Este arquivo é executado por estar em /docker-entrypoint-initdb.d/

-- Criar banco kaui se não existir
CREATE DATABASE IF NOT EXISTS kaui CHARACTER SET utf8 COLLATE utf8_bin;

-- Dar permissões ao usuário killbill no banco kaui
GRANT ALL PRIVILEGES ON kaui.* TO 'killbill'@'%';
FLUSH PRIVILEGES;

-- Mensagem de confirmação
SELECT 'Banco kaui criado com sucesso!' AS status;

