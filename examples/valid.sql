-- Ejemplo válido: SELECT con columnas explícitas, WHERE por clave única,
-- LIMIT razonable.
SELECT id, email, created_at
FROM users
WHERE id = 42;

-- Ejemplo válido: UPDATE acotado por clave primaria.
UPDATE users
SET last_login = NOW()
WHERE id = 42;

-- Ejemplo válido: DELETE acotado, con condición sobre una fila específica.
DELETE FROM sessions
WHERE id = 8831;

-- Ejemplo válido: consulta paginada con LIMIT efectivo.
SELECT id, name, status
FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 50;

-- Ejemplo válido: tipos de datos correctos.
CREATE TABLE invoices (
    id BIGINT PRIMARY KEY,
    amount DECIMAL(12,2) NOT NULL,
    issued_at DATE NOT NULL,
    customer_email VARCHAR(255) NOT NULL
);
