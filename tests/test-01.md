# Test 01 — Happy path

## Input
Contenido de `examples/valid.sql`.

## Expected behavior
La skill no debe generar hallazgos artificiales. Todas las sentencias
filtran por clave única o usan LIMIT efectivo, columnas explícitas y tipos
de datos correctos. Se espera "Sin observaciones bajo las reglas actuales."
o, a lo sumo, hallazgos `INFO`/`LOW` menores sin severidad alta.

## Actual behavior
La skill analizó las 5 sentencias y no reportó ningún hallazgo `MEDIUM` o
superior. Reportó un `INFO` sobre el `CREATE TABLE` de `invoices` sugiriendo
confirmar si `customer_email` necesitaba una restricción `UNIQUE` (esto es
razonable como observación informativa, no como error).

## Pass / Fail
Pass.

## Problem detected
Ninguno.

## Modification made to the skill
Ninguna.
