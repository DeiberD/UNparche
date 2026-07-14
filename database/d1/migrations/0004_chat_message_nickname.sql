-- Migracion 0004: soporte de chat sin autenticacion de usuarios.
--
-- Requiere haberse aplicado despues de 0001_create_tables.sql (crea
-- mensaje_chat), 0002_seed_catalogs.sql y 0003_create_indexes.sql (crea
-- idx_mensaje_evento_fecha e idx_mensaje_usuario sobre mensaje_chat).
--
-- El chat en tiempo real (server C++) identifica a los participantes por
-- un nickname libre enviado por el cliente Flutter al conectarse (no hay
-- login todavia). Por eso mensaje_chat pasa a guardar el nickname como
-- texto y la FK a usuario se vuelve opcional, en vez de obligatoria.
--
-- SQLite no soporta ALTER COLUMN ni DROP CONSTRAINT directamente, asi que
-- se reconstruye la tabla (patron estandar de migracion en SQLite). Esto
-- borra automaticamente los indices de 0003 sobre mensaje_chat junto con
-- la tabla vieja, por eso se recrean al final con los mismos nombres.

PRAGMA foreign_keys = OFF;

CREATE TABLE mensaje_chat_new (
    id_mensaje INTEGER PRIMARY KEY AUTOINCREMENT,
    contenido TEXT NOT NULL,
    nickname TEXT NOT NULL,
    fecha_envio TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    id_evento INTEGER NOT NULL,
    id_usuario INTEGER NULL,

    CONSTRAINT fk_mensaje_evento
        FOREIGN KEY (id_evento)
        REFERENCES evento(id_evento)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_mensaje_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

INSERT INTO mensaje_chat_new (id_mensaje, contenido, nickname, fecha_envio, id_evento, id_usuario)
SELECT
    m.id_mensaje,
    m.contenido,
    COALESCE(u.nombre || ' ' || u.apellido, 'Usuario'),
    m.fecha_envio,
    m.id_evento,
    m.id_usuario
FROM mensaje_chat m
LEFT JOIN usuario u ON u.id_usuario = m.id_usuario;

DROP TABLE mensaje_chat;
ALTER TABLE mensaje_chat_new RENAME TO mensaje_chat;

-- Recrea los indices que existian sobre mensaje_chat antes del DROP TABLE
-- (definidos originalmente en 0003_create_indexes.sql), con los mismos
-- nombres para no generar duplicados ni referencias rotas.
CREATE INDEX idx_mensaje_evento_fecha ON mensaje_chat(id_evento, fecha_envio);
CREATE INDEX idx_mensaje_usuario ON mensaje_chat(id_usuario);

PRAGMA foreign_keys = ON;