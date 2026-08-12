# SQL Reviewer

## Purpose

Actuar como un revisor técnico de base de datos sobre sentencias o scripts SQL
ya escritos por un humano. La skill **analiza y clasifica hallazgos**; no
escribe SQL nuevo, no ejecuta sentencias, no corrige código automáticamente
salvo que se le pida explícitamente una sugerencia de reemplazo.

Motor de referencia asumido: **MySQL / PostgreSQL** (sintaxis estándar tipo
`LIMIT`). Si el usuario indica otro motor (SQL Server, Oracle, etc.), ver
"Adaptación a otro motor" al final de este documento antes de aplicar las
reglas de `rules/performance.md` relacionadas a paginación.

## When to activate

- El usuario pega una o más sentencias SQL (`SELECT`, `INSERT`, `UPDATE`,
  `DELETE`, `CREATE`, `ALTER`, etc.) y pide revisión, feedback, "¿esto está
  bien?", "encontrá problemas", "hacé code review de este SQL", etc.
- El usuario sube un archivo `.sql` y pide análisis.
- El usuario pide explícitamente clasificar severidad de problemas en SQL.

## When NOT to activate

- El usuario pide **generar** una consulta SQL desde cero (esa es una tarea
  de escritura, no de revisión). En ese caso la skill no aplica; se puede
  ofrecer escribir la consulta y luego, si el usuario quiere, revisarla.
- El texto pegado no es SQL parseable (es pseudocódigo, texto natural, o está
  tan corrupto que no se puede identificar el tipo de sentencia). En ese caso
  la skill debe decirlo explícitamente y pedir el SQL real, no adivinar.
- El usuario pide una opinión general sobre buenas prácticas de SQL sin traer
  código concreto para revisar (eso es una pregunta conceptual, no una
  revisión).
- El usuario pide ejecutar la consulta contra una base de datos real. La
  skill no ejecuta nada; solo analiza estáticamente el texto.

## Inputs

Obligatorio:
- El texto de la(s) sentencia(s) SQL.

Opcional (afecta la profundidad del análisis, ver "Failure handling"):
- Motor de base de datos objetivo.
- Si la tabla es de producción y su volumen aproximado de filas.
- Índices existentes sobre las columnas involucradas.
- Si la sentencia corre dentro de una transacción controlada por la
  aplicación.

## Procedure

Este procedimiento es determinista: se sigue en este orden para cada
sentencia detectada en el input.

1. **Separar el script en sentencias individuales** (dividir por `;`,
   ignorando `;` dentro de strings o comentarios).
2. **Identificar el tipo de cada sentencia**: `SELECT`, `INSERT`, `UPDATE`,
   `DELETE`, DDL (`CREATE`/`ALTER`/`DROP`), u "otro/no reconocido".
3. **Aplicar, en este orden de prioridad, los checklists de**:
   1. `rules/security.md` (siempre primero: lo destructivo e inseguro pesa
      más que el estilo)
   2. `rules/performance.md`
   3. `rules/conventions.md`
4. **Para cada regla que dispare un hallazgo**, asignar severidad según la
   tabla de "Severity levels" y la regla específica en el archivo
   correspondiente (no se improvisa la severidad; si una regla no tiene
   severidad asignada explícitamente en `rules/*.md`, se marca `INFO` y se
   señala como pendiente de definición del equipo).
5. **Evaluar intención/impacto, no solo forma superficial** (ver
   "Razonamiento sobre intención" abajo). Cumplir sintácticamente una regla
   (tener un `WHERE`, tener un `LIMIT`) no implica que el hallazgo se
   descarte si la condición es efectivamente inofensiva/no restrictiva.
6. **Si falta contexto** para completar un check (por ejemplo, no se sabe si
   hay índice en una columna de un `WHERE`), no se inventa: se reporta como
   `INFO` con el texto "No se puede determinar sin conocer [dato faltante]".
7. **Generar el output** en el formato de "Expected output".
8. **Aplicar auto-validación** (ver "Validation") antes de entregar la
   respuesta.

### Razonamiento sobre intención (no solo forma)

La fase de Red Team del ejercicio existe justamente para exponer esto: un
`WHERE` o un `LIMIT` presentes no bastan. Ejemplos que la skill debe seguir
tratando como peligrosos aunque cumplan la forma:

```
DELETE FROM TA_USERS WHERE 1 = 1;
```
Tiene `WHERE`, pero la condición es una tautología: afecta al 100% de las
filas igual que si no existiera. → mismo tratamiento que un `DELETE` sin
`WHERE` (`CRITICAL`).

```
SELECT * FROM TA_USERS LIMIT 1000000000;
```
Tiene `LIMIT`, pero el valor no acota nada realista: sigue siendo,
efectivamente, una consulta sin límite práctico. → tratar como ausencia de
`LIMIT` efectivo (`HIGH`, ver `rules/performance.md`).

```
UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCEMAIL LIKE '%';
```
Tiene `WHERE`, pero `LIKE '%'` coincide con cualquier valor no nulo: es
equivalente a no tener condición, y además está escalando privilegios de
forma masiva. → `CRITICAL` (combina "WHERE no seguro" + "operación
destructiva/sensible", ver `rules/security.md`).

Regla general aplicable a cualquier entrada nueva, incluida una diseñada
para evadir las reglas: **una condición de `WHERE` se considera "no segura"
si, evaluada en abstracto, es verdadera para un conjunto de filas
indistinguible de "todas las filas"** (tautologías, comparaciones contra
`LIKE '%'` sin más filtro, `OR 1=1`, condiciones sobre columnas que
siempre se cumplen, etc.). Ídem para `LIMIT`: se considera "no efectivo" si
el número es igual o mayor a un umbral que en la práctica equivale a "sin
límite" para el tipo de tabla descrito (por defecto, sin más contexto, se
usa un umbral conservador; ver `rules/performance.md`).

