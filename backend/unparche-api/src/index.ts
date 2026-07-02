type AppEnv = Env & {
	unparche_db: D1Database;
};

type CrearEventoBody = {
	titulo?: string;
	descripcion?: string;
	fecha_inicio?: string;
	duracion_minutos?: number;
	latitud?: number;
	longitud?: number;
	visibilidad?: "PUBLICA" | "SOLO_GRUPO" | "SOLO_AMIGOS";
	id_organizador?: number;
	id_tipo_evento?: number;
	id_grupo?: number | null;
	chat_habilitado?: boolean;
};

type CrearAsistenciaBody = {
	id_usuario?: number;
	estado?: "CONFIRMADA" | "CANCELADA";
};

const corsHeaders = {
	"Access-Control-Allow-Origin": "*",
	"Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
	"Access-Control-Allow-Headers": "Content-Type, Authorization",
};

const json = (body: unknown, init: ResponseInit = {}) =>
	Response.json(body, {
		...init,
		headers: {
			...corsHeaders,
			...init.headers,
		},
	});

const buildFechaFin = (fechaInicio: string, duracionMinutos: number) => {
	const inicio = new Date(fechaInicio);

	if (Number.isNaN(inicio.getTime())) {
		return null;
	}

	return new Date(inicio.getTime() + duracionMinutos * 60_000).toISOString();
};

const toInteger = (value: unknown) => {
	if (typeof value === "number" && Number.isInteger(value)) {
		return value;
	}

	return null;
};

const toNumber = (value: unknown) => {
	if (typeof value === "number" && Number.isFinite(value)) {
		return value;
	}

	return null;
};

const toBoolean = (value: unknown, defaultValue: boolean) => {
	if (value === undefined) {
		return defaultValue;
	}

	if (typeof value === "boolean") {
		return value;
	}

	return null;
};

const selectEventoById = async (db: D1Database, idEvento: number) =>
	db
		.prepare(
			`SELECT
				id_evento,
				titulo,
				descripcion,
				fecha_inicio,
				duracion_minutos,
				fecha_fin,
				fecha_publicacion,
				latitud,
				longitud,
				visibilidad,
				chat_habilitado,
				estado,
				id_organizador,
				id_grupo,
				id_tipo_evento
			 FROM evento
			 WHERE id_evento = ?`
		)
		.bind(idEvento)
		.first();

