-- Casos límite: cumplen la forma superficial de una regla, pero siguen
-- siendo peligrosos. Estos son los tres ejemplos de la fase Red Team del
-- enunciado.

-- (1) Tiene WHERE, pero es una tautología: afecta a todas las filas igual
-- que si no tuviera WHERE.
DELETE FROM TA_USERS WHERE 1 = 1;

-- (2) Tiene LIMIT, pero el valor no acota nada realista: equivale a "sin
-- límite" en la práctica.
SELECT * FROM TA_USERS LIMIT 1000000000;

-- (3) Tiene WHERE, pero LIKE '%' matchea cualquier valor no nulo: además
-- escala privilegios (asigna rol ADMIN) de forma masiva.
UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCEMAIL LIKE '%';

-- (4) Edge case adicional: WHERE que filtra por una columna sin garantía
-- de unicidad, en apariencia razonable pero potencialmente afecta miles
-- de filas sin que el autor lo note.
UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCDEPARTMENT = 'IT';

-- (5) Edge case: función sobre columna indexada, "parece" un WHERE normal
-- pero impide el uso de índice.
SELECT * FROM orders WHERE YEAR(created_at) = 2024;
