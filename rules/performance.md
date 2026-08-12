# Performance Rules

## P1 — SELECT *

```
IF statement = SELECT
AND columnas = "*"
THEN severity = MEDIUM
AND recommend = "listar explícitamente las columnas necesarias; reduce
   I/O, evita romper contratos si la tabla cambia, y hace explícito qué
   necesita el consumidor"
```

Excepción: si es un `SELECT *` dentro de una subconsulta `EXISTS (...)`
donde no se proyectan columnas, baja a `LOW` (no hay costo real de
transferencia de datos).

## P2 — Ausencia de LIMIT (o LIMIT inefectivo) en consultas potencialmente masivas

```
IF statement = SELECT
AND no tiene cláusula LIMIT / equivalente
AND no es un agregado que ya devuelve una sola fila (COUNT, SUM sin
    GROUP BY, etc.)
THEN severity = HIGH
AND recommend = "agregar LIMIT explícito y paginación si el consumo es
   para UI o proceso batch incremental"

IF statement = SELECT
AND tiene LIMIT
AND el valor de LIMIT es, en la práctica, indistinguible de "sin límite"
    para el contexto descrito (por defecto, sin más contexto sobre el
    tamaño esperado de la tabla, se considera "sin límite efectivo" un
    valor >= 1,000,000, o cualquier valor claramente desproporcionado
    frente al uso típico ej. UI paginada)
THEN severity = HIGH
AND note = "el LIMIT existe pero no cumple su función real, tratar igual
   que ausencia de LIMIT"
```

## P3 — Índices potencialmente faltantes

```
IF statement = SELECT o UPDATE o DELETE
AND el WHERE filtra por una columna
AND no hay información de que esa columna tenga índice
THEN severity = MEDIUM
AND note = "no se puede confirmar sin ver el esquema; recomendar verificar
   índice en <columna> si la tabla es grande"
```

Este hallazgo siempre se reporta con "Confianza: baja" porque depende de
contexto que normalmente no está disponible (ver `SKILL.md` / Failure
handling) — no se debe subir a severidad alta sin confirmar el esquema.

## P4 — Funciones sobre columnas indexadas en el WHERE

```
IF WHERE aplica una función sobre la columna filtrada
   (ej. WHERE YEAR(fecha) = 2024, WHERE UPPER(nombre) = 'X')
THEN severity = MEDIUM
AND recommend = "reescribir para que la columna quede 'limpia' en la
   comparación (ej. WHERE fecha >= '2024-01-01' AND fecha < '2025-01-01')
   así el motor puede usar el índice"
```

## P5 — Otros antipatrones razonables de rendimiento

```
IF hay un JOIN sin condición de unión explícita (cross join implícito por
   listar tablas separadas por coma sin WHERE de unión)
THEN severity = HIGH
AND note = "probable producto cartesiano no intencional"

IF hay subconsultas correlacionadas repetidas en el SELECT list que podrían
   reescribirse como un JOIN
THEN severity = LOW
AND recommend = "evaluar reescribir como JOIN si el volumen lo justifica"
```
