# Skills
Actividad: Ingeniería y Desarrollo de una Skill para  IA

# sql-reviewer-skill

Skill que analiza sentencias/scripts SQL y actúa como revisor técnico,
clasificando hallazgos en CRITICAL / HIGH / MEDIUM / LOW / INFO.

## Estructura

```
sql-reviewer-skill/
├── SKILL.md              # Comportamiento: purpose, cuándo activar/no
│                          # activar, procedimiento paso a paso, niveles
│                          # de severidad, formato de salida, manejo de
│                          # fallos.
├── rules/
│   ├── security.md        # WHERE inseguro, injection, destructivo, S4
│   ├── performance.md      # SELECT *, LIMIT, índices, antipatrones
│   └── conventions.md      # nombres, NULL, tipos de datos
├── examples/
│   ├── valid.sql           # no debe generar hallazgos artificiales
│   ├── invalid.sql         # múltiples violaciones evidentes
│   └── edge-cases.sql      # cumplen la forma, siguen siendo peligrosos
└── tests/
    ├── test-01.md           # happy path
    ├── test-02.md           # error evidente
    ├── test-03.md           # edge case
    ├── test-04.md           # información insuficiente
    └── test-05.md           # adversarial (Red Team del enunciado)
```

## Cómo usarla / probarla

Pegar el contenido de cualquier archivo de `examples/` (o SQL propio) y
pedirle a un modelo con esta skill cargada: "Revisá este SQL". El modelo
debe seguir el `Procedure` de `SKILL.md`, no razonar libremente.

## Antes de la defensa: repaso de las preguntas del enunciado

Esto **no reemplaza entender el repo** — es un punto de partida para que
ambos integrantes puedan explicar cada decisión con sus propias palabras.

**¿Qué diferencia técnica existe entre esta skill y un prompt?**
Un prompt delega la decisión completa al modelo cada vez. Esta skill fija
un procedimiento (`Procedure` en `SKILL.md`), reglas `IF/THEN` con
severidad predefinida (`rules/*.md`), y comportamiento explícito ante
información faltante. Dos ejecuciones distintas deberían llegar al mismo
veredicto sobre la misma sentencia, porque la regla —no el "criterio" del
modelo en ese momento— es la que decide.

**¿Qué ocurre si dos reglas entran en conflicto?**
Ver "Conflicto entre reglas" en `SKILL.md`: gana la severidad más alta y se
documenta la ambigüedad en el output, en vez de promediar o elegir
arbitrariamente.

**¿Dónde está definido el comportamiento que acaba de mostrar?**
Cada hallazgo debe poder señalarse a una regla concreta en
`rules/security.md`, `rules/performance.md` o `rules/conventions.md`. Si no
se puede señalar, es un fallo de `Validation` (punto 1 en `SKILL.md`).

**¿Por qué un hallazgo fue clasificado con esa severidad?**
Por la tabla de "Severity levels" + la regla específica que lo generó. Por
ejemplo, un `DELETE` sin `WHERE` es `CRITICAL` porque S1 lo define así:
riesgo de pérdida irreversible de datos, criterio explícito de la tabla.

**¿Qué entrada podría romper actualmente la skill?**
Ver `tests/test-03.md` y `tests/test-05.md`: las versiones iniciales de las
reglas fallaron ante WHERE/LIMIT que cumplían la forma pero no la función.
Se corrigieron, pero cualquier condición nueva de "cumple la forma, no la
intención" que el equipo no haya anticipado es un vector de ataque
razonable a mencionar (ej.: subconsultas que ocultan una tautología dentro
de un `IN (...)`).

**Si mañana fuera necesario soportar otro motor, ¿qué cambiaría?**
Ver "Adaptación a otro motor" al final de `SKILL.md`: solo la detección de
paginación (`LIMIT` vs `TOP`/`FETCH FIRST`) cambia; el resto del
procedimiento y las reglas son agnósticas al motor.

**¿Qué partes son deterministas y cuáles dependen del razonamiento del modelo?**
Deterministas: el orden del `Procedure`, la tabla de severidad, el formato
de salida, y las condiciones sintácticas explícitas (¿hay WHERE?, ¿hay
LIMIT?, ¿el tipo de columna es X?). Dependen de razonamiento del modelo:
evaluar si una condición de WHERE es "efectivamente una tautología" en
casos no listados explícitamente, y estimar impacto cuando falta contexto
de esquema — ahí la skill guía con criterios pero no puede cubrir cada
sentencia posible con una regla textual exacta.

## Reglas propias del equipo

Agregar acá, y en `rules/conventions.md` (sección "Reglas adicionales del
equipo"), cualquier violación adicional que el equipo decida incorporar,
con el mismo formato IF/THEN.
s