DROP TABLE IF EXISTS anuncio;
DROP TABLE IF EXISTS mensaje_chat;
DROP TABLE IF EXISTS amistad;
DROP TABLE IF EXISTS asistencia;
DROP TABLE IF EXISTS invitacion_grupo;
DROP TABLE IF EXISTS membresia_grupo;
DROP TABLE IF EXISTS evento;
DROP TABLE IF EXISTS grupo;
DROP TABLE IF EXISTS tipo_evento;
DROP TABLE IF EXISTS usuario;

CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    correo_institucional VARCHAR(80) NOT NULL UNIQUE,
    nombre VARCHAR(45) NOT NULL,
    apellido VARCHAR(45) NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    foto_perfil VARCHAR(255),
    carrera VARCHAR(80),
    informacion_personal VARCHAR(255),
    rol VARCHAR(45) NOT NULL DEFAULT 'COMUNITARIO',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_usuario_rol
        CHECK (rol IN ('COMUNITARIO', 'MODERADOR')),
    CONSTRAINT chk_usuario_correo_unal
        CHECK (correo_institucional LIKE '%@unal.edu.co')
);

CREATE TABLE tipo_evento (
    id_tipo_evento INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(45) NOT NULL UNIQUE,
    icono_svg VARCHAR(80)
);

CREATE TABLE grupo (
    id_grupo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(45) NOT NULL,
    descripcion VARCHAR(255),
    categoria VARCHAR(45) NOT NULL,
    es_oficial BOOLEAN NOT NULL DEFAULT FALSE,
    estado_verificacion VARCHAR(45) NOT NULL DEFAULT 'NO_SOLICITADO',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_administrador INT NOT NULL,

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
    id_evento INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    duracion_minutos INT NOT NULL,
    fecha_fin DATETIME NOT NULL,
    fecha_publicacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_eliminacion DATETIME NOT NULL,
    latitud DECIMAL(10,7) NOT NULL,
    longitud DECIMAL(10,7) NOT NULL,
    visibilidad VARCHAR(45) NOT NULL,
    chat_habilitado BOOLEAN NOT NULL DEFAULT TRUE,
    estado VARCHAR(45) NOT NULL DEFAULT 'PROGRAMADO',

    id_organizador INT NOT NULL,
    id_grupo INT NULL,
    id_tipo_evento INT NOT NULL,

    CONSTRAINT chk_evento_duracion
        CHECK (duracion_minutos > 0),
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
    id_membresia INT AUTO_INCREMENT PRIMARY KEY,
    rol_grupo VARCHAR(45) NOT NULL DEFAULT 'MIEMBRO',
    estado VARCHAR(45) NOT NULL DEFAULT 'ACTIVA',
    fecha_union DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    id_usuario INT NOT NULL,
    id_grupo INT NOT NULL,

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
    id_invitacion_grupo INT AUTO_INCREMENT PRIMARY KEY,
    estado VARCHAR(45) NOT NULL DEFAULT 'PENDIENTE',
    fecha_envio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_respuesta DATETIME NULL,

    id_grupo INT NOT NULL,
    id_invitado INT NOT NULL,
    id_invitador INT NOT NULL,

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
    id_asistencia INT AUTO_INCREMENT PRIMARY KEY,
    estado VARCHAR(45) NOT NULL DEFAULT 'CONFIRMADA',
    notificaciones_activas BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_confirmacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    id_usuario INT NOT NULL,
    id_evento INT NOT NULL,

    CONSTRAINT uq_asistencia_usuario_evento
        UNIQUE (id_usuario, id_evento),
    CONSTRAINT chk_asistencia_estado
        CHECK (estado IN ('CONFIRMADA', 'CANCELADA')),
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
    id_amistad INT AUTO_INCREMENT PRIMARY KEY,
    estado VARCHAR(45) NOT NULL DEFAULT 'PENDIENTE',
    fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_respuesta DATETIME NULL,

    id_solicitante INT NOT NULL,
    id_receptor INT NOT NULL,

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
    id_mensaje INT AUTO_INCREMENT PRIMARY KEY,
    contenido VARCHAR(300) NOT NULL,
    fecha_envio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    id_evento INT NOT NULL,
    id_usuario INT NOT NULL,

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
    id_anuncio INT AUTO_INCREMENT PRIMARY KEY,
    contenido VARCHAR(300) NOT NULL,
    fecha_publicacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    id_autor INT NOT NULL,
    id_evento INT NOT NULL,

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
