-- Adds Google authentication metadata to existing users.
ALTER TABLE usuario ADD COLUMN google_id TEXT;

CREATE UNIQUE INDEX idx_usuario_google_id
ON usuario(google_id);

ALTER TABLE usuario ADD COLUMN proveedor_auth TEXT NOT NULL DEFAULT 'LOCAL'
    CHECK (proveedor_auth IN ('LOCAL', 'GOOGLE'));

ALTER TABLE usuario ADD COLUMN correo_verificado INTEGER NOT NULL DEFAULT 0
    CHECK (correo_verificado IN (0, 1));

CREATE INDEX idx_usuario_proveedor_auth
ON usuario(proveedor_auth);
