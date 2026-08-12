# Security Rules

Estas reglas se evalúan primero (ver `SKILL.md` / Procedure). Todas siguen el
principio de "Razonamiento sobre intención": una regla no se descarta solo
porque la sentencia tiene *algo* que parece cumplirla.

## S1 — UPDATE/DELETE sin WHERE seguro

```
IF statement = UPDATE OR statement = DELETE
AND WHERE is absent
THEN severity = CRITICAL
AND do not recommend executing the statement

IF statement = UPDATE OR statement = DELETE
AND WHERE exists
AND WHERE is a tautology or equivalent-to-tautology
   (ej: 1=1, 'a'='a', LIKE '%', OR 1=1, condición sobre columna que
   siempre es verdadera para el dominio descrito)
THEN severity = CRITICAL
AND note = "el WHERE existe pero no restringe filas de forma efectiva"

IF statement = UPDATE OR statement = DELETE
AND WHERE exists
AND WHERE filtra por una columna sin garantía de unicidad
   (ej. WHERE FCROLE = 'X' en vez de WHERE ID = 123) sobre una tabla que
   parece de usuarios/producción
THEN severity = HIGH
AND note = "confirmar cuántas filas matchean antes de ejecutar"
```

## S2 — Concatenación que facilita SQL Injection

```
IF una sentencia construye SQL concatenando variables/inputs directamente
   en el string (ej: "... WHERE id = " + userInput, o f-strings/format con
   interpolación directa de una variable dentro del SQL)
THEN severity = CRITICAL
AND recommend = "usar sentencias preparadas / parámetros bind, nunca
   concatenar input de usuario en el texto SQL"
```

Nota: si la concatenación es de valores literales fijos definidos en el
propio script (no provienen de input externo), la severidad baja a `LOW`
(antipatrón de mantenibilidad, no vulnerabilidad real) — pero solo si se
puede confirmar que el valor no viene de fuera. Si no se puede confirmar el
origen del valor, no se asume que es seguro: se marca `INFO` pidiendo
aclarar el origen del dato antes de descartar el riesgo.

## S3 — Operaciones potencialmente destructivas

```
IF statement es DROP TABLE, DROP DATABASE, TRUNCATE
THEN severity = CRITICAL
AND recommend = "confirmar backup y ejecutar en ventana controlada;
   preferir soft-delete o script reversible si aplica"

IF statement es ALTER TABLE ... DROP COLUMN
THEN severity = HIGH
AND recommend = "verificar que ninguna vista/aplicación dependa de la
   columna antes de eliminarla"
```

## S4 — Escalación de privilegios / campos sensibles

```
IF statement = UPDATE
AND la columna modificada corresponde semánticamente a rol, permiso,
    contraseña o campo de autorización (ej. ROLE, PASSWORD, IS_ADMIN,
    PERMISSION)
AND el WHERE no identifica una fila específica de forma inequívoca
    (ver S1 sobre WHERE no seguro)
THEN severity = CRITICAL
AND note = "combina escalación de privilegios con alcance no acotado:
   tratar como el hallazgo más severo posible, no promediar con otras
   reglas"
```

## Failure handling específico de seguridad

Si no se puede determinar si un valor concatenado proviene de input
externo o de una constante fija del script, **no se asume que es seguro**.
Se reporta como `INFO`/riesgo potencial pendiente de confirmación, nunca se
omite el hallazgo por falta de certeza.
