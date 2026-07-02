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

type CrearGrupoBody = {
	nombre?: string;
	descripcion?: string;
	categoria?: "ACADEMICO" | "CULTURAL" | "SOCIAL" | "DEPORTIVO" | "OTRO";
	id_administrador?: number;
};

type ActualizarInvitacionGrupoBody = {
	estado?: "ACEPTADA" | "RECHAZADA";
};

const corsHeaders = {
	"Access-Control-Allow-Origin": "*",
	"Access-Control-Allow-Methods": "GET, POST, PATCH, OPTIONS",
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
				COUNT(m.id_membresia) AS cantidad_integrantes
			 FROM grupo g
			 LEFT JOIN membresia_grupo m
				ON m.id_grupo = g.id_grupo
				AND m.estado = 'ACTIVA'
			 WHERE g.id_grupo = ?
			 GROUP BY g.id_grupo`
		)
		.bind(idGrupo)
		.first();

const selectInvitacionGrupoById = async (db: D1Database, idInvitacion: number) =>
	db
		.prepare(
			`SELECT
				i.id_invitacion_grupo,
				i.estado,
				i.fecha_envio,
				i.fecha_respuesta,
				i.id_grupo,
				i.id_invitado,
				i.id_invitador,
				g.nombre,
				g.descripcion,
				g.categoria,
				g.es_oficial,
				g.estado_verificacion,
				g.id_administrador,
				(inv.nombre || ' ' || inv.apellido) AS nombre_invitador,
				COUNT(m.id_membresia) AS cantidad_integrantes
			 FROM invitacion_grupo i
			 JOIN grupo g
				ON g.id_grupo = i.id_grupo
			 JOIN usuario inv
				ON inv.id_usuario = i.id_invitador
			 LEFT JOIN membresia_grupo m
				ON m.id_grupo = g.id_grupo
				AND m.estado = 'ACTIVA'
			 WHERE i.id_invitacion_grupo = ?
			 GROUP BY i.id_invitacion_grupo`
		)
		.bind(idInvitacion)
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
						COUNT(m.id_membresia) AS cantidad_integrantes
					 FROM grupo g
					 LEFT JOIN membresia_grupo m
						ON m.id_grupo = g.id_grupo
						AND m.estado = 'ACTIVA'
					 GROUP BY g.id_grupo
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
			const descripcion = typeof body.descripcion === "string" ? body.descripcion.trim() : "";
			const categoria = body.categoria;
			const idAdministrador = toInteger(body.id_administrador);

			if (!nombre || !categoria || idAdministrador === null) {
				return json(
					{
						ok: false,
						error: "nombre, categoria e id_administrador son obligatorios.",
					},
					{ status: 400 }
				);
			}

			if (!["ACADEMICO", "CULTURAL", "SOCIAL", "DEPORTIVO", "OTRO"].includes(categoria)) {
				return json({ ok: false, error: "categoria no es valida." }, { status: 400 });
			}

			try {
				const result = await env.unparche_db
					.prepare(
						`INSERT INTO grupo (
							nombre,
							descripcion,
							categoria,
							es_oficial,
							estado_verificacion,
							id_administrador
						) VALUES (?, ?, ?, 0, 'NO_SOLICITADO', ?)`
					)
					.bind(nombre, descripcion, categoria, idAdministrador)
					.run();

				const idGrupo = result.meta.last_row_id;

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

		const invitacionesUsuarioMatch = url.pathname.match(/^\/usuarios\/(\d+)\/invitaciones-grupo$/);
		if (request.method === "GET" && invitacionesUsuarioMatch) {
			const idUsuario = Number.parseInt(invitacionesUsuarioMatch[1], 10);
			const invitaciones = await env.unparche_db
				.prepare(
					`SELECT
						i.id_invitacion_grupo,
						i.estado,
						i.fecha_envio,
						i.fecha_respuesta,
						i.id_grupo,
						i.id_invitado,
						i.id_invitador,
						g.nombre,
						g.descripcion,
						g.categoria,
						g.es_oficial,
						g.estado_verificacion,
						g.id_administrador,
						(inv.nombre || ' ' || inv.apellido) AS nombre_invitador,
						COUNT(m.id_membresia) AS cantidad_integrantes
					 FROM invitacion_grupo i
					 JOIN grupo g
						ON g.id_grupo = i.id_grupo
					 JOIN usuario inv
						ON inv.id_usuario = i.id_invitador
					 LEFT JOIN membresia_grupo m
						ON m.id_grupo = g.id_grupo
						AND m.estado = 'ACTIVA'
					 WHERE i.id_invitado = ?
					 GROUP BY i.id_invitacion_grupo
					 ORDER BY i.fecha_envio DESC`
				)
				.bind(idUsuario)
				.all();

			return json({ ok: true, invitaciones: invitaciones.results });
		}

		const invitacionMatch = url.pathname.match(/^\/invitaciones-grupo\/(\d+)$/);
		if (request.method === "PATCH" && invitacionMatch) {
			const idInvitacion = Number.parseInt(invitacionMatch[1], 10);
			let body: ActualizarInvitacionGrupoBody;

			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			const estado = body.estado;
			if (!estado || !["ACEPTADA", "RECHAZADA"].includes(estado)) {
				return json({ ok: false, error: "estado debe ser ACEPTADA o RECHAZADA." }, { status: 400 });
			}

			const invitacionActual = await env.unparche_db
				.prepare(
					`SELECT id_invitacion_grupo, estado, id_grupo, id_invitado
					 FROM invitacion_grupo
					 WHERE id_invitacion_grupo = ?`
				)
				.bind(idInvitacion)
				.first();

			if (!invitacionActual) {
				return json({ ok: false, error: "Invitacion no encontrada." }, { status: 404 });
			}

			if (invitacionActual.estado !== "PENDIENTE") {
				return json({ ok: false, error: "La invitacion ya fue respondida." }, { status: 409 });
			}

			await env.unparche_db
				.prepare(
					`UPDATE invitacion_grupo
					 SET estado = ?, fecha_respuesta = CURRENT_TIMESTAMP
					 WHERE id_invitacion_grupo = ?`
				)
				.bind(estado, idInvitacion)
				.run();

			if (estado === "ACEPTADA") {
				await env.unparche_db
					.prepare(
						`INSERT OR IGNORE INTO membresia_grupo (
							rol_grupo,
							estado,
							id_usuario,
							id_grupo
						) VALUES ('MIEMBRO', 'ACTIVA', ?, ?)`
					)
					.bind(invitacionActual.id_invitado, invitacionActual.id_grupo)
					.run();
			}

			const invitacion = await selectInvitacionGrupoById(env.unparche_db, idInvitacion);
			return json({ ok: true, invitacion });
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