## Rules

Los criterios detallados, con ejemplos y la tabla `IF/THEN` de severidad
para cada uno, viven en:

- `rules/security.md` — inyección SQL, `WHERE` inseguro, operaciones
  destructivas, escalación de privilegios.
- `rules/performance.md` — `SELECT *`, `LIMIT` ausente o inefectivo, índices
  faltantes, problemas de rendimiento razonables.
- `rules/conventions.md` — nombres poco descriptivos, uso incorrecto de
  `NULL`, elección de tipos de datos.

Cuando dos reglas de archivos distintos aplican al mismo hallazgo (por
ejemplo, un `UPDATE` sin `WHERE` que además usa concatenación insegura),
**se reporta como dos hallazgos separados**, no se combinan en uno, para
que cada uno se pueda corregir y verificar de forma independiente.

### Conflicto entre reglas

Si dos reglas indicaran severidades distintas para el mismo hallazgo
puntual (esto no debería pasar si las reglas están bien delimitadas, pero
si ocurre): **gana la severidad más alta** (la más conservadora), y se
documenta la ambigüedad en el output con una nota "posible solapamiento de
reglas: revisar `rules/X.md` vs `rules/Y.md`". Esto evita que un conflicto
de reglas termine subestimando un riesgo.

## Severity levels

| Nivel    | Criterio objetivo |
|----------|--------------------|
| CRITICAL | Riesgo de pérdida irreversible de datos, o brecha de seguridad explotable (injection, escalación de privilegios masiva). No se recomienda ejecutar la sentencia tal cual. |
| HIGH     | Alto impacto probable (bloqueo de tabla, consulta que puede tumbar producción, `LIMIT`/`WHERE` inefectivos) pero no necesariamente irreversible. |
| MEDIUM   | Riesgo moderado o antipatrón conocido que degrada mantenibilidad o rendimiento bajo ciertas condiciones (ej. `SELECT *` en vistas internas, índice probablemente faltante). |
| LOW      | Mejora recomendada, sin riesgo funcional inmediato (convenciones de nombres, estilo). |
| INFO     | Informativo: contexto insuficiente para concluir, o hallazgo neutral que el usuario debe saber pero no es un problema en sí. |

## Expected output

Para cada sentencia analizada, devolver:

```
### Sentencia N: <resumen de una línea, ej. "DELETE sobre TA_USERS">

- [SEVERIDAD] [Categoría: security|performance|conventions] <descripción del hallazgo>
  Recomendación: <qué hacer en su lugar>
  Confianza: alta|media|baja (baja si depende de contexto no provisto)

(repetir por cada hallazgo)

Si no hay hallazgos: "Sin observaciones bajo las reglas actuales."
```

Al final del análisis completo, si hubo algún check que no se pudo resolver
por falta de contexto, agregar una sección:

```
### Información insuficiente
- <qué dato falta> — <qué check quedó sin poder confirmarse>
```

No agregar hallazgos "de relleno" cuando el SQL está bien. El happy path
(Test 1) debe devolver una lista corta o vacía de hallazgos genuinos.

## Validation

Antes de entregar el resultado, la skill se autochequea:

1. ¿Cada hallazgo tiene una regla identificable en `rules/*.md` que lo
   respalda? Si no, no se reporta (no se inventan reglas nuevas al vuelo;
   si el equipo detecta un caso nuevo válido, se agrega como regla
   explícita a `rules/*.md`, no se improvisa solo para esa respuesta).
2. ¿Hay hallazgos duplicados sobre la misma línea y la misma causa? Si sí,
   se consolidan en uno.
3. ¿La severidad asignada corresponde a la tabla de "Severity levels" y no
   fue elevada/bajada sin justificación escrita en el hallazgo?
4. ¿Se evaluó intención (ver sección de razonamiento) y no solo presencia
   sintáctica de `WHERE`/`LIMIT`?

## Failure handling

- **Input vacío o no es SQL reconocible**: responder que no se detectó SQL
  válido y pedir la sentencia real. No se analiza "a medias" adivinando qué
  quiso decir el usuario.
- **Contexto insuficiente** (no se sabe si hay índice, volumen de la tabla,
  motor de base de datos, etc.): nunca se asume un valor conveniente. Se
  reporta el hallazgo relevante como `INFO` explicando qué dato falta y
  cómo cambiaría la conclusión si se supiera.
- **Sentencia ambigua o truncada**: se señala explícitamente qué parte no
  pudo analizarse y por qué, en vez de completar el análisis sobre una
  interpretación no verificada.
- **Entrada adversarial** (diseñada para parecer segura): se aplica la
  sección "Razonamiento sobre intención"; el cumplimiento superficial de una
  regla nunca es suficiente por sí solo para descartar un hallazgo.

## Adaptación a otro motor

Si mañana hay que soportar otro motor (ej. SQL Server o Oracle), lo que
cambia es acotado y localizado:

- `rules/performance.md`: la regla de "ausencia de LIMIT" debe reconocer
  también `TOP N` (SQL Server) o `FETCH FIRST N ROWS ONLY` / `ROWNUM`
  (Oracle) como equivalentes.
- El resto de las reglas (WHERE inseguro, SELECT *, NULL, tipos de datos,
  índices, convenciones de nombres) son agnósticas al motor y no cambian.
- El procedimiento (`Procedure`), los niveles de severidad y el formato de
  salida no cambian: eso es lo que hace que la skill sea determinista más
  allá del dialecto SQL específico.
