# Conventions Rules

## C1 — Nombres poco descriptivos

```
IF nombre de tabla o columna es de 1-2 caracteres no estándar
   (ej. "a", "t1", "x") o es un acrónimo no documentado en el propio script
THEN severity = LOW
AND recommend = "usar nombres que describan el contenido/dominio"
```

Nota: prefijos consistentes de una convención propia del sistema (ej.
`TA_` para tablas, `FC` para columnas de un módulo específico) NO se
penalizan si son consistentes en todo el script — eso es una convención de
equipo, no un nombre poco descriptivo. Solo se marca si el nombre en sí,
quitando el prefijo, sigue sin decir nada (ej. `TA_X`, `FCVAL1`).

## C2 — Uso incorrecto de NULL

```
IF hay una comparación tipo "columna = NULL" o "columna != NULL"
THEN severity = MEDIUM
AND recommend = "usar IS NULL / IS NOT NULL; '= NULL' nunca es verdadero
   en SQL estándar y el filtro no hace lo que parece"

IF una columna que representa una cantidad/monto permite NULL sin que el
   script indique que "ausente" y "cero" deban distinguirse
THEN severity = LOW
AND note = "confirmar si NULL y 0 tienen significados distintos en este
   dominio; si no, considerar NOT NULL DEFAULT 0"
```

## C3 — Problemas en la elección de tipos de datos

```
IF una columna que almacena solo fechas usa tipo texto/VARCHAR en vez de
   DATE/DATETIME
THEN severity = MEDIUM
AND recommend = "usar tipo DATE/DATETIME nativo para permitir
   comparaciones y validación correctas"

IF una columna monetaria usa FLOAT/DOUBLE en vez de DECIMAL/NUMERIC
THEN severity = HIGH
AND recommend = "usar DECIMAL/NUMERIC para evitar errores de redondeo en
   montos"

IF una columna identificadora (ID) usa un tipo más grande de lo necesario
   sin justificación (ej. BIGINT para una tabla de catálogo con <100 filas)
THEN severity = INFO
AND note = "no es un error, pero vale la pena confirmar la intención"
```

## Reglas adicionales del equipo

_(Este espacio es para las reglas propias que agrega el equipo, como pide
el enunciado — "Violaciones adicionales definidas explícitamente por el
propio equipo". Documentar acá con el mismo formato IF/THEN antes de la
defensa, así queda claro qué reglas son del enunciado y cuáles agregó el
equipo.)_
