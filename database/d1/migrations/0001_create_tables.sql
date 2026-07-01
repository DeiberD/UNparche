CREATE TABLE usuario (
    id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
    correo_institucional TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    apellido TEXT NOT NULL,
    contrasena_hash TEXT NOT NULL,
    foto_perfil TEXT,
    carrera TEXT,
    informacion_personal TEXT,
    rol TEXT NOT NULL DEFAULT 'COMUNITARIO',
    activo INTEGER NOT NULL DEFAULT 1,
    fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_usuario_rol
        CHECK (rol IN ('COMUNITARIO', 'MODERADOR')),

    CONSTRAINT chk_usuario_activo
        CHECK (activo IN (0, 1)),

    CONSTRAINT chk_usuario_correo_unal
        CHECK (correo_institucional LIKE '%@unal.edu.co')
);

CREATE TABLE tipo_evento (
    id_tipo_evento INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL UNIQUE,
    icono_svg TEXT
);

CREATE TABLE grupo (
    id_grupo INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    categoria TEXT NOT NULL,
    es_oficial INTEGER NOT NULL DEFAULT 0,
    estado_verificacion TEXT NOT NULL DEFAULT 'NO_SOLICITADO',
    fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_administrador INTEGER NOT NULL,

    CONSTRAINT chk_grupo_es_oficial
        CHECK (es_oficial IN (0, 1)),

    CONSTRAINT chk_grupo_categoria
        CHECK (categoria IN ('ACADEMICO', 'CULTURAL', 'SOCIAL', 'DEPORTIVO', 'OTRO')),

    CONSTRAINT chk_grupo_estado_verificacion
        CHECK (estado_verificacion IN ('NO_SOLICITADO', 'PENDIENTE', 'APROBADO', 'RECHAZADO', 'CANCELADO')),

    CONSTRAINT fk_grupo_administrador
        FOREIGN KEY (id_administrador)
        REFERENCES usuario(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE evento (
    id_evento INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    fecha_inicio TEXT NOT NULL,
    duracion_minutos INTEGER NOT NULL,
    fecha_fin TEXT NOT NULL,
    fecha_publicacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_eliminacion TEXT NULL,
    latitud REAL NOT NULL,
    longitud REAL NOT NULL,
    visibilidad TEXT NOT NULL,
    chat_habilitado INTEGER NOT NULL DEFAULT 1,
    estado TEXT NOT NULL DEFAULT 'PROGRAMADO',

    id_organizador INTEGER NOT NULL,
    id_grupo INTEGER NULL,
    id_tipo_evento INTEGER NOT NULL,

    CONSTRAINT chk_evento_duracion
        CHECK (duracion_minutos > 0),

    CONSTRAINT chk_evento_latitud
        CHECK (latitud >= -90 AND latitud <= 90),

    CONSTRAINT chk_evento_longitud
        CHECK (longitud >= -180 AND longitud <= 180),

    CONSTRAINT chk_evento_chat_habilitado
        CHECK (chat_habilitado IN (0, 1)),

    CONSTRAINT chk_evento_visibilidad
        CHECK (visibilidad IN ('PUBLICA', 'SOLO_GRUPO', 'SOLO_AMIGOS')),

    CONSTRAINT chk_evento_estado
        CHECK (estado IN ('PROGRAMADO', 'EN_CURSO', 'FINALIZADO', 'CANCELADO')),

    CONSTRAINT fk_evento_organizador
        FOREIGN KEY (id_organizador)
        REFERENCES usuario(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_evento_grupo
        FOREIGN KEY (id_grupo)
        REFERENCES grupo(id_grupo)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_evento_tipo_evento
        FOREIGN KEY (id_tipo_evento)
        REFERENCES tipo_evento(id_tipo_evento)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE membresia_grupo (
    id_membresia INTEGER PRIMARY KEY AUTOINCREMENT,
    rol_grupo TEXT NOT NULL DEFAULT 'MIEMBRO',
    estado TEXT NOT NULL DEFAULT 'ACTIVA',
    fecha_union TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    id_usuario INTEGER NOT NULL,
    id_grupo INTEGER NOT NULL,

    CONSTRAINT uq_membresia_usuario_grupo
        UNIQUE (id_usuario, id_grupo),

    CONSTRAINT chk_membresia_rol
        CHECK (rol_grupo IN ('ADMINISTRADOR', 'MIEMBRO')),

    CONSTRAINT chk_membresia_estado
        CHECK (estado IN ('ACTIVA', 'INACTIVA')),

    CONSTRAINT fk_membresia_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_membresia_grupo
        FOREIGN KEY (id_grupo)
        REFERENCES grupo(id_grupo)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE invitacion_grupo (
    id_invitacion_grupo INTEGER PRIMARY KEY AUTOINCREMENT,
    estado TEXT NOT NULL DEFAULT 'PENDIENTE',
    fecha_envio TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_respuesta TEXT NULL,

    id_grupo INTEGER NOT NULL,
    id_invitado INTEGER NOT NULL,
    id_invitador INTEGER NOT NULL,

    CONSTRAINT chk_invitacion_grupo_estado
        CHECK (estado IN ('PENDIENTE', 'ACEPTADA', 'RECHAZADA')),

    CONSTRAINT fk_invitacion_grupo
        FOREIGN KEY (id_grupo)
        REFERENCES grupo(id_grupo)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_invitacion_invitado
        FOREIGN KEY (id_invitado)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_invitacion_invitador
        FOREIGN KEY (id_invitador)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE asistencia (
    id_asistencia INTEGER PRIMARY KEY AUTOINCREMENT,
    estado TEXT NOT NULL DEFAULT 'CONFIRMADA',
    notificaciones_activas INTEGER NOT NULL DEFAULT 0,
    fecha_confirmacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    id_usuario INTEGER NOT NULL,
    id_evento INTEGER NOT NULL,

    CONSTRAINT uq_asistencia_usuario_evento
        UNIQUE (id_usuario, id_evento),

    CONSTRAINT chk_asistencia_estado
        CHECK (estado IN ('CONFIRMADA', 'CANCELADA')),

    CONSTRAINT chk_asistencia_notificaciones
        CHECK (notificaciones_activas IN (0, 1)),

    CONSTRAINT fk_asistencia_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_asistencia_evento
        FOREIGN KEY (id_evento)
        REFERENCES evento(id_evento)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE amistad (
    id_amistad INTEGER PRIMARY KEY AUTOINCREMENT,
    estado TEXT NOT NULL DEFAULT 'PENDIENTE',
    fecha_solicitud TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_respuesta TEXT NULL,

    id_solicitante INTEGER NOT NULL,
    id_receptor INTEGER NOT NULL,

    CONSTRAINT uq_amistad
        UNIQUE (id_solicitante, id_receptor),

    CONSTRAINT chk_amistad_estado
        CHECK (estado IN ('PENDIENTE', 'ACEPTADA', 'RECHAZADA', 'ELIMINADA')),

    CONSTRAINT chk_amistad_distintos_usuarios
        CHECK (id_solicitante <> id_receptor),

    CONSTRAINT fk_amistad_solicitante
        FOREIGN KEY (id_solicitante)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_amistad_receptor
        FOREIGN KEY (id_receptor)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE mensaje_chat (
    id_mensaje INTEGER PRIMARY KEY AUTOINCREMENT,
    contenido TEXT NOT NULL,
    fecha_envio TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    id_evento INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,

    CONSTRAINT fk_mensaje_evento
        FOREIGN KEY (id_evento)
        REFERENCES evento(id_evento)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_mensaje_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE anuncio (
    id_anuncio INTEGER PRIMARY KEY AUTOINCREMENT,
    contenido TEXT NOT NULL,
    fecha_publicacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    id_autor INTEGER NOT NULL,
    id_evento INTEGER NOT NULL,

    CONSTRAINT fk_anuncio_autor
        FOREIGN KEY (id_autor)
        REFERENCES usuario(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_anuncio_evento
        FOREIGN KEY (id_evento)
        REFERENCES evento(id_evento)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);