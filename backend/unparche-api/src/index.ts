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

type CrearGrupoBody = {
	nombre?: string;
	descripcion?: string | null;
	categoria?: "ACADEMICO" | "CULTURAL" | "SOCIAL" | "DEPORTIVO" | "OTRO";
	es_oficial?: boolean;
	id_administrador?: number;
};

const corsHeaders = {
	"Access-Control-Allow-Origin": "*",
	"Access-Control-Allow-Methods": "GET, POST, OPTIONS",
	"Access-Control-Allow-Headers": "Content-Type",
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

const selectGrupoById = async (db: D1Database, idGrupo: number) =>
	db
		.prepare(
			`SELECT
				g.id_grupo,
				g.nombre,
				g.descripcion,
				g.categoria,
				g.es_oficial,
				g.estado_verificacion,
				g.fecha_creacion,
				g.id_administrador,
				u.nombre || ' ' || u.apellido AS administrador_nombre,
				COUNT(m.id_membresia) AS total_miembros
			 FROM grupo g
			 JOIN usuario u ON u.id_usuario = g.id_administrador
			 LEFT JOIN membresia_grupo m
				ON m.id_grupo = g.id_grupo
				AND m.estado = 'ACTIVA'
			 WHERE g.id_grupo = ?
			 GROUP BY
				g.id_grupo,
				g.nombre,
				g.descripcion,
				g.categoria,
				g.es_oficial,
				g.estado_verificacion,
				g.fecha_creacion,
				g.id_administrador,
				u.nombre,
				u.apellido`
		)
		.bind(idGrupo)
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

		if (request.method === "GET" && url.pathname === "/grupos") {
			const grupos = await env.unparche_db
				.prepare(
					`SELECT
						g.id_grupo,
						g.nombre,
						g.descripcion,
						g.categoria,
						g.es_oficial,
						g.estado_verificacion,
						g.fecha_creacion,
						g.id_administrador,
						u.nombre || ' ' || u.apellido AS administrador_nombre,
						COUNT(m.id_membresia) AS total_miembros
					 FROM grupo g
					 JOIN usuario u ON u.id_usuario = g.id_administrador
					 LEFT JOIN membresia_grupo m
						ON m.id_grupo = g.id_grupo
						AND m.estado = 'ACTIVA'
					 GROUP BY
						g.id_grupo,
						g.nombre,
						g.descripcion,
						g.categoria,
						g.es_oficial,
						g.estado_verificacion,
						g.fecha_creacion,
						g.id_administrador,
						u.nombre,
						u.apellido
					 ORDER BY g.nombre ASC`
				)
				.all();

			return json({ ok: true, grupos: grupos.results });
		}

		if (request.method === "POST" && url.pathname === "/grupos") {
			let body: CrearGrupoBody;

			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			const nombre = typeof body.nombre === "string" ? body.nombre.trim() : "";
			const descripcion = typeof body.descripcion === "string" ? body.descripcion.trim() : null;
			const categoria = body.categoria;
			const esOficial = toBoolean(body.es_oficial, false);
			const idAdministrador = toInteger(body.id_administrador);

			if (!nombre || idAdministrador === null || esOficial === null) {
				return json(
					{ ok: false, error: "nombre e id_administrador son obligatorios y deben tener formato valido." },
					{ status: 400 }
				);
			}

			if (!categoria || !["ACADEMICO", "CULTURAL", "SOCIAL", "DEPORTIVO", "OTRO"].includes(categoria)) {
				return json(
					{ ok: false, error: "categoria debe ser ACADEMICO, CULTURAL, SOCIAL, DEPORTIVO u OTRO." },
					{ status: 400 }
				);
			}

			try {
				const grupoResult = await env.unparche_db
					.prepare(
						`INSERT INTO grupo (
							nombre,
							descripcion,
							categoria,
							es_oficial,
							id_administrador
						) VALUES (?, ?, ?, ?, ?)`
					)
					.bind(nombre, descripcion, categoria, esOficial ? 1 : 0, idAdministrador)
					.run();

				const idGrupo = grupoResult.meta.last_row_id;

				await env.unparche_db
					.prepare(
						`INSERT INTO membresia_grupo (
							rol_grupo,
							estado,
							id_usuario,
							id_grupo
						) VALUES ('ADMINISTRADOR', 'ACTIVA', ?, ?)`
					)
					.bind(idAdministrador, idGrupo)
					.run();

				const grupo = await selectGrupoById(env.unparche_db, idGrupo);

				return json(
					{
						ok: true,
						message: "Grupo creado correctamente.",
						grupo,
					},
					{ status: 201 }
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);

				if (message.toLowerCase().includes("foreign key constraint failed")) {
					return json({ ok: false, error: "id_administrador no existe." }, { status: 400 });
				}

				return json({ ok: false, error: "No se pudo crear el grupo." }, { status: 500 });
			}
		}

		const grupoMatch = url.pathname.match(/^\/grupos\/(\d+)$/);

		if (request.method === "GET" && grupoMatch) {
			const idGrupo = Number(grupoMatch[1]);
			const grupo = await selectGrupoById(env.unparche_db, idGrupo);

			if (!grupo) {
				return json({ ok: false, error: "Grupo no encontrado." }, { status: 404 });
			}

			return json({ ok: true, grupo });
		}

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
						e.fecha_eliminacion,
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
				return json({ ok: false, error: "estado debe ser CONFIRMADA o CANCELADA." }, { status: 400 });
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

				if (message.toLowerCase().includes("foreign key constraint failed")) {
					return json({ ok: false, error: "El evento o el usuario no existe." }, { status: 400 });
				}

				return json({ ok: false, error: "No se pudo registrar la asistencia." }, { status: 500 });
			}
		}

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

				if (message.toLowerCase().includes("foreign key constraint failed")) {
					return json(
						{
							ok: false,
							error: "id_organizador, id_tipo_evento o id_grupo no existe.",
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
				)
			}
		}

		return json({ ok: false, error: "Ruta no encontrada." }, { status: 404 });
	},
} satisfies ExportedHandler<AppEnv>;
