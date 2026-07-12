-- 004_add_google_auth.sql
-- Agrega soporte de inicio de sesion con Google a la tabla usuario.
--
-- Cambios:
--   - google_id: identificador unico entregado por Google (claim "sub")
--   - proveedor_auth: 'LOCAL' o 'GOOGLE'
--   - correo_verificado: Google ya verifica el correo, se marca automaticamente
--   - foto_perfil se conserva (ya existia) y se usa para guardar la URL de la foto de Google
--
-- NOTA sobre contrasena_hash:
--   SQLite/D1 no permiten quitar un NOT NULL con ALTER TABLE sin reconstruir
--   la tabla, y reconstruirla es riesgoso aqui por las FK. Por eso contrasena_hash
--   sigue siendo NOT NULL: para usuarios que entran solo con Google, la
--   aplicacion debe guardar el valor 'OAUTH:GOOGLE' (sentinela, no un hash real)
--   y el backend NUNCA debe intentar autenticar con contrasena si proveedor_auth = 'GOOGLE'.
--   Esa regla se valida en la capa de aplicacion, no en la base de datos.

ALTER TABLE usuario ADD COLUMN google_id TEXT;

-- UNIQUE via indice (ADD COLUMN no permite UNIQUE directamente en SQLite).
-- SQLite permite multiples NULL en un indice unico, asi que no afecta a los
-- usuarios LOCAL que no tienen google_id.
CREATE UNIQUE INDEX idx_usuario_google_id
ON usuario(google_id);

ALTER TABLE usuario ADD COLUMN proveedor_auth TEXT NOT NULL DEFAULT 'LOCAL'
    CHECK (proveedor_auth IN ('LOCAL', 'GOOGLE'));

ALTER TABLE usuario ADD COLUMN correo_verificado INTEGER NOT NULL DEFAULT 0
    CHECK (correo_verificado IN (0, 1));

CREATE INDEX idx_usuario_proveedor_auth
ON usuario(proveedor_auth);