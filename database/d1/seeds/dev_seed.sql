INSERT INTO usuario (
    id_usuario,
    correo_institucional,
    nombre,
    apellido,
    contrasena_hash,
    foto_perfil,
    carrera,
    informacion_personal,
    rol,
    activo
) VALUES
    (1, 'daniel@unal.edu.co', 'Daniel', 'Lopez', 'hash_demo_1', NULL, 'Ingeniería de Sistemas', 'Usuario de prueba', 'COMUNITARIO', 1),
    (2, 'juan@unal.edu.co', 'Juan', 'Perez', 'hash_demo_2', NULL, 'Estadística', 'Usuario de prueba', 'COMUNITARIO', 1);

INSERT INTO grupo (
    id_grupo,
    nombre,
    descripcion,
    categoria,
    es_oficial,
    estado_verificacion,
    id_administrador
) VALUES
    (1, 'Ajedrez UN', 'Grupo para jugar ajedrez en la universidad', 'SOCIAL', 0, 'NO_SOLICITADO', 1);

INSERT INTO membresia_grupo (
    id_membresia,
    rol_grupo,
    estado,
    id_usuario,
    id_grupo
) VALUES
    (1, 'ADMINISTRADOR', 'ACTIVA', 1, 1),
    (2, 'MIEMBRO', 'ACTIVA', 2, 1);

INSERT INTO evento (
    id_evento,
    titulo,
    descripcion,
    fecha_inicio,
    duracion_minutos,
    fecha_fin,
    fecha_eliminacion,
    latitud,
    longitud,
    visibilidad,
    chat_habilitado,
    estado,
    id_organizador,
    id_grupo,
    id_tipo_evento
) VALUES
    (
        1,
        'Torneo de ajedrez',
        'Partidas amistosas en la universidad',
        '2026-07-10 14:00:00',
        120,
        '2026-07-10 16:00:00',
        NULL,
        4.6370,
        -74.0830,
        'PUBLICA',
        1,
        'PROGRAMADO',
        1,
        1,
        4
    );

INSERT INTO asistencia (
    id_asistencia,
    estado,
    notificaciones_activas,
    id_usuario,
    id_evento
) VALUES
    (1, 'CONFIRMADA', 1, 2, 1);

INSERT INTO mensaje_chat (
    id_mensaje,
    contenido,
    id_evento,
    id_usuario
) VALUES
    (1, 'Hola, nos vemos en el torneo.', 1, 2);

INSERT INTO anuncio (
    id_anuncio,
    contenido,
    id_autor,
    id_evento
) VALUES
    (1, 'Recuerden llegar 10 minutos antes.', 1, 1);
