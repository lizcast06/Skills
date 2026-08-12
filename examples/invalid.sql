-- Ejemplo inválido: múltiples violaciones claras y evidentes.

-- SELECT * sin límite
SELECT * FROM users;

-- UPDATE sin WHERE (afecta toda la tabla)
UPDATE users SET status = 'inactive';

-- DELETE sin WHERE (destructivo, irreversible)
DELETE FROM sessions;

-- Concatenación directa de input en el SQL (SQL injection)
-- (pseudo-representación de cómo llegaría construido desde código)
-- query = "SELECT * FROM users WHERE email = '" + userEmail + "'";

-- Comparación incorrecta con NULL
SELECT * FROM orders WHERE cancelled_reason = NULL;

-- Tipo de dato incorrecto para monto
CREATE TABLE payments (
    id INT,
    amount FLOAT,
    created TEXT
);

-- Nombre no descriptivo
SELECT * FROM t1 WHERE x = 1;
