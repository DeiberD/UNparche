-- Migración 0006: soporte de verificación de correo y códigos de un solo uso.
--
-- Añade correo_verificado a usuario y crea la tabla codigo_verificacion
-- para los flujos de: verificación al registrarse y reset de contraseña.
--
-- Notas:
-- • correo_verificado DEFAULT 0 deja a todos los usuarios existentes sin verificar.
--   Ajusta manualmente si ya tienes usuarios de producción que deban quedar verificados.
-- • Los usuarios creados vía /auth/google se insertan con correo_verificado = 1
--   directamente en el endpoint (Google ya verificó el correo).

ALTER TABLE usuario ADD COLUMN correo_verificado INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS codigo_verificacion (
    id_codigo        INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario       INTEGER NOT NULL,
    codigo           TEXT    NOT NULL,
    tipo             TEXT    NOT NULL CHECK(tipo IN ('registro', 'reset_password')),
    expira_en        TEXT    NOT NULL,   -- ISO 8601 UTC
    usado            INTEGER NOT NULL DEFAULT 0,
    fecha_creacion   TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_codigo_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_codigo_usuario_tipo ON codigo_verificacion(id_usuario, tipo);
