-- =====================================================================
-- analisis.sql
-- Proyecto Capstone: EDA en PostgreSQL (tienda online)
-- Requiere haber ejecutado antes estructura.sql en la base capstone_project.
--
-- Pregunta de negocio: ¿de dónde viene el ingreso, qué clientes y productos
-- lo sostienen y en qué momentos del año se nos cae la venta?
-- =====================================================================


-- =====================================================================
-- 1. LIMPIEZA Y VALIDACIÓN (antes de analizar nada)
-- =====================================================================

-- 1.1 Diagnóstico de nulos en las columnas críticas.
-- Lo medimos primero para decidir con datos qué hacer con cada una.
SELECT
    COUNT(*)                                              AS total_pedidos,
    COUNT(*) FILTER (WHERE fecha_pedido    IS NULL)       AS sin_fecha,
    COUNT(*) FILTER (WHERE precio_unitario IS NULL)       AS sin_precio,
    COUNT(*) FILTER (WHERE descuento_pct   IS NULL)       AS sin_descuento
FROM pedidos;

-- 1.2 Verificación de tipos de datos: fechas como DATE y montos como NUMERIC.
-- Si una fecha estuviera guardada como texto, DATE_TRUNC y los ordenamientos
-- cronológicos fallarían o darían resultados engañosos.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('clientes', 'productos', 'pedidos')
ORDER BY table_name, ordinal_position;

-- 1.3 Control de duplicados: un email repetido significaría el mismo cliente
-- cargado dos veces y distorsionaría el ranking de gasto por cliente.
-- (Esperado: 0 filas; además la restricción UNIQUE lo previene.)
SELECT email, COUNT(*) AS repeticiones
FROM clientes
GROUP BY email
HAVING COUNT(*) > 1;

-- 1.4 Vista con datos limpios. Reglas de tratamiento de nulos:
--   * precio_unitario nulo  -> usamos el precio de lista del producto.
--     Preferimos imputar antes que descartar: perder el pedido subestimaría
--     las ventas, y el precio de lista es la mejor aproximación disponible.
--   * descuento_pct nulo    -> 0. Sin registro de descuento asumimos precio pleno.
--   * fecha_pedido nula     -> NO se inventa una fecha: inventarla falsearía la
--     estacionalidad. El pedido cuenta en gasto por cliente/producto, pero se
--     excluye de las ventas mensuales (ver consulta 2).
CREATE OR REPLACE VIEW pedidos_limpios AS
SELECT
    p.id_pedido,
    p.id_cliente,
    p.id_producto,
    pr.nombre                                         AS producto,
    pr.categoria,
    p.fecha_pedido,
    p.cantidad,
    COALESCE(p.precio_unitario, pr.precio_lista)      AS precio_aplicado,
    COALESCE(p.descuento_pct, 0)                      AS descuento_pct,
    (p.precio_unitario IS NULL)                       AS precio_imputado,
    ROUND(
        p.cantidad
        * COALESCE(p.precio_unitario, pr.precio_lista)
        * (1 - COALESCE(p.descuento_pct, 0) / 100.0)
    , 2)                                              AS total_linea
FROM pedidos p
JOIN productos pr ON pr.id_producto = p.id_producto;

-- 1.5 Control de sanidad de la vista: el conteo de filas debe coincidir con
-- la tabla original; si no, el JOIN está duplicando o perdiendo pedidos.
SELECT
    (SELECT COUNT(*) FROM pedidos)          AS filas_pedidos,
    (SELECT COUNT(*) FROM pedidos_limpios)  AS filas_vista;


-- =====================================================================
-- 2. ANÁLISIS
-- =====================================================================

-- ---------------------------------------------------------------------
-- Consulta 1: Top 5 clientes por gasto total (JOIN + GROUP BY + SUM)
-- Por qué: saber quién concentra el ingreso para priorizar retención y
-- programas de fidelización. Mostramos también la cantidad de pedidos
-- para distinguir clientes frecuentes de compradores de un ticket grande.
-- ---------------------------------------------------------------------
SELECT
    c.nombre,
    c.ciudad,
    COUNT(*)              AS cantidad_pedidos,
    SUM(pl.total_linea)   AS gasto_total
