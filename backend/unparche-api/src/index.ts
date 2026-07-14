import * as bcrypt from "bcryptjs";
import jwt from "@tsndr/cloudflare-worker-jwt";

type AppEnv = Env & {
	unparche_db: D1Database;
	CHAT_INTERNAL_TOKEN?: string;
	JWT_SECRET: string;
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

type AgregarMiembroGrupoBody = {
	id_usuario?: number;
	rol_grupo?: "ADMINISTRADOR" | "MIEMBRO";
	estado?: "ACTIVA" | "INACTIVA";
};

type ActualizarInvitacionGrupoBody = {
	estado?: "ACEPTADA" | "RECHAZADA";
};

type ActualizarEventoBody = {
	titulo?: string;
	descripcion?: string;
	fecha_inicio?: string;
	duracion_minutos?: number;
	latitud?: number;
	longitud?: number;
	visibilidad?: "PUBLICA" | "SOLO_GRUPO" | "SOLO_AMIGOS";
	id_tipo_evento?: number;
	id_grupo?: number | null;
	chat_habilitado?: boolean;
	estado?: "PROGRAMADO" | "CANCELADO" | "FINALIZADO";
};

type CrearMensajeChatBody = {
	id_evento?: number;
	nickname?: string;
	contenido?: string;
	timestamp_ms?: number;
};

const EVENT_RETENTION_HOURS = 24;
const expiredEventCondition = `datetime(fecha_fin) <= datetime('now', '-${EVENT_RETENTION_HOURS} hours')`;
const activeEventCondition = `fecha_eliminacion IS NULL
				AND datetime(fecha_fin) > datetime('now', '-${EVENT_RETENTION_HOURS} hours')`;
const activeEventConditionForAlias = (alias: string) => `${alias}.fecha_eliminacion IS NULL
					AND datetime(${alias}.fecha_fin) > datetime('now', '-${EVENT_RETENTION_HOURS} hours')`;

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

const pruneExpiredEvents = async (db: D1Database) =>
	db
		.prepare(
			`UPDATE evento
			 SET
				estado = 'FINALIZADO',
				fecha_eliminacion = CURRENT_TIMESTAMP,
				chat_habilitado = 0
			 WHERE fecha_eliminacion IS NULL
			 AND ${expiredEventCondition}`
		)
		.run();

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
			 WHERE id_evento = ?
			 AND ${activeEventCondition}`
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
				COUNT(m.id_membresia) AS cantidad_integrantes,
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
				g.fecha_creacion,
				g.id_administrador,
				(inv.nombre || ' ' || inv.apellido) AS nombre_invitador,
				COUNT(m.id_membresia) AS cantidad_integrantes,
				COUNT(m.id_membresia) AS total_miembros
			FROM invitacion_grupo i
			JOIN grupo g
				ON g.id_grupo = i.id_grupo
			JOIN usuario inv
				ON inv.id_usuario = i.id_invitador
			LEFT JOIN membresia_grupo m
				ON m.id_grupo = g.id_grupo
				AND m.estado = 'ACTIVA'
			WHERE i.id_invitacion_grupo = ?
			GROUP BY
				i.id_invitacion_grupo,
				g.nombre,
				g.descripcion,
				g.categoria,
				g.es_oficial,
				g.estado_verificacion,
				g.fecha_creacion,
				g.id_administrador,
				inv.nombre,
				inv.apellido`
		)
		.bind(idInvitacion)
		.first();

const verifyToken = async (request: Request, env: AppEnv) => {
	const authHeader = request.headers.get("Authorization");
	if (!authHeader || !authHeader.startsWith("Bearer ")) {
		return null;
	}
	const token = authHeader.split(" ")[1];
	try {
		const isValid = await jwt.verify(token, env.JWT_SECRET || "default_secret_for_dev");
		if (!isValid) return null;
		const { payload } = jwt.decode(token);
		return payload as any;
	} catch {
		return null;
	}
};

