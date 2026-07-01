CREATE INDEX idx_usuario_rol
ON usuario(rol);

CREATE INDEX idx_usuario_activo
ON usuario(activo);

CREATE INDEX idx_grupo_administrador
ON grupo(id_administrador);

CREATE INDEX idx_grupo_categoria
ON grupo(categoria);

CREATE INDEX idx_grupo_estado_verificacion
ON grupo(estado_verificacion);

CREATE INDEX idx_evento_organizador
ON evento(id_organizador);

CREATE INDEX idx_evento_grupo
ON evento(id_grupo);

CREATE INDEX idx_evento_tipo_evento
ON evento(id_tipo_evento);

CREATE INDEX idx_evento_fecha_inicio
ON evento(fecha_inicio);

CREATE INDEX idx_evento_estado
ON evento(estado);

CREATE INDEX idx_evento_visibilidad
ON evento(visibilidad);

CREATE INDEX idx_membresia_grupo
ON membresia_grupo(id_grupo);

CREATE INDEX idx_membresia_usuario_estado
ON membresia_grupo(id_usuario, estado);

CREATE INDEX idx_invitacion_grupo
ON invitacion_grupo(id_grupo);

CREATE INDEX idx_invitacion_invitado_estado
ON invitacion_grupo(id_invitado, estado);

CREATE INDEX idx_invitacion_invitador
ON invitacion_grupo(id_invitador);

CREATE INDEX idx_asistencia_evento
ON asistencia(id_evento);

CREATE INDEX idx_asistencia_usuario_estado
ON asistencia(id_usuario, estado);

CREATE INDEX idx_amistad_receptor_estado
ON amistad(id_receptor, estado);

CREATE INDEX idx_amistad_solicitante_estado
ON amistad(id_solicitante, estado);

CREATE INDEX idx_mensaje_evento_fecha
ON mensaje_chat(id_evento, fecha_envio);

CREATE INDEX idx_mensaje_usuario
ON mensaje_chat(id_usuario);

CREATE INDEX idx_anuncio_evento_fecha
ON anuncio(id_evento, fecha_publicacion);

CREATE INDEX idx_anuncio_autor
ON anuncio(id_autor);