FROM pedidos_limpios pl
JOIN clientes c ON c.id_cliente = pl.id_cliente
GROUP BY c.id_cliente, c.nombre, c.ciudad
ORDER BY gasto_total DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- Consulta 2: Ventas totales por mes (funciones de fecha)
-- Por qué: detectar estacionalidad y los meses flojos donde conviene
-- lanzar campañas. Excluimos pedidos sin fecha (decisión de la sección 1.4).
-- ---------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', fecha_pedido)::date  AS mes,
    COUNT(*)                                 AS pedidos,
    SUM(total_linea)                         AS ventas_totales
FROM pedidos_limpios
WHERE fecha_pedido IS NOT NULL
GROUP BY DATE_TRUNC('month', fecha_pedido)
ORDER BY mes;

-- ---------------------------------------------------------------------
-- Consulta 3: Los 3 productos menos vendidos (LEFT JOIN + COALESCE)
-- Por qué: LEFT JOIN para no perder productos que NUNCA se vendieron
-- (con INNER JOIN desaparecerían justo los que más nos interesan).
-- COALESCE convierte el NULL de "sin ventas" en 0 unidades.
-- Desempate por nombre para que el resultado sea reproducible; ojo: puede
-- haber empates en el tercer lugar (ver README).
-- ---------------------------------------------------------------------
SELECT
    pr.nombre,
    pr.categoria,
    COALESCE(SUM(pl.cantidad), 0)  AS unidades_vendidas
FROM productos pr
LEFT JOIN pedidos_limpios pl ON pl.id_producto = pr.id_producto
GROUP BY pr.id_producto, pr.nombre, pr.categoria
ORDER BY unidades_vendidas ASC, pr.nombre
LIMIT 3;

-- ---------------------------------------------------------------------
-- Consulta 4: Ranking de pedidos por categoría con RANK() (Window Function)
-- Por qué: ver cuáles son los pedidos de mayor valor dentro de cada
-- categoría, sin perder el detalle de cada fila. Usamos RANK() y no
-- ROW_NUMBER() porque queremos que pedidos con el mismo monto compartan
-- posición en lugar de desempatar de forma arbitraria.
-- Nos quedamos con las posiciones 1 a 3 de cada categoría.
-- ---------------------------------------------------------------------
WITH ranking AS (
    SELECT
        categoria,
        id_pedido,
        producto,
        total_linea,
        RANK() OVER (PARTITION BY categoria ORDER BY total_linea DESC) AS posicion
    FROM pedidos_limpios
)
SELECT categoria, posicion, id_pedido, producto, total_linea
FROM ranking
WHERE posicion <= 3
ORDER BY categoria, posicion, id_pedido;

-- ---------------------------------------------------------------------
-- Consulta 5 (extra): Segmentación de clientes con CASE + CTE
-- Por qué: agrupar clientes por frecuencia para medir cuánto ingreso
-- depende de los más fieles. Umbrales definidos para este dataset:
-- 5 o más pedidos = leal, 3 o 4 = recurrente, menos de 3 = ocasional.
-- ---------------------------------------------------------------------
WITH resumen_cliente AS (
    SELECT
        id_cliente,
        COUNT(*)          AS pedidos,
        SUM(total_linea)  AS gasto
    FROM pedidos_limpios
    GROUP BY id_cliente
)
SELECT
    CASE
        WHEN pedidos >= 5 THEN 'Leal'
        WHEN pedidos >= 3 THEN 'Recurrente'
        ELSE 'Ocasional'
    END                                                        AS segmento,
    COUNT(*)                                                   AS clientes,
    SUM(gasto)                                                 AS gasto_total,
    ROUND(100.0 * SUM(gasto) / SUM(SUM(gasto)) OVER (), 1)     AS pct_del_ingreso
FROM resumen_cliente
GROUP BY 1
ORDER BY gasto_total DESC;

-- ---------------------------------------------------------------------
-- Consulta 6 (extra): Participación de cada categoría en el ingreso
-- Por qué: medir dependencia. SUM() OVER () calcula el total general en la
-- misma consulta, así obtenemos el porcentaje sin una subconsulta aparte.
-- ---------------------------------------------------------------------
SELECT
    categoria,
    COUNT(*)                                                   AS pedidos,
    SUM(total_linea)                                           AS ventas,
    ROUND(100.0 * SUM(total_linea) / SUM(SUM(total_linea)) OVER (), 1) AS pct_del_ingreso
FROM pedidos_limpios
GROUP BY categoria
ORDER BY ventas DESC;
