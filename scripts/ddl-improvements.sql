-- ============================================================================
-- Ajustes propostos no modelo relacional (ver README.md § Ajustes no Modelo
-- Relacional). Este script é ADITIVO e NÃO é aplicado automaticamente pelo
-- pipeline — rode a seção de validação primeiro em cada ambiente antes de
-- aplicar as constraints, pois uma linha órfã faz o ALTER TABLE falhar.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. VALIDAÇÃO — rode antes de aplicar as constraints. Cada consulta deve
--    retornar ZERO linhas. Se retornar alguma linha, trate/limpe o dado antes
--    de prosseguir (a FK correspondente vai falhar caso contrário).
-- ----------------------------------------------------------------------------

SELECT 'stocks.product_id orfao' AS problema, s.*
FROM stocks s
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.id = s.product_id);

SELECT 'stock_movements.stock_id orfao' AS problema, m.*
FROM stock_movements m
WHERE NOT EXISTS (SELECT 1 FROM stocks s WHERE s.id = m.stock_id);

SELECT 'stock_reservations.stock_id orfao' AS problema, r.*
FROM stock_reservations r
WHERE NOT EXISTS (SELECT 1 FROM stocks s WHERE s.id = r.stock_id);

SELECT 'stock_reservations.product_id orfao' AS problema, r.*
FROM stock_reservations r
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.id = r.product_id);

SELECT 'stock_reservations.service_order_id orfao' AS problema, r.*
FROM stock_reservations r
WHERE NOT EXISTS (SELECT 1 FROM service_order so WHERE so.id = r.service_order_id);

SELECT 'budgets.service_order_id orfao' AS problema, b.*
FROM budgets b
WHERE NOT EXISTS (SELECT 1 FROM service_order so WHERE so.id = b.service_order_id);

SELECT 'budget_items.product_id orfao' AS problema, bi.*
FROM budget_items bi
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.id = bi.product_id);

SELECT 'service.id_os orfao' AS problema, sv.*
FROM service sv
WHERE NOT EXISTS (SELECT 1 FROM service_order so WHERE so.id = sv.id_os);

SELECT 'service_order.cpf_cnpj sem cliente' AS problema, so.*
FROM service_order so
WHERE NOT EXISTS (SELECT 1 FROM clients c WHERE c.document = so.cpf_cnpj);

SELECT 'service_order.placa sem veiculo' AS problema, so.*
FROM service_order so
WHERE NOT EXISTS (SELECT 1 FROM vehicles v WHERE v.plate = so.placa);

-- ----------------------------------------------------------------------------
-- 1. CHAVES ESTRANGEIRAS AUSENTES
--    Garante integridade referencial que hoje é aplicada apenas pela camada
--    de aplicação (Java/JPA), fechando a brecha de um script manual ou uma
--    futura integração gravar diretamente no banco sem passar pelo domínio.
-- ----------------------------------------------------------------------------

ALTER TABLE stocks
  ADD CONSTRAINT fk_stocks_product
  FOREIGN KEY (product_id) REFERENCES products (id);

ALTER TABLE stock_movements
  ADD CONSTRAINT fk_stock_movements_stock
  FOREIGN KEY (stock_id) REFERENCES stocks (id);

ALTER TABLE stock_reservations
  ADD CONSTRAINT fk_stock_reservations_stock
  FOREIGN KEY (stock_id) REFERENCES stocks (id);

ALTER TABLE stock_reservations
  ADD CONSTRAINT fk_stock_reservations_product
  FOREIGN KEY (product_id) REFERENCES products (id);

ALTER TABLE stock_reservations
  ADD CONSTRAINT fk_stock_reservations_service_order
  FOREIGN KEY (service_order_id) REFERENCES service_order (id);

ALTER TABLE budgets
  ADD CONSTRAINT fk_budgets_service_order
  FOREIGN KEY (service_order_id) REFERENCES service_order (id);

ALTER TABLE budget_items
  ADD CONSTRAINT fk_budget_items_product
  FOREIGN KEY (product_id) REFERENCES products (id);

ALTER TABLE service
  ADD CONSTRAINT fk_service_service_order
  FOREIGN KEY (id_os) REFERENCES service_order (id);

-- clients.document e vehicles.plate já são UNIQUE (pré-requisito para FK).
ALTER TABLE service_order
  ADD CONSTRAINT fk_service_order_client
  FOREIGN KEY (cpf_cnpj) REFERENCES clients (document);

ALTER TABLE service_order
  ADD CONSTRAINT fk_service_order_vehicle
  FOREIGN KEY (placa) REFERENCES vehicles (plate);

-- ----------------------------------------------------------------------------
-- 2. ÍNDICES EM COLUNAS DE BUSCA FREQUENTE
--    cpf_cnpj/placa são usados em WHERE por GET /order/document/{cpfCnpj} e
--    por regras de negócio que casam OS a cliente/veículo; sem índice, essas
--    consultas viram sequential scan à medida que o volume de OS cresce.
-- ----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_service_order_cpf_cnpj ON service_order (cpf_cnpj);
CREATE INDEX IF NOT EXISTS idx_service_order_placa ON service_order (placa);
CREATE INDEX IF NOT EXISTS idx_stock_reservations_service_order ON stock_reservations (service_order_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_stock ON stock_movements (stock_id);

-- ----------------------------------------------------------------------------
-- 3. CONSTRAINTS DE DOMÍNIO (CHECK)
--    Hoje os valores de status são VARCHAR livre; a validação existe apenas
--    na máquina de estados em Java. Um CHECK barra no banco um valor fora do
--    vocabulário conhecido, mesmo se gravado fora da aplicação.
-- ----------------------------------------------------------------------------

ALTER TABLE service_order
  ADD CONSTRAINT chk_service_order_status
  CHECK (service_status IN (
    'RECEBIDA', 'EM_DIAGNOSTICO', 'AGUARDANDO_APROVACAO', 'APROVADO',
    'EM_EXECUCAO', 'FINALIZADA', 'ENTREGUE', 'RECUSADA'
  ));

ALTER TABLE stock_reservations
  ADD CONSTRAINT chk_stock_reservations_status
  CHECK (status IN ('ACTIVE', 'CONFIRMED', 'RELEASED'));
