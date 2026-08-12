# Test 03 — Edge case

## Input
```sql
SELECT * FROM orders WHERE YEAR(created_at) = 2024;
```
(Quinto caso de `examples/edge-cases.sql`.)

## Expected behavior
Superficialmente parece una consulta normal y acotada por fecha. La skill
debe detectar que `YEAR(created_at)` aplica una función sobre la columna
filtrada, lo que impide el uso de índice sobre `created_at` aunque exista
(regla P4), y además marcar el `SELECT *` (P1).

## Actual behavior
En la primera versión de la skill, el hallazgo de P4 no se generó: la
regla original solo mencionaba "funciones sobre columnas indexadas" sin
dar un procedimiento de detección textual, y el modelo no lo reconoció como
aplicable porque no había información sobre si la columna tenía índice.

## Pass / Fail
Fail (primera iteración) → Pass (después de la corrección).

## Problem detected
La regla P4 dependía implícitamente de saber si había índice, cuando en
realidad el problema (impedir el *uso* de un índice, si existiera) es
detectable solo mirando la sintaxis: cualquier función envolviendo la
columna en el WHERE es candidata, independientemente de si hoy tiene
índice o no.

## Modification made to the skill
Se reescribió P4 en `rules/performance.md` para que dispare únicamente en
base a la forma sintáctica (función envolviendo la columna en el WHERE),
sin condicionarlo a confirmar la existencia de un índice. Se agregó
"Confianza: media" en el output para este caso, ya que el impacto real
depende de si el índice existe.
