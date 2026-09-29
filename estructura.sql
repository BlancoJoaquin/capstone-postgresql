-- =====================================================================
-- estructura.sql
-- Proyecto Capstone: EDA en PostgreSQL (tienda online)
-- Crea el esquema (clientes, productos, pedidos) y carga los datos.
--
-- Uso:
--   1) createdb capstone_project        (o crearla desde pgAdmin)
--   2) psql -d capstone_project -f estructura.sql
-- =====================================================================

-- La base se crea por fuera del script (CREATE DATABASE no puede correr
-- dentro de una transacción ni en una conexión a la misma base):
--   CREATE DATABASE capstone_project;

DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes (
    id_cliente  SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    ciudad      VARCHAR(60),
    email       VARCHAR(120) UNIQUE
);

CREATE TABLE productos (
    id_producto  SERIAL PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    categoria    VARCHAR(50)  NOT NULL,
    -- precio de catálogo: sirve como respaldo cuando el pedido no registró precio
    precio_lista NUMERIC(12,2) NOT NULL CHECK (precio_lista > 0)
);

CREATE TABLE pedidos (
    id_pedido       SERIAL PRIMARY KEY,
    id_cliente      INTEGER NOT NULL REFERENCES clientes(id_cliente),
    id_producto     INTEGER NOT NULL REFERENCES productos(id_producto),
    -- fecha, precio y descuento admiten NULL a propósito: simulan datos "sucios"
    -- que se tratan en la etapa de limpieza (ver analisis.sql, sección 1)
    fecha_pedido    DATE,
    cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2),
    descuento_pct   NUMERIC(5,2)
);

-- ------------------------------ CLIENTES ------------------------------
INSERT INTO clientes (nombre, ciudad, email) VALUES
    ('Lucía Fernández', 'Neuquén', 'cliente1@mail.com'),
    ('Martín Gómez', 'Buenos Aires', 'cliente2@mail.com'),
    ('Camila Rossi', 'Córdoba', 'cliente3@mail.com'),
    ('Joaquín Pérez', 'Rosario', 'cliente4@mail.com'),
    ('Valentina Díaz', 'Mendoza', 'cliente5@mail.com'),
    ('Santiago Ruiz', 'Neuquén', 'cliente6@mail.com'),
    ('Sofía Morales', 'Buenos Aires', 'cliente7@mail.com'),
    ('Mateo Herrera', 'Córdoba', 'cliente8@mail.com'),
    ('Julieta Castro', 'Salta', 'cliente9@mail.com'),
    ('Nicolás Vega', 'Rosario', 'cliente10@mail.com'),
    ('Agustina Silva', 'Neuquén', 'cliente11@mail.com'),
    ('Tomás Acosta', 'Mendoza', 'cliente12@mail.com'),
    ('Milagros Ponce', 'Buenos Aires', 'cliente13@mail.com'),
    ('Facundo Ibarra', 'Tucumán', 'cliente14@mail.com'),
    ('Renata Luna', 'Neuquén', 'cliente15@mail.com');

-- ------------------------------ PRODUCTOS -----------------------------
INSERT INTO productos (nombre, categoria, precio_lista) VALUES
    ('Notebook 14''', 'Electrónica', 850000),
    ('Auriculares Bluetooth', 'Electrónica', 45000),
    ('Mouse inalámbrico', 'Electrónica', 18000),
    ('Teclado mecánico', 'Electrónica', 62000),
    ('Zapatillas running', 'Indumentaria', 78000),
    ('Campera impermeable', 'Indumentaria', 95000),
    ('Remera algodón', 'Indumentaria', 15000),
    ('Cafetera express', 'Hogar', 120000),
    ('Set de sábanas', 'Hogar', 38000),
    ('Lámpara LED escritorio', 'Hogar', 22000),
    ('Mochila urbana', 'Accesorios', 41000),
    ('Botella térmica', 'Accesorios', 16000);

