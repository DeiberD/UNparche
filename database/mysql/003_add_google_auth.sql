-- 003_add_google_auth.sql
-- Agrega soporte de inicio de sesion con Google a la tabla usuario.
--
-- Cambios:
--   - contrasena_hash pasa a ser NULLABLE (usuarios de Google no tienen password local)
--   - google_id: identificador unico entregado por Google (claim "sub")
--   - proveedor_auth: 'LOCAL' o 'GOOGLE'
--   - correo_verificado: Google ya verifica el correo, se marca automaticamente
--   - foto_perfil se amplia a VARCHAR(512) por si la URL de la foto de Google es larga

ALTER TABLE usuario
    MODIFY COLUMN contrasena_hash VARCHAR(255) NULL,
    MODIFY COLUMN foto_perfil VARCHAR(512),
    ADD COLUMN google_id VARCHAR(50) NULL AFTER contrasena_hash,
    ADD COLUMN proveedor_auth VARCHAR(20) NOT NULL DEFAULT 'LOCAL' AFTER google_id,
    ADD COLUMN correo_verificado BOOLEAN NOT NULL DEFAULT FALSE AFTER proveedor_auth;

ALTER TABLE usuario
    ADD CONSTRAINT uq_usuario_google_id UNIQUE (google_id);

ALTER TABLE usuario
    ADD CONSTRAINT chk_usuario_proveedor_auth
        CHECK (proveedor_auth IN ('LOCAL', 'GOOGLE')),
    ADD CONSTRAINT chk_usuario_auth_provider
        CHECK (
            (proveedor_auth = 'LOCAL' AND contrasena_hash IS NOT NULL)
            OR
            (proveedor_auth = 'GOOGLE' AND google_id IS NOT NULL)
        );

CREATE INDEX idx_usuario_google_id
ON usuario(google_id);

CREATE INDEX idx_usuario_proveedor_auth
ON usuario(proveedor_auth);