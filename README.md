# Capstone PostgreSQL: análisis exploratorio de una tienda online

Proyecto final del curso de PostgreSQL. Simula el trabajo de un analista de datos: cargar un dataset, limpiarlo, analizarlo con SQL e interpretar los resultados para un equipo directivo.

## Problema de negocio

Una tienda online de electrónica, indumentaria, hogar y accesorios quiere responder tres preguntas:

1. ¿Qué clientes sostienen el ingreso y cómo de concentrado está?
2. ¿En qué momentos del año se cae la venta?
3. ¿Qué productos y categorías rinden poco y hay que revisar?

## Dataset

Dataset **sintético** creado para este proyecto, con 3 tablas:

| Tabla | Filas | Descripción |
|---|---|---|
| `clientes` | 15 | Nombre, ciudad y email |
| `productos` | 12 | Nombre, categoría y precio de lista |
| `pedidos` | 70 | Un producto por pedido, entre enero y diciembre de 2025 |

Los pedidos incluyen nulos a propósito para practicar la limpieza: 9 sin `precio_unitario`, 1 sin `descuento_pct` y 2 sin `fecha_pedido`.

## Estructura del repositorio

- `estructura.sql`: creación de tablas (con tipos `DATE`, `NUMERIC`, claves y restricciones) e inserción de datos.
- `analisis.sql`: limpieza y consultas de análisis, comentadas con el *por qué* de cada decisión.
- `README.md`: este archivo.

## Cómo ejecutarlo

```bash
# 1. Crear la base de datos
createdb capstone_project

# 2. Crear tablas y cargar datos
psql -d capstone_project -f estructura.sql

# 3. Correr el análisis
psql -d capstone_project -f analisis.sql
```

También podés hacerlo desde pgAdmin: crear la base `capstone_project`, abrir el *Query Tool* y ejecutar primero `estructura.sql` y después `analisis.sql`.

## Limpieza de datos

| Problema | Decisión | Motivo |
|---|---|---|
| 9 pedidos sin precio | `COALESCE(precio_unitario, precio_lista)` | Descartarlos subestimaría las ventas; el precio de lista es la mejor aproximación |
| 1 pedido sin descuento | `COALESCE(descuento_pct, 0)` | Sin registro asumimos precio pleno |
| 2 pedidos sin fecha | Se excluyen solo de las ventas mensuales | Inventar una fecha falsearía la estacionalidad |

Además se validaron los tipos de datos, la ausencia de emails duplicados y que la vista limpia conserve las 70 filas (sin explosión de filas en los JOINs). Todo el análisis se hace sobre la vista `pedidos_limpios`.

## Hallazgos principales

Ingreso total analizado: **$8.350.700** (los pedidos sin fecha suman $144.000 y solo quedan fuera del análisis mensual, que cubre $8.206.700).

### 1. Los clientes leales sostienen casi el 70% del ingreso
Solo 5 de los 15 clientes (33%) hicieron 5 o más pedidos y generan el **68,4%** del ingreso. Los 7 recurrentes aportan el 18,1% y los 3 ocasionales el 13,5%.
**Interpretación:** perder un puñado de clientes leales tendría un impacto desproporcionado. Conviene un programa de retención antes que salir a captar clientes nuevos.

Top 5 por gasto: Camila Rossi ($2.195.700), Milagros Ponce ($1.079.700), Renata Luna ($879.000), Santiago Ruiz ($858.900) y Mateo Herrera ($850.000). Camila sola representa el 26% del ingreso. Mateo aparece quinto con **un único pedido** (una notebook): es un comprador de ticket alto, no un cliente frecuente, y no debería tratarse igual en una campaña de fidelización.

### 2. La venta cae fuerte en el último trimestre
Agosto es el mejor mes ($1,30 M), seguido por febrero, mayo y junio (entre $1,08 M y $1,14 M). Entre septiembre y noviembre las ventas suman $647.000, contra $3,10 M de junio a agosto. Noviembre es el piso ($108.000). Diciembre se recupera en cantidad de pedidos (9), pero con un ticket bajo ($644.250 en total).
**Interpretación:** hay un bache de septiembre a noviembre. Es el momento para promociones o campañas, y para revisar por qué el pico de fin de año no se traduce en más facturación.

### 3. Electrónica concentra el ingreso; Accesorios casi no existe
Electrónica genera el **58,3%** de las ventas, Indumentaria el 26,1%, Hogar el 15,2% y Accesorios apenas el 0,4% (un solo pedido en todo el año).
**Interpretación:** hay dependencia de una categoría. Si electrónica se ve afectada (precio, stock, competencia), el negocio se resiente. Accesorios necesita una decisión: impulsarla o replantearla.

### 4. Productos menos vendidos
Botella térmica (**0 unidades**, nunca se vendió), Mochila urbana (1 unidad) y un empate en 4 unidades entre Cafetera express y Notebook 14''. La consulta devuelve Cafetera express por desempate alfabético.
**Interpretación:** los dos primeros son candidatos claros a liquidar o promocionar. El empate no tiene el mismo significado: la notebook vende poco en unidades pero es el producto de mayor valor, así que "menos vendido" no equivale a "menos rentable".

### 5. Pedidos de mayor valor por categoría (RANK)
En Electrónica los pedidos top son notebooks ($850.000, dos empatados en el primer puesto). En Indumentaria y Hogar los primeros puestos también son empates (uso de `RANK()` en lugar de `ROW_NUMBER()`), y Accesorios tiene un único pedido en el ranking.
**Interpretación:** los pedidos más grandes se explican por la cantidad de unidades y por productos caros; confirma que el ticket alto se concentra en pocos productos.

## Limitaciones

- El dataset es sintético y pequeño (70 pedidos): los porcentajes son ilustrativos, no representan una tienda real.
- Cada pedido tiene un solo producto; en un caso real habría una tabla de detalle de pedido.
- Los umbrales de segmentación (5 y 3 pedidos) se eligieron para este volumen de datos.
- Los hallazgos se calcularon con un motor SQL equivalente; conviene ejecutar los scripts en PostgreSQL y confirmar que los resultados coincidan.

## Autor

_Tu nombre_ (completá con tu nombre y el enlace a tu perfil de GitHub)
