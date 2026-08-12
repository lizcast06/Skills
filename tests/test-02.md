# Test 02 — Error evidente (múltiples violaciones claras)

## Input
Contenido de `examples/invalid.sql`.

## Expected behavior
Debe detectar, como mínimo: SELECT * (P1), UPDATE sin WHERE (S1,
CRITICAL), DELETE sin WHERE (S1, CRITICAL), comparación con NULL incorrecta
(C2), FLOAT para monto (C3, HIGH), nombre no descriptivo `t1`/`x` (C1).

## Actual behavior
La skill reportó los 6 hallazgos esperados con las severidades de la tabla
de `SKILL.md`:
- UPDATE sin WHERE → CRITICAL
- DELETE sin WHERE → CRITICAL
- SELECT * (x2) → MEDIUM
- `cancelled_reason = NULL` → MEDIUM
- `amount FLOAT` → HIGH
- `created TEXT` para timestamp → MEDIUM (tipo de dato incorrecto)
- `t1`, `x` → LOW

No inventó hallazgos adicionales fuera de lo detectable en el texto.

## Pass / Fail
Pass.

## Problem detected
Ninguno.

## Modification made to the skill
Ninguna.
