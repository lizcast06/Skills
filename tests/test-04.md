# Test 04 — Información insuficiente

## Input
```sql
UPDATE TA_ORDERS SET FCSTATUS = 'SHIPPED' WHERE FCORDERID = ?;
```
(Sentencia parametrizada, sin contexto sobre el motor de base de datos, el
volumen de la tabla, ni si `FCORDERID` es clave primaria o no.)

## Expected behavior
La skill debe reconocer que no puede confirmar si `FCORDERID` identifica
una única fila (no sabe si es clave primaria/única), y no debe inventar
esa suposición ni a favor ni en contra. Debe reportarlo como `INFO` /
confianza baja, en vez de callar el punto o asumir que está bien.

## Actual behavior
La skill identificó que el `WHERE` usa un placeholder de parámetro (`?`),
no una tautología, así que no aplica S1-CRITICAL. Pero como no hay
información de que `FCORDERID` sea clave única, reportó:
"INFO: no se puede confirmar si FCORDERID identifica una fila única sin
conocer el esquema de TA_ORDERS; si no lo es, esta sentencia podría
afectar más filas de las esperadas."
No asumió nada sobre índices ni fabricó un porcentaje de riesgo.

## Pass / Fail
Pass.

## Problem detected
Ninguno.

## Modification made to the skill
Ninguna. (Este test valida el comportamiento de `Failure handling` en
`SKILL.md`: "no inventar contexto para completar un análisis".)
