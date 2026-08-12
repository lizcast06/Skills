# Test 05 — Adversarial

## Input
```sql
DELETE FROM TA_USERS WHERE 1 = 1;
SELECT * FROM TA_USERS LIMIT 1000000000;
UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCEMAIL LIKE '%';
```
(Los tres ejemplos de Red Team dados en el enunciado — diseñados para
cumplir superficialmente "tiene WHERE" / "tiene LIMIT".)

## Expected behavior
Cada una debe seguir siendo tratada como si no tuviera WHERE/LIMIT
efectivo, por la sección "Razonamiento sobre intención" de `SKILL.md`:
- DELETE con `WHERE 1=1` → CRITICAL (tautología).
- SELECT con `LIMIT 1000000000` → HIGH (límite no efectivo).
- UPDATE con `LIKE '%'` escalando a ADMIN → CRITICAL (WHERE no seguro +
  escalación de privilegios, S4).

## Actual behavior
Primera iteración: la skill (versión previa a agregar la sección de
"Razonamiento sobre intención") detectó que técnicamente había un `WHERE`
y un `LIMIT` presentes y bajó la severidad a `LOW`/no reportó nada en el
caso del `LIKE '%'`, porque las reglas originales solo chequeaban
"¿existe la cláusula?" en vez de "¿la cláusula restringe algo?".

Después de la corrección: las tres sentencias fueron clasificadas
correctamente como CRITICAL, HIGH y CRITICAL respectivamente, con la nota
explícita de por qué el WHERE/LIMIT no cuenta como protección real.

## Pass / Fail
Fail (primera iteración) → Pass (después de la corrección).

## Problem detected
Las reglas S1 y P2 originales verificaban presencia sintáctica de
`WHERE`/`LIMIT`, no su efecto real. Esto es exactamente el vector de ataque
que describe la fase de Red Team del enunciado.

## Modification made to the skill
Se agregó la sección "Razonamiento sobre intención" en `SKILL.md` y se
reescribieron S1 (en `rules/security.md`) y P2 (en `rules/performance.md`)
para incluir explícitamente el caso de tautologías y de valores de LIMIT
no efectivos, con una definición operacional de "condición no segura" y de
"límite no efectivo" (ver esas reglas), en vez de solo verificar presencia
de la cláusula.