export default {
	async scheduled(_event, env, ctx): Promise<void> {
		ctx.waitUntil(pruneExpiredEvents(env.unparche_db));
	},

	async fetch(request, env): Promise<Response> {
		const url = new URL(request.url);

		if (request.method === "OPTIONS") {
			return new Response(null, { status: 204, headers: corsHeaders });
		}

		if (request.method === "GET" && url.pathname === "/") {
			return json({ ok: true, message: "UNparche API" });
		}

		// POST /internal/mensajes
		// Llamado exclusivamente por el chat server en C++ (boost::asio),
		// de forma fire-and-forget cada vez que llega un mensaje nuevo a
		// una sala de chat. Persiste el mensaje en mensaje_chat para que
		// quede historial, tal como pide RN-19 / HU-20. No hay auth de
		// usuarios todavia, asi que el remitente se identifica solo por
		// nickname (string libre elegido en el cliente Flutter).
		if (request.method === "POST" && url.pathname === "/internal/mensajes") {
			const internalToken = env.CHAT_INTERNAL_TOKEN;

			if (internalToken) {
				const receivedToken = request.headers.get("X-Internal-Token");

				if (receivedToken !== internalToken) {
					return json({ ok: false, error: "Token interno invalido." }, { status: 401 });
				}
			}

			let body: CrearMensajeChatBody;

			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			const idEvento = toInteger(body.id_evento);
			const nickname = typeof body.nickname === "string" ? body.nickname.trim() : "";
			const contenido = typeof body.contenido === "string" ? body.contenido.trim() : "";

			if (idEvento === null || !nickname || !contenido) {
				return json(
					{
						ok: false,
						error: "id_evento, nickname y contenido son obligatorios y deben tener formato valido.",
					},
					{ status: 400 }
				);
			}

			// contenido esta acotado a VARCHAR(300) en el schema MySQL; se
			// recorta defensivamente para evitar fallos de insercion si
			// llega algo mas largo (el chat server no valida longitud).
			const contenidoRecortado = contenido.slice(0, 300);

			const fechaEnvio = typeof body.timestamp_ms === "number" && Number.isFinite(body.timestamp_ms)
				? new Date(body.timestamp_ms).toISOString()
				: new Date().toISOString();

			try {
				const result = await env.unparche_db
					.prepare(
						`INSERT INTO mensaje_chat (
							contenido,
							nickname,
							fecha_envio,
							id_evento
						) VALUES (?, ?, ?, ?)`
					)
					.bind(contenidoRecortado, nickname, fechaEnvio, idEvento)
					.run();

				return json(
					{
						ok: true,
						message: "Mensaje persistido correctamente.",
						id_mensaje: result.meta.last_row_id,
					},
					{ status: 201 }
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				const lowerMessage = message.toLowerCase();

				if (lowerMessage.includes("foreign key constraint failed")) {
					return json({ ok: false, error: "id_evento no existe." }, { status: 400 });
				}

				return json({ ok: false, error: "No se pudo persistir el mensaje." }, { status: 500 });
			}
		}

		// GET /eventos/:id/mensajes
		// Historial de un chat, para que la app lo cargue al entrar (el
		// socket TCP solo entrega mensajes nuevos en tiempo real, no
		// historial pasado).
		const mensajesEventoMatch = url.pathname.match(/^\/eventos\/(\d+)\/mensajes$/);

		if (request.method === "GET" && mensajesEventoMatch) {
			const idEvento = Number(mensajesEventoMatch[1]);

			const evento = await env.unparche_db
				.prepare(
					`SELECT id_evento, chat_habilitado
					FROM evento
					WHERE id_evento = ?
					AND fecha_eliminacion IS NULL`
				)
				.bind(idEvento)
				.first();

			if (!evento) {
				return json({ ok: false, error: "Evento no encontrado." }, { status: 404 });
			}

			const mensajes = await env.unparche_db
				.prepare(
					`SELECT
						id_mensaje,
						nickname,
						contenido,
						fecha_envio
					FROM mensaje_chat
					WHERE id_evento = ?
					ORDER BY fecha_envio ASC
					LIMIT 200`
				)
				.bind(idEvento)
				.all();

			return json({ ok: true, evento, mensajes: mensajes.results });
		}

		// POST /auth/register
		if (request.method === "POST" && url.pathname === "/auth/register") {
			let body: any;
			try { body = await request.json(); } catch { return json({ ok: false, error: "JSON invalido" }, { status: 400 }); }
			const { correo_institucional, contrasena, nombre, apellido } = body;

			if (!correo_institucional || !correo_institucional.endsWith("@unal.edu.co") || !contrasena || !nombre) {
				return json({ ok: false, error: "Datos invalidos o correo no institucional" }, { status: 400 });
			}

			try {
				const hash = await bcrypt.hash(contrasena, 10);
				const result = await env.unparche_db.prepare(
					`INSERT INTO usuario (correo_institucional, contrasena_hash, nombre, apellido) VALUES (?, ?, ?, ?)`
				).bind(correo_institucional.trim(), hash, nombre.trim(), apellido?.trim() || "").run();

				const idUsuario = result.meta.last_row_id;
				// exp: Unix timestamp de expiración (7 días desde ahora)
				const exp = Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60;
				const token = await jwt.sign({ id: idUsuario, correo: correo_institucional, exp }, env.JWT_SECRET || "default_secret_for_dev");

				return json({ ok: true, usuario: { id_usuario: idUsuario, correo_institucional, nombre, apellido, nickname: null }, token }, { status: 201 });
			} catch (e: any) {
				if (e.message?.includes("UNIQUE")) {
					return json({ ok: false, error: "El correo ya está registrado" }, { status: 409 });
				}
				return json({ ok: false, error: "Error interno al crear usuario" }, { status: 500 });
			}
		}

		// POST /auth/login
		if (request.method === "POST" && url.pathname === "/auth/login") {
			let body: any;
			try { body = await request.json(); } catch { return json({ ok: false, error: "JSON invalido" }, { status: 400 }); }
			const { correo_institucional, contrasena } = body;
			if (!correo_institucional || !contrasena) return json({ ok: false, error: "Credenciales requeridas" }, { status: 400 });

			const usuario = await env.unparche_db.prepare(`SELECT id_usuario, contrasena_hash, nombre, apellido, nickname FROM usuario WHERE correo_institucional = ?`)
				.bind(correo_institucional.trim()).first<{ id_usuario: number, contrasena_hash: string, nombre: string, apellido: string, nickname: string | null }>();

			if (!usuario) return json({ ok: false, error: "Credenciales invalidas" }, { status: 401 });

			const valid = await bcrypt.compare(contrasena, usuario.contrasena_hash);
			if (!valid) return json({ ok: false, error: "Credenciales invalidas" }, { status: 401 });

			// exp: Unix timestamp de expiración (7 días desde ahora)
			const exp = Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60;
			const token = await jwt.sign({ id: usuario.id_usuario, correo: correo_institucional, exp }, env.JWT_SECRET || "default_secret_for_dev");
			return json({ ok: true, usuario: { id_usuario: usuario.id_usuario, correo_institucional, nombre: usuario.nombre, apellido: usuario.apellido, nickname: usuario.nickname }, token });
		}

		// GET /usuarios/me
		if (request.method === "GET" && url.pathname === "/usuarios/me") {
			const payload = await verifyToken(request, env as AppEnv);
			if (!payload) return json({ ok: false, error: "No autorizado" }, { status: 401 });

			const usuario = await env.unparche_db.prepare(
				`SELECT id_usuario, correo_institucional, nombre, apellido, nickname, carrera, informacion_personal, rol, foto_perfil, fecha_creacion FROM usuario WHERE id_usuario = ?`
			).bind(payload.id).first();
			if (!usuario) return json({ ok: false, error: "Usuario no encontrado" }, { status: 404 });
			return json({ ok: true, usuario });
		}

		// PATCH /usuarios/me
		if (request.method === "PATCH" && url.pathname === "/usuarios/me") {
			const payload = await verifyToken(request, env as AppEnv);
			if (!payload) return json({ ok: false, error: "No autorizado" }, { status: 401 });

			let body: any;
			try { body = await request.json(); } catch { return json({ ok: false, error: "JSON invalido" }, { status: 400 }); }

			const allowedUpdates = ["nombre", "apellido", "nickname", "carrera", "informacion_personal", "foto_perfil"];
			const updates = [];
			const values = [];
			for (const key of allowedUpdates) {
				if (body[key] !== undefined) {
					updates.push(`${key} = ?`);
					values.push(key === "nickname" && typeof body[key] === "string" && body[key].trim() === "" ? null : body[key]);
				}
			}
			if (updates.length === 0) return json({ ok: false, error: "No hay datos para actualizar" }, { status: 400 });

			values.push(payload.id);
			await env.unparche_db.prepare(`UPDATE usuario SET ${updates.join(", ")} WHERE id_usuario = ?`).bind(...values).run();

			const usuario = await env.unparche_db.prepare(
				`SELECT id_usuario, correo_institucional, nombre, apellido, nickname, carrera, informacion_personal, rol, foto_perfil, fecha_creacion FROM usuario WHERE id_usuario = ?`
			).bind(payload.id).first();
			return json({ ok: true, usuario });
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
						g.id_grupo,
						g.nombre,
						g.descripcion,
						g.categoria,
						g.es_oficial,
						g.estado_verificacion,
						g.fecha_creacion,
						g.id_administrador,
						u.nombre || ' ' || u.apellido AS administrador_nombre,
						COUNT(m.id_membresia) AS cantidad_integrantes,
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

		// POST grupos (/grupos)
		if (request.method === "POST" && url.pathname === "/grupos") {
			let body: CrearGrupoBody;

			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			const nombre = typeof body.nombre === "string" ? body.nombre.trim() : "";
			const descripcion = typeof body.descripcion === "string" ? body.descripcion.trim() : null;
			const categoria = typeof body.categoria === "string"
				? body.categoria.trim().toUpperCase()
				: "";
			const esOficial = toBoolean(body.es_oficial, false);
			const idAdministrador = toInteger(body.id_administrador);

			if (!nombre || !categoria || idAdministrador === null || esOficial === null) {
				return json(
					{
						ok: false,
						error: "nombre, categoria e id_administrador son obligatorios y deben tener formato valido.",
					},
					{ status: 400 }
				);
			}

			if (!["ACADEMICO", "CULTURAL", "SOCIAL", "DEPORTIVO", "OTRO"].includes(categoria)) {
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
				const lowerMessage = message.toLowerCase();

				if (lowerMessage.includes("foreign key constraint failed")) {
					return json(
						{ ok: false, error: "El id_administrador no existe." },
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
					{ ok: false, error: "No se pudo crear el grupo." },
					{ status: 500 }
				);
			}
		}

		// GET grupo por id (/grupos/:id)
		const grupoMatch = url.pathname.match(/^\/grupos\/(\d+)$/);

		if (request.method === "GET" && grupoMatch) {
			const idGrupo = Number(grupoMatch[1]);
			const grupo = await selectGrupoById(env.unparche_db, idGrupo);

			if (!grupo) {
				return json({ ok: false, error: "Grupo no encontrado." }, { status: 404 });
			}

			return json({ ok: true, grupo });
		}

		// GET eventos asociados a un grupo (/grupos/:id/eventos)
		const eventosGrupoMatch = url.pathname.match(/^\/grupos\/(\d+)\/eventos$/);

		if (request.method === "GET" && eventosGrupoMatch) {
			const idGrupo = Number(eventosGrupoMatch[1]);

			const grupo = await env.unparche_db
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
					WHERE id_grupo = ?`
				)
				.bind(idGrupo)
				.first();

			if (!grupo) {
				return json({ ok: false, error: "Grupo no encontrado." }, { status: 404 });
			}

			const eventos = await env.unparche_db
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
						u.correo_institucional AS organizador_correo,
						u.carrera AS organizador_carrera,
						u.informacion_personal AS organizador_informacion,
						e.id_grupo,
						g.nombre AS grupo_nombre,
						g.descripcion AS grupo_descripcion,
						g.categoria AS grupo_categoria,
						g.es_oficial AS grupo_es_oficial,
						g.estado_verificacion AS grupo_estado_verificacion,
						e.id_tipo_evento,
						t.nombre AS tipo_evento_nombre,
						t.icono_svg AS tipo_evento_icono
					FROM evento e
					JOIN usuario u ON u.id_usuario = e.id_organizador
					JOIN tipo_evento t ON t.id_tipo_evento = e.id_tipo_evento
					JOIN grupo g ON g.id_grupo = e.id_grupo
					WHERE e.id_grupo = ?
					AND ${activeEventConditionForAlias("e")}
					ORDER BY e.fecha_inicio DESC`
				)
				.bind(idGrupo)
				.all();

			return json({
				ok: true,
				grupo,
				eventos: eventos.results,
			});
		}

		// GET miembros de un grupo (/grupos/:id/miembros)
		const miembrosGrupoMatch = url.pathname.match(/^\/grupos\/(\d+)\/miembros$/);

		if (request.method === "GET" && miembrosGrupoMatch) {
			const idGrupo = Number(miembrosGrupoMatch[1]);

			const grupo = await env.unparche_db
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
					WHERE id_grupo = ?`
				)
				.bind(idGrupo)
				.first();

			if (!grupo) {
				return json({ ok: false, error: "Grupo no encontrado." }, { status: 404 });
			}

			const miembros = await env.unparche_db
				.prepare(
					`SELECT
						m.id_membresia,
						m.id_grupo,
						m.id_usuario,
						u.nombre || ' ' || u.apellido AS usuario_nombre,
						u.correo_institucional,
						u.carrera,
						m.rol_grupo,
						m.estado,
						m.fecha_union
					FROM membresia_grupo m
					JOIN usuario u ON u.id_usuario = m.id_usuario
					WHERE m.id_grupo = ?
					ORDER BY m.fecha_union DESC`
				)
				.bind(idGrupo)
				.all();

			return json({
				ok: true,
				grupo,
				miembros: miembros.results,
			});
		}

		// POST agregar usuario a un grupo (/grupos/:id/miembros)
		if (request.method === "POST" && miembrosGrupoMatch) {
			const idGrupo = Number(miembrosGrupoMatch[1]);

			let body: AgregarMiembroGrupoBody;

			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			const idUsuario = toInteger(body.id_usuario);
			const rolGrupo = body.rol_grupo ?? "MIEMBRO";
			const estado = body.estado ?? "ACTIVA";

			if (idUsuario === null) {
				return json(
					{ ok: false, error: "id_usuario es obligatorio y debe ser entero." },
					{ status: 400 }
				);
			}

			if (!["ADMINISTRADOR", "MIEMBRO"].includes(rolGrupo)) {
				return json(
					{ ok: false, error: "rol_grupo debe ser ADMINISTRADOR o MIEMBRO." },
					{ status: 400 }
				);
			}

			if (!["ACTIVA", "INACTIVA"].includes(estado)) {
				return json(
					{ ok: false, error: "estado debe ser ACTIVA o INACTIVA." },
					{ status: 400 }
				);
			}

			try {
				await env.unparche_db
					.prepare(
						`INSERT INTO membresia_grupo (
							id_usuario,
							id_grupo,
							rol_grupo,
							estado
						) VALUES (?, ?, ?, ?)
						ON CONFLICT(id_usuario, id_grupo)
						DO UPDATE SET
							rol_grupo = excluded.rol_grupo,
							estado = excluded.estado`
					)
					.bind(idUsuario, idGrupo, rolGrupo, estado)
					.run();

				const miembro = await env.unparche_db
					.prepare(
						`SELECT
							m.id_membresia,
							m.id_grupo,
							g.nombre AS grupo_nombre,
							m.id_usuario,
							u.nombre || ' ' || u.apellido AS usuario_nombre,
							u.correo_institucional,
							u.carrera,
							m.rol_grupo,
							m.estado,
							m.fecha_union
						FROM membresia_grupo m
						JOIN grupo g ON g.id_grupo = m.id_grupo
						JOIN usuario u ON u.id_usuario = m.id_usuario
						WHERE m.id_usuario = ?
						AND m.id_grupo = ?`
					)
					.bind(idUsuario, idGrupo)
					.first();

				return json(
					{
						ok: true,
						message: "Miembro agregado correctamente.",
						miembro,
					},
					{ status: 201 }
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				const lowerMessage = message.toLowerCase();

				if (lowerMessage.includes("foreign key constraint failed")) {
					return json(
						{ ok: false, error: "El usuario o el grupo no existe." },
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
					{ ok: false, error: "No se pudo agregar el miembro al grupo." },
					{ status: 500 }
				);
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
						g.fecha_creacion,
						g.id_administrador,
						(inv.nombre || ' ' || inv.apellido) AS nombre_invitador,
						COUNT(m.id_membresia) AS cantidad_integrantes,
						COUNT(m.id_membresia) AS total_miembros
					 FROM invitacion_grupo i
					 JOIN grupo g
						ON g.id_grupo = i.id_grupo
					 JOIN usuario inv
						ON inv.id_usuario = i.id_invitador
					 LEFT JOIN membresia_grupo m
						ON m.id_grupo = g.id_grupo
						AND m.estado = 'ACTIVA'
					 WHERE i.id_invitado = ?
					 GROUP BY
						i.id_invitacion_grupo,
						g.nombre,
						g.descripcion,
						g.categoria,
						g.es_oficial,
						g.estado_verificacion,
						g.fecha_creacion,
						g.id_administrador,
						inv.nombre,
						inv.apellido
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
							id_usuario,
							id_grupo,
							rol_grupo,
							estado
						) VALUES (?, ?, 'MIEMBRO', 'ACTIVA')`
					)
					.bind(invitacionActual.id_invitado, invitacionActual.id_grupo)
					.run();
			}

			const invitacion = await selectInvitacionGrupoById(env.unparche_db, idInvitacion);
			return json({ ok: true, invitacion });
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
					AND ${activeEventConditionForAlias("e")}
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
					AND ${activeEventConditionForAlias("e")}
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
						u.correo_institucional AS organizador_correo,
						u.carrera AS organizador_carrera,
						u.informacion_personal AS organizador_informacion,
						e.id_grupo,
						g.nombre AS grupo_nombre,
						g.descripcion AS grupo_descripcion,
						g.categoria AS grupo_categoria,
						g.es_oficial AS grupo_es_oficial,
						g.estado_verificacion AS grupo_estado_verificacion,
						e.id_tipo_evento,
						t.nombre AS tipo_evento_nombre,
						t.icono_svg AS tipo_evento_icono
					FROM evento e
					JOIN usuario u ON u.id_usuario = e.id_organizador
					JOIN tipo_evento t ON t.id_tipo_evento = e.id_tipo_evento
					LEFT JOIN grupo g ON g.id_grupo = e.id_grupo
					WHERE e.id_evento = ?
					AND ${activeEventConditionForAlias("e")}`
				)
				.bind(idEvento)
				.first();

			if (!evento) {
				return json({ ok: false, error: "Evento no encontrado." }, { status: 404 });
			}

			return json({ ok: true, evento });
		}

		// PATCH editar un evento (/eventos/:id)
		if (request.method === "PATCH" && eventoMatch) {
			const idEvento = Number(eventoMatch[1]);

			let body: ActualizarEventoBody;

			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			const eventoActual = await env.unparche_db
				.prepare(
					`SELECT
						id_evento,
						titulo,
						descripcion,
						fecha_inicio,
						duracion_minutos,
						latitud,
						longitud,
						visibilidad,
						chat_habilitado,
						estado,
						id_grupo,
						id_tipo_evento
					FROM evento
					WHERE id_evento = ?
					AND ${activeEventCondition}`
				)
				.bind(idEvento)
				.first<{
					id_evento: number;
					titulo: string;
					descripcion: string;
					fecha_inicio: string;
					duracion_minutos: number;
					latitud: number;
					longitud: number;
					visibilidad: "PUBLICA" | "SOLO_GRUPO" | "SOLO_AMIGOS";
					chat_habilitado: number;
					estado: "PROGRAMADO" | "CANCELADO" | "FINALIZADO";
					id_grupo: number | null;
					id_tipo_evento: number;
				}>();

			if (!eventoActual) {
				return json({ ok: false, error: "Evento no encontrado." }, { status: 404 });
			}

			const titulo =
				body.titulo !== undefined
					? typeof body.titulo === "string"
						? body.titulo.trim()
						: ""
					: eventoActual.titulo;

			const descripcion =
				body.descripcion !== undefined
					? typeof body.descripcion === "string"
						? body.descripcion.trim()
						: ""
					: eventoActual.descripcion;

			const fechaInicio =
				body.fecha_inicio !== undefined
					? typeof body.fecha_inicio === "string"
						? body.fecha_inicio.trim()
						: ""
					: eventoActual.fecha_inicio;

			const duracionMinutos =
				body.duracion_minutos !== undefined
					? toInteger(body.duracion_minutos)
					: eventoActual.duracion_minutos;

			const latitud =
				body.latitud !== undefined
					? toNumber(body.latitud)
					: eventoActual.latitud;

			const longitud =
				body.longitud !== undefined
					? toNumber(body.longitud)
					: eventoActual.longitud;

			const visibilidad = body.visibilidad ?? eventoActual.visibilidad;

			const idTipoEvento =
				body.id_tipo_evento !== undefined
					? toInteger(body.id_tipo_evento)
					: eventoActual.id_tipo_evento;

			const idGrupo =
				body.id_grupo === undefined
					? eventoActual.id_grupo
					: body.id_grupo === null
						? null
						: toInteger(body.id_grupo);

			const chatHabilitado =
				body.chat_habilitado !== undefined
					? toBoolean(body.chat_habilitado, true)
					: Boolean(eventoActual.chat_habilitado);

			const estado = body.estado ?? eventoActual.estado;

			if (
				!titulo ||
				!descripcion ||
				!fechaInicio ||
				duracionMinutos === null ||
				duracionMinutos <= 0 ||
				latitud === null ||
				longitud === null ||
				idTipoEvento === null ||
				(idGrupo === null && body.id_grupo !== null && body.id_grupo !== undefined) ||
				chatHabilitado === null
			) {
				return json(
					{ ok: false, error: "Los campos enviados tienen un formato invalido." },
					{ status: 400 }
				);
			}

			const fechaFin = buildFechaFin(fechaInicio, duracionMinutos);

			if (fechaFin === null) {
				return json({ ok: false, error: "fecha_inicio debe ser una fecha ISO valida." }, { status: 400 });
			}

			if (!["PUBLICA", "SOLO_GRUPO", "SOLO_AMIGOS"].includes(visibilidad)) {
				return json({ ok: false, error: "visibilidad debe ser PUBLICA, SOLO_GRUPO o SOLO_AMIGOS." }, { status: 400 });
			}

			if (visibilidad === "SOLO_GRUPO" && idGrupo === null) {
				return json(
					{ ok: false, error: "id_grupo es obligatorio cuando la visibilidad es SOLO_GRUPO." },
					{ status: 400 }
				);
			}

			if (!["PROGRAMADO", "CANCELADO", "FINALIZADO"].includes(estado)) {
				return json(
					{ ok: false, error: "estado debe ser PROGRAMADO, CANCELADO o FINALIZADO." },
					{ status: 400 }
				);
			}

			if (latitud < -90 || latitud > 90) {
				return json({ ok: false, error: "latitud debe estar entre -90 y 90." }, { status: 400 });
			}

			if (longitud < -180 || longitud > 180) {
				return json({ ok: false, error: "longitud debe estar entre -180 y 180." }, { status: 400 });
			}

			try {
				await env.unparche_db
					.prepare(
						`UPDATE evento
						SET
							titulo = ?,
							descripcion = ?,
							fecha_inicio = ?,
							duracion_minutos = ?,
							fecha_fin = ?,
							latitud = ?,
							longitud = ?,
							visibilidad = ?,
							chat_habilitado = ?,
							estado = ?,
							id_grupo = ?,
							id_tipo_evento = ?
						WHERE id_evento = ?
						AND fecha_eliminacion IS NULL`
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
						estado,
						idGrupo,
						idTipoEvento,
						idEvento
					)
					.run();

				const evento = await selectEventoById(env.unparche_db, idEvento);

				return json({
					ok: true,
					message: "Evento actualizado correctamente.",
					evento,
				});
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				const lowerMessage = message.toLowerCase();

				if (lowerMessage.includes("foreign key constraint failed")) {
					return json(
						{ ok: false, error: "id_tipo_evento o id_grupo no existe." },
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
					{ ok: false, error: "No se pudo actualizar el evento." },
					{ status: 500 }
				);
			}
		}

		// DELETE borrar evento (/eventos/:id)
		if (request.method === "DELETE" && eventoMatch) {
			const idEvento = Number(eventoMatch[1]);

			const eventoActual = await env.unparche_db
				.prepare(
					`SELECT
						id_evento,
						titulo,
						estado,
						fecha_eliminacion
					FROM evento
					WHERE id_evento = ?
					AND ${activeEventCondition}`
				)
				.bind(idEvento)
				.first();

			if (!eventoActual) {
				return json({ ok: false, error: "Evento no encontrado." }, { status: 404 });
			}

			try {
				await env.unparche_db
					.prepare(
						`UPDATE evento
						SET
							estado = 'CANCELADO',
							fecha_eliminacion = CURRENT_TIMESTAMP
						WHERE id_evento = ?
						AND fecha_eliminacion IS NULL`
					)
					.bind(idEvento)
					.run();

				const evento = await env.unparche_db
					.prepare(
						`SELECT
							id_evento,
							titulo,
							descripcion,
							fecha_inicio,
							duracion_minutos,
							fecha_fin,
							fecha_publicacion,
							fecha_eliminacion,
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

				return json({
					ok: true,
					message: "Evento eliminado correctamente.",
					evento,
				});
			} catch {
				return json(
					{ ok: false, error: "No se pudo eliminar el evento." },
					{ status: 500 }
				);
			}
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

			const evento = await env.unparche_db
				.prepare(
					`SELECT
						id_evento,
						chat_habilitado
					FROM evento
					WHERE id_evento = ?
					AND ${activeEventCondition}`
				)
				.bind(idEvento)
				.first();

			if (!evento) {
				return json({ ok: false, error: "Evento no encontrado o finalizado." }, { status: 404 });
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

		// GET asistencias de un evento y confirmados (/eventos/:id/asistencias)
		const asistenciasEventoMatch = url.pathname.match(/^\/eventos\/(\d+)\/asistencias$/);

		if (request.method === "GET" && asistenciasEventoMatch) {
			const idEvento = Number(asistenciasEventoMatch[1]);

			const evento = await env.unparche_db
				.prepare(
					`SELECT
						id_evento,
						titulo
					FROM evento
					WHERE id_evento = ?
					AND fecha_eliminacion IS NULL`
				)
				.bind(idEvento)
				.first();

			if (!evento) {
				return json({ ok: false, error: "Evento no encontrado." }, { status: 404 });
			}

			const resumen = await env.unparche_db
				.prepare(
					`SELECT
						SUM(CASE WHEN estado = 'CONFIRMADA' THEN 1 ELSE 0 END) AS total_confirmadas,
						SUM(CASE WHEN estado = 'CANCELADA' THEN 1 ELSE 0 END) AS total_canceladas,
						COUNT(*) AS total_registros
					FROM asistencia
					WHERE id_evento = ?`
				)
				.bind(idEvento)
				.first();

			const asistencias = await env.unparche_db
				.prepare(
					`SELECT
						a.id_asistencia,
						a.id_usuario,
						u.nombre || ' ' || u.apellido AS usuario_nombre,
						u.correo_institucional,
						a.id_evento,
						a.estado,
						a.notificaciones_activas,
						a.fecha_confirmacion
					FROM asistencia a
					JOIN usuario u ON u.id_usuario = a.id_usuario
					WHERE a.id_evento = ?
					ORDER BY a.fecha_confirmacion DESC`
				)
				.bind(idEvento)
				.all();

			return json({
				ok: true,
				evento,
				resumen: {
					total_confirmadas: resumen?.total_confirmadas ?? 0,
					total_canceladas: resumen?.total_canceladas ?? 0,
					total_registros: resumen?.total_registros ?? 0,
				},
				asistencias: asistencias.results,
			});
		}


		// GET ids de todos los eventos actuales con chat habilitado
		if (request.method === "GET" && url.pathname === "/eventos/ids-actuales") {
			const eventosActuales = await env.unparche_db
				.prepare(
					`SELECT
						id_evento
					FROM evento
					WHERE ${activeEventCondition}
					AND estado IN ('PROGRAMADO', 'EN_CURSO')
					AND chat_habilitado = 1
					ORDER BY fecha_inicio ASC`
				)
				.all<{ id_evento: number }>();

			return json(eventosActuales.results.map((evento) => evento.id_evento));
		}

		// GET eventos
		if (request.method === "GET" && url.pathname === "/eventos") {
			const idUsuarioParam = url.searchParams.get("id_usuario");
			const idUsuario = idUsuarioParam === null ? null : Number(idUsuarioParam);

			if (idUsuarioParam !== null && !Number.isInteger(idUsuario)) {
				return json(
					{ ok: false, error: "id_usuario debe ser entero." },
					{ status: 400 }
				);
			}

			const asistenciaSelect = idUsuario === null
				? `NULL AS estado_asistencia,
						NULL AS fecha_confirmacion`
				: `a.estado AS estado_asistencia,
						a.fecha_confirmacion`;
			const asistenciaJoin = idUsuario === null
				? ""
				: `LEFT JOIN asistencia a
					ON a.id_evento = e.id_evento
					AND a.id_usuario = ?`;
			const eventosQuery = `SELECT
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
				u.correo_institucional AS organizador_correo,
				u.carrera AS organizador_carrera,
				u.informacion_personal AS organizador_informacion,
				e.id_grupo,
				g.nombre AS grupo_nombre,
				g.descripcion AS grupo_descripcion,
				g.categoria AS grupo_categoria,
				g.es_oficial AS grupo_es_oficial,
				g.estado_verificacion AS grupo_estado_verificacion,
				e.id_tipo_evento,
				t.nombre AS tipo_evento_nombre,
				t.icono_svg AS tipo_evento_icono,
				${asistenciaSelect}
			FROM evento e
			JOIN usuario u ON u.id_usuario = e.id_organizador
			JOIN tipo_evento t ON t.id_tipo_evento = e.id_tipo_evento
			LEFT JOIN grupo g ON g.id_grupo = e.id_grupo
			${asistenciaJoin}
			WHERE ${activeEventConditionForAlias("e")}
			ORDER BY e.fecha_inicio DESC`;
			const eventosStatement = env.unparche_db.prepare(eventosQuery);
			const eventos = idUsuario === null
				? await eventosStatement.all()
				: await eventosStatement.bind(idUsuario).all();

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
