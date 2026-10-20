-- DDL: esquema completo do banco (PostgreSQL)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- users / roles / groups
CREATE TABLE IF NOT EXISTS roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'users'::regclass
      AND contype = 'u'
      AND conname = 'uk_users_email'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT uk_users_email UNIQUE (email);
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID NOT NULL,
  role_id UUID NOT NULL,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_groups (
  user_id UUID NOT NULL,
  group_id UUID NOT NULL,
  PRIMARY KEY (user_id, group_id),
  CONSTRAINT fk_user_groups_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_groups_group FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);

-- clients + sequence
CREATE SEQUENCE IF NOT EXISTS clients_seq START WITH 1 INCREMENT BY 50;

CREATE TABLE IF NOT EXISTS clients (
  id BIGINT PRIMARY KEY DEFAULT nextval('clients_seq'),
  name VARCHAR(255) NOT NULL,
  document VARCHAR(14) NOT NULL UNIQUE,
  email VARCHAR(255),
  phone VARCHAR(255),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- vehicles + sequence
CREATE SEQUENCE IF NOT EXISTS vehicles_seq START WITH 1 INCREMENT BY 50;

CREATE TABLE IF NOT EXISTS vehicles (
  id BIGINT PRIMARY KEY DEFAULT nextval('vehicles_seq'),
  client_id BIGINT NOT NULL,
  plate VARCHAR(20) NOT NULL UNIQUE,
  brand VARCHAR(255) NOT NULL,
  model VARCHAR(255) NOT NULL,
  year INTEGER NOT NULL,
  color VARCHAR(255),
  type VARCHAR(255) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_vehicles_clients FOREIGN KEY (client_id) REFERENCES clients (id)
);

-- service types
CREATE TABLE IF NOT EXISTS service_type (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT
);

-- service (stores events/status as jsonb)
CREATE TABLE IF NOT EXISTS service (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_type_name VARCHAR(255) NOT NULL,
  id_os UUID NOT NULL,
  service_status JSONB NOT NULL
);

-- service_order (list_service as jsonb)
CREATE TABLE IF NOT EXISTS service_order (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_type_name VARCHAR(255) NOT NULL,
  service_status VARCHAR(30) DEFAULT 'RECEBIDA',
  list_service JSONB NOT NULL,
  cpf_cnpj VARCHAR(50) NOT NULL,
  placa VARCHAR(20) NOT NULL,
  rejection_reason VARCHAR(500),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

ALTER TABLE service_order
  ALTER COLUMN service_status SET DEFAULT 'RECEBIDA';

ALTER TABLE service_order
  ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE service_order
  ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP;

-- products / parts / supplies + sequence
CREATE SEQUENCE IF NOT EXISTS product_seq START WITH 1 INCREMENT BY 50;

CREATE TABLE IF NOT EXISTS products (
  id BIGINT PRIMARY KEY DEFAULT nextval('product_seq'),
  product_type VARCHAR(50) NOT NULL,
  name VARCHAR(255) NOT NULL,
  sku VARCHAR(255) NOT NULL UNIQUE,
  unit VARCHAR(50) NOT NULL,
  category VARCHAR(255),
  brand VARCHAR(255),
  cost_price NUMERIC(19,2) NOT NULL,
  sale_price NUMERIC(19,2) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP WITHOUT TIME ZONE,
  updated_at TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE IF NOT EXISTS parts (
  id BIGINT PRIMARY KEY REFERENCES products(id),
  manufacturer_code VARCHAR(255),
  warranty_months INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS supplies (
  id BIGINT PRIMARY KEY REFERENCES products(id),
  fractional_allowed BOOLEAN,
  package_size NUMERIC(19,2)
);

-- stocks + sequence
CREATE SEQUENCE IF NOT EXISTS stock_seq START WITH 1 INCREMENT BY 50;

CREATE TABLE IF NOT EXISTS stocks (
  id BIGINT PRIMARY KEY DEFAULT nextval('stock_seq'),
  product_id BIGINT NOT NULL UNIQUE,
  quantity NUMERIC(19,2) NOT NULL DEFAULT 0,
  reserved_quantity NUMERIC(19,2) NOT NULL DEFAULT 0,
  minimum_quantity NUMERIC(19,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITHOUT TIME ZONE,
  updated_at TIMESTAMP WITHOUT TIME ZONE
);

-- stock movements + sequence
CREATE SEQUENCE IF NOT EXISTS stock_movement_seq START WITH 1 INCREMENT BY 50;

CREATE TABLE IF NOT EXISTS stock_movements (
  id BIGINT PRIMARY KEY DEFAULT nextval('stock_movement_seq'),
  stock_id BIGINT NOT NULL,
  type VARCHAR(50) NOT NULL,
  quantity NUMERIC(19,2) NOT NULL,
  reason VARCHAR(255),
  created_at TIMESTAMP WITHOUT TIME ZONE
);

-- stock reservations + sequence
CREATE SEQUENCE IF NOT EXISTS stock_reservation_seq START WITH 1 INCREMENT BY 50;

CREATE TABLE IF NOT EXISTS stock_reservations (
  id BIGINT PRIMARY KEY DEFAULT nextval('stock_reservation_seq'),
  stock_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL,
  service_order_id UUID NOT NULL,
  quantity NUMERIC(19,2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE,
  updated_at TIMESTAMP WITHOUT TIME ZONE
);

-- budgets / budget_items + sequences
CREATE SEQUENCE IF NOT EXISTS budget_seq START WITH 1 INCREMENT BY 50;
CREATE SEQUENCE IF NOT EXISTS budget_item_seq START WITH 1 INCREMENT BY 50;

CREATE TABLE IF NOT EXISTS budgets (
  id BIGINT PRIMARY KEY DEFAULT nextval('budget_seq'),
  service_order_id UUID NOT NULL UNIQUE,
  total_price NUMERIC(19,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITHOUT TIME ZONE,
  updated_at TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE IF NOT EXISTS budget_items (
  id BIGINT PRIMARY KEY DEFAULT nextval('budget_item_seq'),
  budget_id BIGINT NOT NULL REFERENCES budgets(id),
  product_id BIGINT NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  product_sku VARCHAR(255) NOT NULL,
  product_type VARCHAR(50) NOT NULL,
  quantity NUMERIC(19,2) NOT NULL,
  unit_price NUMERIC(19,2) NOT NULL,
  total_price NUMERIC(19,2) NOT NULL
);