export default {
	async fetch(request, env): Promise<Response> {
		const url = new URL(request.url);

		if (request.method === "OPTIONS") {
			return new Response(null, { status: 204, headers: corsHeaders });
		}

		if (request.method === "GET" && url.pathname === "/") {
			return json({ ok: true, message: "UNparche API" });
		}


		// GET tipos-evento
		if (request.method === "GET" && url.pathname === "/tipos-evento") {
			const tiposEvento = await env.unparche_db
				.prepare(
					`SELECT
						id_tipo_evento,
						nombre,
						icono_svg
					FROM tipo_evento
					ORDER BY id_tipo_evento ASC`
				)
				.all();

			return json({ ok: true, tipos_evento: tiposEvento.results });
		}

		// GET grupos
		if (request.method === "GET" && url.pathname === "/grupos") {
			const grupos = await env.unparche_db
				.prepare(
					`SELECT
						id_grupo,
						nombre,
						descripcion,
						categoria,
						es_oficial,
						estado_verificacion,
						fecha_creacion,
						id_administrador
					FROM grupo
					ORDER BY fecha_creacion DESC`
				)
				.all();

			return json({ ok: true, grupos: grupos.results });
		}
		
		// GET usuarios/id
		const usuarioMatch = url.pathname.match(/^\/usuarios\/(\d+)$/);

		if (request.method === "GET" && usuarioMatch) {
			const idUsuario = Number(usuarioMatch[1]);

			const usuario = await env.unparche_db
				.prepare(
					`SELECT
						id_usuario,
						correo_institucional,
						nombre,
						apellido,
						carrera,
						informacion_personal,
						rol,
						fecha_creacion
					FROM usuario
					WHERE id_usuario = ?`
				)
				.bind(idUsuario)
				.first();

			if (!usuario) {
				return json({ ok: false, error: "Usuario no encontrado." }, { status: 404 });
			}

			return json({ ok: true, usuario });
		}
		
		// GET eventos relacionados con un usuario (usuarios/:id/eventos)
		const eventosUsuarioMatch = url.pathname.match(/^\/usuarios\/(\d+)\/eventos$/);

		if (request.method === "GET" && eventosUsuarioMatch) {
			const idUsuario = Number(eventosUsuarioMatch[1]);

			const usuario = await env.unparche_db
				.prepare(
					`SELECT
						id_usuario
					FROM usuario
					WHERE id_usuario = ?`
				)
				.bind(idUsuario)
				.first();

			if (!usuario) {
				return json({ ok: false, error: "Usuario no encontrado." }, { status: 404 });
			}

			const eventosOrganizados = await env.unparche_db
				.prepare(
					`SELECT
						e.id_evento,
						e.titulo,
						e.descripcion,
						e.fecha_inicio,
						e.duracion_minutos,
						e.fecha_fin,
						e.fecha_publicacion,
						e.latitud,
						e.longitud,
						e.visibilidad,
						e.chat_habilitado,
						e.estado,
						e.id_organizador,
						e.id_grupo,
						g.nombre AS grupo_nombre,
						e.id_tipo_evento,
						t.nombre AS tipo_evento_nombre,
						t.icono_svg AS tipo_evento_icono
					FROM evento e
					JOIN tipo_evento t ON t.id_tipo_evento = e.id_tipo_evento
					LEFT JOIN grupo g ON g.id_grupo = e.id_grupo
					WHERE e.id_organizador = ?
					AND e.fecha_eliminacion IS NULL
					ORDER BY e.fecha_inicio DESC`
				)
				.bind(idUsuario)
				.all();

			const eventosAsistencia = await env.unparche_db
				.prepare(
					`SELECT
						e.id_evento,
						e.titulo,
						e.descripcion,
						e.fecha_inicio,
						e.duracion_minutos,
						e.fecha_fin,
						e.fecha_publicacion,
						e.latitud,
						e.longitud,
						e.visibilidad,
						e.chat_habilitado,
						e.estado,
						e.id_organizador,
						u.nombre || ' ' || u.apellido AS organizador_nombre,
						e.id_grupo,
						g.nombre AS grupo_nombre,
						e.id_tipo_evento,
						t.nombre AS tipo_evento_nombre,
						t.icono_svg AS tipo_evento_icono,
						a.estado AS estado_asistencia,
						a.fecha_confirmacion
					FROM asistencia a
					JOIN evento e ON e.id_evento = a.id_evento
					JOIN usuario u ON u.id_usuario = e.id_organizador
					JOIN tipo_evento t ON t.id_tipo_evento = e.id_tipo_evento
					LEFT JOIN grupo g ON g.id_grupo = e.id_grupo
					WHERE a.id_usuario = ?
					AND a.estado = 'CONFIRMADA'
					AND e.fecha_eliminacion IS NULL
					ORDER BY e.fecha_inicio DESC`
				)
				.bind(idUsuario)
				.all();

			return json({
				ok: true,
				id_usuario: idUsuario,
				eventos_organizados: eventosOrganizados.results,
				eventos_asistencia: eventosAsistencia.results,
			});
		}


		// GET eventos/id
		const eventoMatch = url.pathname.match(/^\/eventos\/(\d+)$/);

		if (request.method === "GET" && eventoMatch) {
			const idEvento = Number(eventoMatch[1]);

			const evento = await env.unparche_db
				.prepare(
					`SELECT
						e.id_evento,
						e.titulo,
						e.descripcion,
						e.fecha_inicio,
						e.duracion_minutos,
						e.fecha_fin,
						e.fecha_publicacion,
						e.latitud,
						e.longitud,
						e.visibilidad,
						e.chat_habilitado,
						e.estado,
						e.id_organizador,
						u.nombre || ' ' || u.apellido AS organizador_nombre,
						e.id_grupo,
						g.nombre AS grupo_nombre,
						e.id_tipo_evento,
						t.nombre AS tipo_evento_nombre,
						t.icono_svg AS tipo_evento_icono
					FROM evento e
					JOIN usuario u ON u.id_usuario = e.id_organizador
					JOIN tipo_evento t ON t.id_tipo_evento = e.id_tipo_evento
					LEFT JOIN grupo g ON g.id_grupo = e.id_grupo
					WHERE e.id_evento = ?
					AND e.fecha_eliminacion IS NULL`
				)
				.bind(idEvento)
				.first();

			if (!evento) {
				return json({ ok: false, error: "Evento no encontrado." }, { status: 404 });
			}

			return json({ ok: true, evento });
		}

		// POST eventos/id/asistencias (asistencia de un usuario a un evento)
		const asistenciaEventoMatch = url.pathname.match(/^\/eventos\/(\d+)\/asistencias$/);

		if (request.method === "POST" && asistenciaEventoMatch) {
			const idEvento = Number(asistenciaEventoMatch[1]);

			let body: CrearAsistenciaBody;

			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			const idUsuario = toInteger(body.id_usuario);
			const estado = body.estado ?? "CONFIRMADA";

			if (idUsuario === null) {
				return json({ ok: false, error: "id_usuario es obligatorio y debe ser entero." }, { status: 400 });
			}

			if (!["CONFIRMADA", "CANCELADA"].includes(estado)) {
				return json(
					{ ok: false, error: "estado debe ser CONFIRMADA o CANCELADA." },
					{ status: 400 }
				);
			}

			try {
				await env.unparche_db
					.prepare(
						`INSERT INTO asistencia (
							id_usuario,
							id_evento,
							estado
						) VALUES (?, ?, ?)
						ON CONFLICT(id_usuario, id_evento)
						DO UPDATE SET estado = excluded.estado`
					)
					.bind(idUsuario, idEvento, estado)
					.run();

				const asistencia = await env.unparche_db
					.prepare(
						`SELECT
							a.id_asistencia,
							a.id_usuario,
							u.nombre || ' ' || u.apellido AS usuario_nombre,
							a.id_evento,
							e.titulo AS evento_titulo,
							a.estado,
							a.notificaciones_activas,
							a.fecha_confirmacion
						FROM asistencia a
						JOIN usuario u ON u.id_usuario = a.id_usuario
						JOIN evento e ON e.id_evento = a.id_evento
						WHERE a.id_usuario = ?
						AND a.id_evento = ?`
					)
					.bind(idUsuario, idEvento)
					.first();

				return json(
					{
						ok: true,
						message: "Asistencia registrada correctamente.",
						asistencia,
					},
					{ status: 201 }
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				const lowerMessage = message.toLowerCase();

				if (lowerMessage.includes("foreign key constraint failed")) {
					return json(
						{ ok: false, error: "El evento o el usuario no existe." },
						{ status: 400 }
					);
				}

				if (
					lowerMessage.includes("check constraint failed") ||
					lowerMessage.includes("not null constraint failed") ||
					lowerMessage.includes("unique constraint failed")
				) {
					return json(
						{ ok: false, error: "Los datos enviados no cumplen las restricciones de la base de datos." },
						{ status: 400 }
					);
				}

				return json(
					{ ok: false, error: "No se pudo registrar la asistencia." },
					{ status: 500 }
				);
			}
		}

		// DELETE asistencia (/eventos/:id/asistencias/:id_usuario)
		const cancelarAsistenciaMatch = url.pathname.match(/^\/eventos\/(\d+)\/asistencias\/(\d+)$/);

		if (request.method === "DELETE" && cancelarAsistenciaMatch) {
			const idEvento = Number(cancelarAsistenciaMatch[1]);
			const idUsuario = Number(cancelarAsistenciaMatch[2]);

			const asistenciaExistente = await env.unparche_db
				.prepare(
					`SELECT
						id_asistencia,
						id_usuario,
						id_evento,
						estado
					FROM asistencia
					WHERE id_usuario = ?
					AND id_evento = ?`
				)
				.bind(idUsuario, idEvento)
				.first();

			if (!asistenciaExistente) {
				return json({ ok: false, error: "Asistencia no encontrada." }, { status: 404 });
			}

			await env.unparche_db
				.prepare(
					`UPDATE asistencia
					SET estado = 'CANCELADA'
					WHERE id_usuario = ?
					AND id_evento = ?`
				)
				.bind(idUsuario, idEvento)
				.run();

			const asistencia = await env.unparche_db
				.prepare(
					`SELECT
						a.id_asistencia,
						a.id_usuario,
						u.nombre || ' ' || u.apellido AS usuario_nombre,
						a.id_evento,
						e.titulo AS evento_titulo,
						a.estado,
						a.notificaciones_activas,
						a.fecha_confirmacion
					FROM asistencia a
					JOIN usuario u ON u.id_usuario = a.id_usuario
					JOIN evento e ON e.id_evento = a.id_evento
					WHERE a.id_usuario = ?
					AND a.id_evento = ?`
				)
				.bind(idUsuario, idEvento)
				.first();

			return json({
				ok: true,
				message: "Asistencia cancelada correctamente.",
				asistencia,
			});
		}
	

		// GET eventos
		if (request.method === "GET" && url.pathname === "/eventos") {
			const eventos = await env.unparche_db
				.prepare(
					`SELECT
						id_evento,
						titulo,
						descripcion,
						fecha_inicio,
						duracion_minutos,
						fecha_fin,
						fecha_publicacion,
						latitud,
						longitud,
						visibilidad,
						chat_habilitado,
						estado,
						id_organizador,
						id_grupo,
						id_tipo_evento
					 FROM evento
					 ORDER BY fecha_inicio DESC`
				)
				.all();

			return json({ ok: true, eventos: eventos.results });
		}
		

		// POST eventos
		if (request.method === "POST" && url.pathname === "/eventos") {
			let body: CrearEventoBody;

			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			const titulo = typeof body.titulo === "string" ? body.titulo.trim() : "";
			const descripcion = typeof body.descripcion === "string" ? body.descripcion.trim() : "";
			const fechaInicio = typeof body.fecha_inicio === "string" ? body.fecha_inicio.trim() : "";
			const duracionMinutos = toInteger(body.duracion_minutos);
			const latitud = toNumber(body.latitud);
			const longitud = toNumber(body.longitud);
			const idOrganizador = toInteger(body.id_organizador);
			const idTipoEvento = toInteger(body.id_tipo_evento);
			const idGrupo = body.id_grupo === null || body.id_grupo === undefined ? null : toInteger(body.id_grupo);
			const visibilidad = body.visibilidad;
			const chatHabilitado = toBoolean(body.chat_habilitado, true);
			const fechaFin = buildFechaFin(fechaInicio, duracionMinutos ?? 0);

			if (
				!titulo ||
				!descripcion ||
				!fechaInicio ||
				duracionMinutos === null ||
				duracionMinutos <= 0 ||
				latitud === null ||
				longitud === null ||
				idOrganizador === null ||
				idTipoEvento === null ||
				(idGrupo === null && body.id_grupo !== null && body.id_grupo !== undefined) ||
				chatHabilitado === null
			) {
				return json(
					{
						ok: false,
						error: "Faltan campos obligatorios o tienen un formato invalido.",
					},
					{ status: 400 }
				);
			}

			if (fechaFin === null) {
				return json({ ok: false, error: "fecha_inicio debe ser una fecha ISO valida." }, { status: 400 });
			}

			if (!visibilidad || !["PUBLICA", "SOLO_GRUPO", "SOLO_AMIGOS"].includes(visibilidad)) {
				return json({ ok: false, error: "visibilidad debe ser PUBLICA, SOLO_GRUPO o SOLO_AMIGOS." }, { status: 400 });
			}

			if (latitud < -90 || latitud > 90) {
				return json({ ok: false, error: "latitud debe estar entre -90 y 90." }, { status: 400 });
			}

			if (longitud < -180 || longitud > 180) {
				return json({ ok: false, error: "longitud debe estar entre -180 y 180." }, { status: 400 });
			}

			try {
				const result = await env.unparche_db
					.prepare(
						`INSERT INTO evento (
							titulo,
							descripcion,
							fecha_inicio,
							duracion_minutos,
							fecha_fin,
							latitud,
							longitud,
							visibilidad,
							chat_habilitado,
							id_organizador,
							id_grupo,
							id_tipo_evento
						) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
					)
					.bind(
						titulo,
						descripcion,
						fechaInicio,
						duracionMinutos,
						fechaFin,
						latitud,
						longitud,
						visibilidad,
						chatHabilitado ? 1 : 0,
						idOrganizador,
						idGrupo,
						idTipoEvento
					)
					.run();

				const idEvento = result.meta.last_row_id;
				const evento = await selectEventoById(env.unparche_db, idEvento);

				return json(
					{
						ok: true,
						message: "Evento creado correctamente.",
						evento,
					},
					{ status: 201 }
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);

				const lowerMessage = message.toLowerCase();

				if (lowerMessage.includes("foreign key constraint failed")) {
					return json(
						{
							ok: false,
							error: "id_organizador, id_tipo_evento o id_grupo no existe.",
						},
						{ status: 400 }
					);
				}

				if (
					lowerMessage.includes("check constraint failed") ||
					lowerMessage.includes("not null constraint failed") ||
					lowerMessage.includes("unique constraint failed")
				) {
					return json(
						{
							ok: false,
							error: "Los datos enviados no cumplen las restricciones de la base de datos.",
						},
						{ status: 400 }
					);
				}

				return json(
					{
						ok: false,
						error: "No se pudo crear el evento.",
					},
					{ status: 500 }
				);
			}
		}

		return json({ ok: false, error: "Ruta no encontrada." }, { status: 404 });
	},
} satisfies ExportedHandler<AppEnv>;