-- ------------------------------ PEDIDOS -------------------------------
-- Incluye NULLs en fecha_pedido, precio_unitario y descuento_pct.
INSERT INTO pedidos (id_cliente, id_producto, fecha_pedido, cantidad, precio_unitario, descuento_pct) VALUES
    (8, 1, '2025-05-21', 1, 850000, 0),
    (14, 2, '2025-08-05', 1, NULL, 0),
    (7, 7, '2025-12-26', 3, 15000, 5),
    (1, 8, '2025-12-24', 1, 120000, 5),
    (5, 2, '2025-02-19', 2, 45000, 0),
    (6, 11, '2025-07-13', 1, 41000, 10),
    (5, 3, '2025-02-05', 1, 18000, 0),
    (13, 4, '2025-08-21', 3, 62000, 0),
    (11, 7, '2025-02-06', 3, 15000, 0),
    (3, 10, '2025-12-19', 3, 22000, 0),
    (3, 1, '2025-06-11', 1, 850000, 5),
    (13, 3, '2025-12-02', 2, 18000, 5),
    (2, 7, '2025-10-03', 2, 15000, 10),
    (15, 2, '2025-09-10', 1, 45000, 0),
    (10, 6, '2025-07-17', 2, 95000, 10),
    (13, 1, '2025-02-28', 1, 850000, 10),
    (4, 2, '2025-01-02', 3, 45000, 0),
    (1, 7, '2025-11-24', 3, 15000, 10),
    (15, 10, '2025-01-01', 3, 22000, 0),
    (15, 8, '2025-05-03', 1, 120000, 0),
    (11, 9, '2025-09-30', 1, 38000, 0),
    (6, 6, '2025-04-19', 3, 95000, 0),
    (5, 10, '2025-08-20', 1, 22000, 0),
    (3, 3, '2025-02-06', 3, 18000, 0),
    (1, 3, '2025-12-09', 2, 18000, 0),
    (7, 3, '2025-08-31', 2, NULL, 0),
    (6, 9, '2025-01-28', 3, NULL, 0),
    (1, 3, '2025-10-02', 2, 18000, 0),
    (15, 5, NULL, 1, 78000, 0),
    (1, 7, '2025-05-02', 1, 15000, 5),
    (1, 4, '2025-07-19', 2, 62000, 5),
    (12, 7, '2025-09-07', 1, 15000, 0),
    (7, 7, '2025-01-30', 1, 15000, 10),
    (1, 5, '2025-04-06', 1, NULL, 10),
    (15, 6, '2025-10-24', 3, 95000, 0),
    (6, 10, '2025-04-15', 3, 22000, 0),
    (4, 3, '2025-02-07', 1, 18000, 5),
    (6, 5, '2025-03-09', 2, 78000, 0),
    (13, 7, '2025-11-10', 3, NULL, 10),
    (9, 10, '2025-03-10', 2, 22000, 0),
    (4, 3, '2025-06-25', 1, 18000, 0),
    (1, 7, '2025-05-22', 1, 15000, 0),
    (2, 5, '2025-12-28', 2, NULL, NULL),
    (15, 6, '2025-07-09', 3, 95000, 10),
    (14, 8, '2025-01-21', 1, 120000, 0),
    (12, 10, '2025-07-28', 3, 22000, 0),
    (12, 2, '2025-07-31', 1, 45000, 0),
    (12, 9, '2025-05-08', 2, 38000, 0),
    (13, 3, '2025-08-24', 2, 18000, 0),
    (9, 4, '2025-05-23', 1, 62000, 0),
    (13, 3, '2025-01-15', 1, 18000, 0),
    (1, 4, '2025-06-10', 2, 62000, 10),
    (3, 1, '2025-08-12', 1, 850000, 0),
    (15, 7, '2025-04-11', 2, NULL, 5),
    (4, 9, '2025-06-03', 3, 38000, 0),
    (7, 3, '2025-12-07', 2, 18000, 0),
    (1, 3, '2025-08-09', 3, 18000, 10),
    (3, 5, '2025-03-28', 3, 78000, 0),
    (1, 10, NULL, 3, 22000, 0),
    (3, 5, '2025-02-07', 2, 78000, 5),
    (5, 4, '2025-03-17', 3, 62000, 0),
    (11, 3, '2025-12-23', 3, NULL, 5),
    (6, 8, '2025-12-08', 1, 120000, 10),
    (14, 7, '2025-09-16', 2, 15000, 10),
    (6, 7, '2025-11-23', 2, 15000, 10),
    (11, 3, '2025-06-21', 2, NULL, 10),
    (2, 3, '2025-08-01', 2, 18000, 0),
    (6, 10, '2025-10-27', 3, 22000, 0),
    (1, 3, '2025-07-19', 2, 18000, 10),
    (3, 3, '2025-08-12', 2, 18000, 0);

-- Verificación rápida de la carga (esperado: 15 / 12 / 70)
SELECT (SELECT COUNT(*) FROM clientes)  AS clientes,
       (SELECT COUNT(*) FROM productos) AS productos,
       (SELECT COUNT(*) FROM pedidos)   AS pedidos;
