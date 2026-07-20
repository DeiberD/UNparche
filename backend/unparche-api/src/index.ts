import * as bcrypt from "bcryptjs";
import jwt from "@tsndr/cloudflare-worker-jwt";

/**
 * UNparche Cloudflare Worker.
 *
 * This module is the HTTP entry point for the mobile application. It validates
 * requests, coordinates authentication and email providers, and persists the
 * domain data through the D1 binding. Routes are evaluated from top to bottom,
 * so specific paths must appear before general regular expressions.
 */

/** Runtime resources injected by Cloudflare from wrangler.jsonc and secrets. */
type AppEnv = Env & {
	// D1 binding used by every repository-style query in this Worker.
	unparche_db: D1Database;
	// Optional shared secret used by the external C++ chat server.
	CHAT_INTERNAL_TOKEN?: string;
	// Signs and verifies application session tokens.
	JWT_SECRET: string;
	// OAuth audience accepted by the Google Sign-In endpoint.
	GOOGLE_WEB_CLIENT_ID?: string;
	// Enables verification and password-reset emails through Resend.
	RESEND_API_KEY?: string;
};

// Request DTOs keep untrusted JSON optional until each endpoint validates it.
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

type ActualizarInvitacionGrupoBody = {
	estado?: "ACEPTADA" | "RECHAZADA";
	id_usuario?: number;
};

type CrearInvitacionGrupoBody = {
	id_invitador?: number;
	correo_institucional?: string;
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

type CrearAnuncioBody = {
	contenido?: string;
	id_autor?: number;
};

type ActualizarNotificacionesBody = {
	activas?: boolean;
};

// Event lifecycle rules shared by list, detail, update and cleanup queries.
const EVENT_RETENTION_HOURS = 24;
const EVENT_HISTORY_MONTHS = 6;
const expiredEventCondition = `datetime(fecha_fin) <= datetime('now', '-${EVENT_RETENTION_HOURS} hours')`;
const activeEventCondition = `fecha_eliminacion IS NULL
				AND datetime(fecha_fin) > datetime('now', '-${EVENT_RETENTION_HOURS} hours')`;
const activeEventConditionForAlias = (alias: string) => `${alias}.fecha_eliminacion IS NULL
					AND datetime(${alias}.fecha_fin) > datetime('now', '-${EVENT_RETENTION_HOURS} hours')`;
const visibleEventHistoryConditionForAlias = (alias: string) => `
					(${alias}.fecha_eliminacion IS NULL OR ${alias}.estado = 'FINALIZADO')
					AND datetime(${alias}.fecha_fin) >= datetime('now', '-${EVENT_HISTORY_MONTHS} months')`;

// All API responses, including errors, expose the same CORS policy to Flutter.
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

/** Derives the canonical end timestamp instead of trusting a client value. */
const buildFechaFin = (fechaInicio: string, duracionMinutos: number) => {
	const inicio = new Date(fechaInicio);

	if (Number.isNaN(inicio.getTime())) {
		return null;
	}

	return new Date(inicio.getTime() + duracionMinutos * 60_000).toISOString();
};

// Narrowing helpers reject strings and non-finite values from decoded JSON.
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

/**
 * HU-36 lifecycle cleanup.
 *
 * The row is soft-deleted so histories can still identify the event. Active
 * views stop returning it and its chat is disabled for new interactions.
 */
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

// Shared selectors centralize response shapes reused after mutations.
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

// ─── Helpers de verificación de correo ────────────────────────────────────

/** Genera un código numérico de 6 dígitos */
const generarCodigo6Digitos = (): string =>
	Math.floor(100000 + Math.random() * 900000).toString();

/** Devuelve un timestamp ISO UTC con una expiración de N minutos desde ahora */
const expirarEn = (minutos: number): string =>
	new Date(Date.now() + minutos * 60 * 1000).toISOString();

/** Construye el HTML de la plantilla de correo */
const buildEmailHtml = (tipo: "registro" | "reset_password", codigo: string): string => {
	const campusInk = "#263020";
	const campusBackground = "#FBF5F2";
	const campusSurface = "#F3ECE8";
	const campusAccent = "#EEDDF0";

	const subject = tipo === "registro"
		? "Verifica tu correo en UNparche"
		: "Restablece tu contraseña en UNparche";
	const bodyText = tipo === "registro"
		? "Para completar tu registro, ingresa el siguiente código de verificación:"
		: "Para restablecer tu contraseña, ingresa el siguiente código:";
	const expiryNote = "Este código expira en 15 minutos. Si no realizaste esta solicitud, ignora este mensaje.";

	return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${subject}</title></head>
<body style="margin:0;padding:0;background-color:${campusBackground};font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:${campusBackground};padding:32px 16px;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:12px;border:1px solid ${campusSurface};overflow:hidden;">
        <!-- Header -->
        <tr><td style="background-color:${campusInk};padding:28px 32px;text-align:center;">
          <p style="margin:0;color:#ffffff;font-size:28px;font-weight:900;letter-spacing:-0.5px;">UNparche</p>
          <p style="margin:6px 0 0;color:rgba(255,255,255,0.7);font-size:13px;">Universidad Nacional de Colombia</p>
        </td></tr>
        <!-- Body -->
        <tr><td style="padding:32px;">
          <p style="margin:0 0 8px;color:${campusInk};font-size:20px;font-weight:700;">${subject}</p>
          <p style="margin:0 0 24px;color:#555555;font-size:14px;line-height:1.6;">${bodyText}</p>
          <!-- Code box -->
          <table width="100%" cellpadding="0" cellspacing="0">
            <tr><td align="center" style="padding:0 0 24px;">
              <div style="display:inline-block;background-color:${campusAccent};border:2px solid ${campusInk};border-radius:12px;padding:20px 40px;">
                <p style="margin:0;color:${campusInk};font-size:42px;font-weight:900;letter-spacing:12px;font-family:'Courier New',Courier,monospace;">${codigo}</p>
              </div>
            </td></tr>
          </table>
          <p style="margin:0;color:#888888;font-size:12px;line-height:1.6;text-align:center;">${expiryNote}</p>
        </td></tr>
        <!-- Footer -->
        <tr><td style="background-color:${campusSurface};padding:16px 32px;text-align:center;">
          <p style="margin:0;color:#999999;font-size:11px;">Este correo fue enviado automáticamente. Por favor no respondas a este mensaje.</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
};

const escapeHtml = (value: string): string => value
	.replaceAll("&", "&amp;")
	.replaceAll("<", "&lt;")
	.replaceAll(">", "&gt;")
	.replaceAll('"', "&quot;")
	.replaceAll("'", "&#039;");

/** Builds a small email notification without trusting announcement HTML. */
const buildAnnouncementEmailHtml = (eventTitle: string, content: string): string => `
	<div style="font-family:Arial,Helvetica,sans-serif;color:#263020;line-height:1.5">
		<h2 style="margin-bottom:8px">Novedad en ${escapeHtml(eventTitle)}</h2>
		<p style="white-space:pre-wrap">${escapeHtml(content)}</p>
		<p style="color:#666;font-size:12px">Recibiste este correo porque activaste las novedades del evento en UNparche.</p>
	</div>`;

/** Envía un correo usando la API de Resend */
const sendEmail = async (
	resendApiKey: string,
	to: string,
	subject: string,
	html: string,
): Promise<void> => {
	const resp = await fetch("https://api.resend.com/emails", {
		method: "POST",
		headers: {
			"Authorization": `Bearer ${resendApiKey}`,
			"Content-Type": "application/json",
		},
		body: JSON.stringify({
			from: "UNparche <noreply@unparche.app>",
			to: [to],
			subject,
			html,
		}),
	});
	if (!resp.ok) {
		const err = await resp.text();
		throw new Error(`Resend error ${resp.status}: ${err}`);
	}
};

const verifyToken = async (request: Request, env: AppEnv) => {
	// Protected routes receive the JWT through the standard Bearer header.
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

/**
 * Cloudflare invokes `scheduled` for cron jobs and `fetch` for HTTP requests.
 * Both handlers share the lifecycle, validation and D1 helpers above.
 */
export default {
	async scheduled(_event, env, ctx): Promise<void> {
		// waitUntil keeps the cron execution alive until D1 finishes the cleanup.
		ctx.waitUntil(pruneExpiredEvents(env.unparche_db));
	},

	async fetch(request, env): Promise<Response> {
		const url = new URL(request.url);

		// Browsers send this preflight before cross-origin non-simple requests.
		if (request.method === "OPTIONS") {
			return new Response(null, { status: 204, headers: corsHeaders });
		}

		if (request.method === "GET" && url.pathname === "/") {
			return json({ ok: true, message: "UNparche API" });
		}

		// -------------------------------------------------------------------------
		// Internal chat bridge
		// -------------------------------------------------------------------------
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

		// -------------------------------------------------------------------------
		// Authentication, email verification and user session
		// -------------------------------------------------------------------------
		// POST /auth/register
		if (request.method === "POST" && url.pathname === "/auth/register") {
			let body: any;
			try { body = await request.json(); } catch { return json({ ok: false, error: "JSON invalido" }, { status: 400 }); }
			const { correo_institucional, contrasena, nombre, apellido, carrera, nickname } = body;
			
			if (!correo_institucional || !correo_institucional.endsWith("@unal.edu.co") || !contrasena || !nombre || !nickname) {
				return json({ ok: false, error: "Datos invalidos o correo no institucional" }, { status: 400 });
			}

			const existingNickname = await env.unparche_db.prepare(`SELECT id_usuario FROM usuario WHERE nickname = ?`).bind(nickname.trim()).first();
			if (existingNickname) {
				return json({ ok: false, error: "nickname ya está en uso" }, { status: 409 });
			}

			try {
				// Passwords are persisted only as bcrypt hashes; the plain value is discarded.
				const hash = await bcrypt.hash(contrasena, 10);
				const result = await env.unparche_db.prepare(
					`INSERT INTO usuario (correo_institucional, contrasena_hash, nombre, apellido, carrera, nickname, correo_verificado) VALUES (?, ?, ?, ?, ?, ?, 0)`
				).bind(correo_institucional.trim(), hash, nombre.trim(), apellido?.trim() || "", carrera?.trim() || null, nickname.trim()).run();

				const idUsuario = result.meta.last_row_id;

				// Generar y guardar código de verificación (expira en 15 min)
				const codigo = generarCodigo6Digitos();
				const expira = expirarEn(15);
				await env.unparche_db.prepare(
					`INSERT INTO codigo_verificacion (id_usuario, codigo, tipo, expira_en) VALUES (?, ?, 'registro', ?)`
				).bind(idUsuario, codigo, expira).run();

				// Enviar correo de verificación (no bloquea el registro si falla)
				if (env.RESEND_API_KEY) {
					try {
						await sendEmail(
							env.RESEND_API_KEY,
							correo_institucional.trim(),
							"Verifica tu correo en UNparche",
							buildEmailHtml("registro", codigo),
						);
					} catch (mailErr) {
						console.error("Error enviando correo de verificación:", mailErr);
					}
				}

				return json({ ok: true, requiereVerificacion: true, correo_institucional: correo_institucional.trim() }, { status: 201 });
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

			const usuario = await env.unparche_db.prepare(`SELECT id_usuario, contrasena_hash, nombre, apellido, nickname, correo_verificado FROM usuario WHERE correo_institucional = ?`)
				.bind(correo_institucional.trim()).first<{ id_usuario: number, contrasena_hash: string, nombre: string, apellido: string, nickname: string | null, correo_verificado: number }>();

			if (!usuario) return json({ ok: false, error: "Credenciales invalidas" }, { status: 401 });

			const valid = await bcrypt.compare(contrasena, usuario.contrasena_hash);
			if (!valid) return json({ ok: false, error: "Credenciales invalidas" }, { status: 401 });

			// Bloquear login si el correo no ha sido verificado
			if (!usuario.correo_verificado) {
				return json({ ok: false, error: "correo_no_verificado" }, { status: 403 });
			}

			// exp: Unix timestamp de expiración (7 días desde ahora)
			const exp = Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60;
			const token = await jwt.sign({ id: usuario.id_usuario, correo: correo_institucional, exp }, env.JWT_SECRET || "default_secret_for_dev");
			return json({ ok: true, usuario: { id_usuario: usuario.id_usuario, correo_institucional, nombre: usuario.nombre, apellido: usuario.apellido, nickname: usuario.nickname }, token });
		}

		// POST /auth/google
		if (request.method === "POST" && url.pathname === "/auth/google") {
			let body: any;
			try { body = await request.json(); } catch { return json({ ok: false, error: "JSON invalido" }, { status: 400 }); }
			
			const idToken = body.id_token;
			if (!idToken) return json({ ok: false, error: "Token de Google requerido" }, { status: 400 });
			if (!env.GOOGLE_WEB_CLIENT_ID) {
				return json({ ok: false, error: "Google Sign-In no esta configurado" }, { status: 503 });
			}

			try {
				const verifyResp = await fetch(
					`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`,
				);
				if (!verifyResp.ok) {
					return json({ ok: false, error: "Token de Google inválido" }, { status: 401 });
				}
				const payload: any = await verifyResp.json();
				// Audience prevents accepting a valid Google token issued for another app.
				if (payload.aud !== env.GOOGLE_WEB_CLIENT_ID || payload.email_verified !== "true") {
					return json({ ok: false, error: "Token de Google inválido" }, { status: 401 });
				}
				
				const correo_institucional = typeof payload.email === "string" ? payload.email.toLowerCase() : "";
				if (!correo_institucional || !correo_institucional.endsWith("@unal.edu.co")) {
					return json({ ok: false, error: "Debe usar un correo institucional @unal.edu.co" }, { status: 403 });
				}

				const nombre = payload.given_name || payload.name || "Usuario";
				const apellido = payload.family_name || "";
				const foto_perfil = payload.picture || null;

				const existingUser = await env.unparche_db.prepare(
					`SELECT id_usuario, correo_institucional, nombre, apellido, nickname, foto_perfil FROM usuario WHERE correo_institucional = ?`
				).bind(correo_institucional).first<{ id_usuario: number, correo_institucional: string, nombre: string, apellido: string, nickname: string | null, foto_perfil: string | null }>();

				let idUsuario: number;
				let returnUser: any;

				if (existingUser) {
					idUsuario = existingUser.id_usuario;
					returnUser = existingUser;
				} else {
					let baseNickname = correo_institucional.split('@')[0];
					let nickname = baseNickname;
					let nicknameExists = await env.unparche_db.prepare(`SELECT id_usuario FROM usuario WHERE nickname = ?`).bind(nickname).first();
					if (nicknameExists) {
						nickname = `${baseNickname}_${Math.floor(Math.random() * 10000)}`;
					}

					const fakeHash = `GOOGLE_OAUTH_${crypto.randomUUID()}`;

					const result = await env.unparche_db.prepare(
						`INSERT INTO usuario (correo_institucional, contrasena_hash, nombre, apellido, foto_perfil, nickname, correo_verificado) VALUES (?, ?, ?, ?, ?, ?, 1)`
					).bind(correo_institucional, fakeHash, nombre, apellido, foto_perfil, nickname).run();

					idUsuario = result.meta.last_row_id;
					returnUser = {
						id_usuario: idUsuario,
						correo_institucional,
						nombre,
						apellido,
						nickname,
						foto_perfil
					};
				}

				const exp = Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60;
				const token = await jwt.sign({ id: idUsuario, correo: correo_institucional, exp }, env.JWT_SECRET || "default_secret_for_dev");

				return json({ ok: true, usuario: returnUser, token }, { status: existingUser ? 200 : 201 });
			} catch (e: any) {
				return json({ ok: false, error: "Error interno al verificar con Google" }, { status: 500 });
			}
		}

		// POST /auth/verificar-correo
		if (request.method === "POST" && url.pathname === "/auth/verificar-correo") {
			let body: any;
			try { body = await request.json(); } catch { return json({ ok: false, error: "JSON invalido" }, { status: 400 }); }
			const { correo_institucional, codigo } = body;
			if (!correo_institucional || !codigo) return json({ ok: false, error: "Datos requeridos" }, { status: 400 });

			const usuario = await env.unparche_db.prepare(
				`SELECT id_usuario, nombre, apellido, nickname FROM usuario WHERE correo_institucional = ?`
			).bind(correo_institucional.trim()).first<{ id_usuario: number, nombre: string, apellido: string, nickname: string | null }>();

			if (!usuario) return json({ ok: false, error: "Usuario no encontrado" }, { status: 404 });

			const registro = await env.unparche_db.prepare(
				`SELECT id_codigo, expira_en, usado FROM codigo_verificacion
				 WHERE id_usuario = ? AND codigo = ? AND tipo = 'registro'
				 ORDER BY fecha_creacion DESC LIMIT 1`
			).bind(usuario.id_usuario, codigo.trim()).first<{ id_codigo: number, expira_en: string, usado: number }>();

			if (!registro) return json({ ok: false, error: "Código inválido" }, { status: 400 });
			if (registro.usado) return json({ ok: false, error: "El código ya fue utilizado" }, { status: 400 });
			if (new Date(registro.expira_en) < new Date()) return json({ ok: false, error: "El código ha expirado" }, { status: 400 });

			await env.unparche_db.prepare(
				`UPDATE codigo_verificacion SET usado = 1 WHERE id_codigo = ?`
			).bind(registro.id_codigo).run();

			await env.unparche_db.prepare(
				`UPDATE usuario SET correo_verificado = 1 WHERE id_usuario = ?`
			).bind(usuario.id_usuario).run();

			const exp = Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60;
			const token = await jwt.sign({ id: usuario.id_usuario, correo: correo_institucional, exp }, env.JWT_SECRET || "default_secret_for_dev");

			return json({ ok: true, usuario: { id_usuario: usuario.id_usuario, correo_institucional, nombre: usuario.nombre, apellido: usuario.apellido, nickname: usuario.nickname }, token });
		}

		// POST /auth/reenviar-codigo
		if (request.method === "POST" && url.pathname === "/auth/reenviar-codigo") {
			let body: any;
			try { body = await request.json(); } catch { return json({ ok: false, error: "JSON invalido" }, { status: 400 }); }
			const { correo_institucional } = body;
			if (!correo_institucional) return json({ ok: false, error: "Correo requerido" }, { status: 400 });

			const usuario = await env.unparche_db.prepare(
				`SELECT id_usuario, correo_verificado FROM usuario WHERE correo_institucional = ?`
			).bind(correo_institucional.trim()).first<{ id_usuario: number, correo_verificado: number }>();

			// Responde ok siempre para no filtrar si el correo existe
			if (!usuario || usuario.correo_verificado) return json({ ok: true });

			// Invalidar códigos anteriores de registro
			await env.unparche_db.prepare(
				`UPDATE codigo_verificacion SET usado = 1 WHERE id_usuario = ? AND tipo = 'registro' AND usado = 0`
			).bind(usuario.id_usuario).run();

			const codigo = generarCodigo6Digitos();
			const expira = expirarEn(15);
			await env.unparche_db.prepare(
				`INSERT INTO codigo_verificacion (id_usuario, codigo, tipo, expira_en) VALUES (?, ?, 'registro', ?)`
			).bind(usuario.id_usuario, codigo, expira).run();

			if (env.RESEND_API_KEY) {
				try {
					await sendEmail(
						env.RESEND_API_KEY,
						correo_institucional.trim(),
						"Verifica tu correo en UNparche",
						buildEmailHtml("registro", codigo),
					);
				} catch (mailErr) {
					console.error("Error reenviando código:", mailErr);
				}
			}

			return json({ ok: true });
		}

		// POST /auth/olvide-password
		if (request.method === "POST" && url.pathname === "/auth/olvide-password") {
			let body: any;
			try { body = await request.json(); } catch { return json({ ok: false, error: "JSON invalido" }, { status: 400 }); }
			const { correo_institucional } = body;
			if (!correo_institucional) return json({ ok: false, error: "Correo requerido" }, { status: 400 });

			// Siempre responde ok para no revelar si el correo está registrado
			const usuario = await env.unparche_db.prepare(
				`SELECT id_usuario FROM usuario WHERE correo_institucional = ?`
			).bind(correo_institucional.trim()).first<{ id_usuario: number }>();

			if (usuario) {
				// Invalidar códigos de reset anteriores
				await env.unparche_db.prepare(
					`UPDATE codigo_verificacion SET usado = 1 WHERE id_usuario = ? AND tipo = 'reset_password' AND usado = 0`
				).bind(usuario.id_usuario).run();

				const codigo = generarCodigo6Digitos();
				const expira = expirarEn(15);
				await env.unparche_db.prepare(
					`INSERT INTO codigo_verificacion (id_usuario, codigo, tipo, expira_en) VALUES (?, ?, 'reset_password', ?)`
				).bind(usuario.id_usuario, codigo, expira).run();

				if (env.RESEND_API_KEY) {
					try {
						await sendEmail(
							env.RESEND_API_KEY,
							correo_institucional.trim(),
							"Restablece tu contraseña en UNparche",
							buildEmailHtml("reset_password", codigo),
						);
					} catch (mailErr) {
						console.error("Error enviando correo de reset:", mailErr);
					}
				}
			}

			return json({ ok: true });
		}

		// POST /auth/restablecer-password
		if (request.method === "POST" && url.pathname === "/auth/restablecer-password") {
			let body: any;
			try { body = await request.json(); } catch { return json({ ok: false, error: "JSON invalido" }, { status: 400 }); }
			const { correo_institucional, codigo, nueva_contrasena } = body;
			if (!correo_institucional || !codigo || !nueva_contrasena) return json({ ok: false, error: "Datos requeridos" }, { status: 400 });

			const usuario = await env.unparche_db.prepare(
				`SELECT id_usuario FROM usuario WHERE correo_institucional = ?`
			).bind(correo_institucional.trim()).first<{ id_usuario: number }>();

			if (!usuario) return json({ ok: false, error: "Código inválido o expirado" }, { status: 400 });

			const registro = await env.unparche_db.prepare(
				`SELECT id_codigo, expira_en, usado FROM codigo_verificacion
				 WHERE id_usuario = ? AND codigo = ? AND tipo = 'reset_password'
				 ORDER BY fecha_creacion DESC LIMIT 1`
			).bind(usuario.id_usuario, codigo.trim()).first<{ id_codigo: number, expira_en: string, usado: number }>();

			if (!registro || registro.usado) return json({ ok: false, error: "Código inválido o expirado" }, { status: 400 });
			if (new Date(registro.expira_en) < new Date()) return json({ ok: false, error: "El código ha expirado" }, { status: 400 });

			const hash = await bcrypt.hash(nueva_contrasena, 10);

			await env.unparche_db.prepare(
				`UPDATE usuario SET contrasena_hash = ? WHERE id_usuario = ?`
			).bind(hash, usuario.id_usuario).run();

			await env.unparche_db.prepare(
				`UPDATE codigo_verificacion SET usado = 1 WHERE id_codigo = ?`
			).bind(registro.id_codigo).run();

			return json({ ok: true });
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


		// -------------------------------------------------------------------------
		// Catalogs and groups
		// -------------------------------------------------------------------------
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
			const idUsuarioParam = url.searchParams.get("id_usuario");
			const idUsuario = idUsuarioParam === null ? null : Number(idUsuarioParam);

			if (idUsuarioParam !== null && !Number.isInteger(idUsuario)) {
				return json(
					{ ok: false, error: "id_usuario debe ser entero." },
					{ status: 400 }
				);
			}

			const relacionSelect = idUsuario === null
				? `0 AS es_miembro, 0 AS es_creador`
				: `MAX(CASE WHEN mu.id_usuario IS NOT NULL THEN 1 ELSE 0 END) AS es_miembro,
					MAX(CASE WHEN g.id_administrador = ? THEN 1 ELSE 0 END) AS es_creador`;
			const relacionJoin = idUsuario === null
				? ""
				: `LEFT JOIN membresia_grupo mu
					ON mu.id_grupo = g.id_grupo
					AND mu.id_usuario = ?
					AND mu.estado = 'ACTIVA'`;
			const gruposStatement = env.unparche_db
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
						COUNT(m.id_membresia) AS total_miembros,
						${relacionSelect}
					FROM grupo g
					JOIN usuario u ON u.id_usuario = g.id_administrador
					LEFT JOIN membresia_grupo m
						ON m.id_grupo = g.id_grupo
						AND m.estado = 'ACTIVA'
					${relacionJoin}
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
				);
			const grupos = idUsuario === null
				? await gruposStatement.all()
				: await gruposStatement.bind(idUsuario, idUsuario).all();

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

		if (request.method === "DELETE" && grupoMatch) {
			const idGrupo = Number(grupoMatch[1]);
			const idUsuario = Number(url.searchParams.get("id_usuario"));
			if (!Number.isInteger(idUsuario)) {
				return json({ ok: false, error: "id_usuario debe ser entero." }, { status: 400 });
			}
			const grupo = await env.unparche_db.prepare(
				`SELECT id_grupo, nombre, id_administrador FROM grupo WHERE id_grupo = ?`
			).bind(idGrupo).first<{ id_grupo: number; nombre: string; id_administrador: number }>();
			if (!grupo) return json({ ok: false, error: "Grupo no encontrado." }, { status: 404 });
			if (grupo.id_administrador !== idUsuario) {
				return json({ ok: false, error: "Solo el creador puede eliminar este grupo." }, { status: 403 });
			}
			await env.unparche_db.prepare(
				`DELETE FROM grupo WHERE id_grupo = ? AND id_administrador = ?`
			).bind(idGrupo, idUsuario).run();
			return json({ ok: true, message: "Grupo eliminado correctamente.", grupo });
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
						m.rol_grupo,
						m.estado,
						m.fecha_union
					FROM membresia_grupo m
					JOIN usuario u ON u.id_usuario = m.id_usuario
					WHERE m.id_grupo = ?
					AND m.estado = 'ACTIVA'
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
			return json(
				{ ok: false, error: "Solo puedes unirte a un grupo mediante una invitacion aceptada." },
				{ status: 403 }
			);
		}

		// Membership is invitation-only; direct joins above are rejected explicitly.
		const invitacionesGrupoMatch = url.pathname.match(/^\/grupos\/(\d+)\/invitaciones$/);
		if (request.method === "POST" && invitacionesGrupoMatch) {
			const idGrupo = Number(invitacionesGrupoMatch[1]);
			let body: CrearInvitacionGrupoBody;
			try { body = await request.json(); } catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}
			const idInvitador = toInteger(body.id_invitador);
			const correo = typeof body.correo_institucional === "string"
				? body.correo_institucional.trim().toLowerCase()
				: "";
			if (idInvitador === null || !correo) {
				return json({ ok: false, error: "id_invitador y correo_institucional son obligatorios." }, { status: 400 });
			}

			const grupo = await env.unparche_db.prepare(
				`SELECT id_grupo, id_administrador FROM grupo WHERE id_grupo = ?`
			).bind(idGrupo).first<{ id_grupo: number; id_administrador: number }>();
			if (!grupo) return json({ ok: false, error: "Grupo no encontrado." }, { status: 404 });
			if (grupo.id_administrador !== idInvitador) {
				return json({ ok: false, error: "Solo el creador del grupo puede enviar invitaciones." }, { status: 403 });
			}

			const invitado = await env.unparche_db.prepare(
				`SELECT id_usuario FROM usuario WHERE lower(correo_institucional) = ?`
			).bind(correo).first<{ id_usuario: number }>();
			if (!invitado) return json({ ok: false, error: "No existe un usuario con ese correo institucional." }, { status: 404 });
			if (invitado.id_usuario === idInvitador) {
				return json({ ok: false, error: "El creador ya pertenece al grupo." }, { status: 409 });
			}

			const membresia = await env.unparche_db.prepare(
				`SELECT id_membresia FROM membresia_grupo WHERE id_grupo = ? AND id_usuario = ? AND estado = 'ACTIVA'`
			).bind(idGrupo, invitado.id_usuario).first();
			if (membresia) return json({ ok: false, error: "El usuario ya pertenece al grupo." }, { status: 409 });

			const pendiente = await env.unparche_db.prepare(
				`SELECT id_invitacion_grupo FROM invitacion_grupo WHERE id_grupo = ? AND id_invitado = ? AND estado = 'PENDIENTE'`
			).bind(idGrupo, invitado.id_usuario).first();
			if (pendiente) return json({ ok: false, error: "El usuario ya tiene una invitacion pendiente." }, { status: 409 });

			const result = await env.unparche_db.prepare(
				`INSERT INTO invitacion_grupo (id_grupo, id_invitado, id_invitador) VALUES (?, ?, ?)`
			).bind(idGrupo, invitado.id_usuario, idInvitador).run();
			const invitacion = await selectInvitacionGrupoById(env.unparche_db, Number(result.meta.last_row_id));
			return json({ ok: true, message: "Invitacion enviada correctamente.", invitacion }, { status: 201 });
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
			const idUsuario = toInteger(body.id_usuario);
			if (!estado || !["ACEPTADA", "RECHAZADA"].includes(estado)) {
				return json({ ok: false, error: "estado debe ser ACEPTADA o RECHAZADA." }, { status: 400 });
			}
			if (idUsuario === null) {
				return json({ ok: false, error: "id_usuario es obligatorio." }, { status: 400 });
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
			if (invitacionActual.id_invitado !== idUsuario) {
				return json({ ok: false, error: "Solo el usuario invitado puede responder." }, { status: 403 });
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


		// -------------------------------------------------------------------------
		// Users and their event relationships
		// -------------------------------------------------------------------------
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

		// HU-24 intentionally includes soft-deleted rows produced by HU-36.
		// GET historial de eventos a los que asistio un usuario.
		const historialEventosUsuarioMatch = url.pathname.match(
			/^\/usuarios\/(\d+)\/eventos\/historial$/
		);

		if (request.method === "GET" && historialEventosUsuarioMatch) {
			const idUsuario = Number(historialEventosUsuarioMatch[1]);

			const usuario = await env.unparche_db
				.prepare("SELECT id_usuario FROM usuario WHERE id_usuario = ?")
				.bind(idUsuario)
				.first();

			if (!usuario) {
				return json({ ok: false, error: "Usuario no encontrado." }, { status: 404 });
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
						e.fecha_eliminacion,
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
						a.estado AS estado_asistencia,
						a.fecha_confirmacion
					FROM asistencia a
					JOIN evento e ON e.id_evento = a.id_evento
					JOIN usuario u ON u.id_usuario = e.id_organizador
					JOIN tipo_evento t ON t.id_tipo_evento = e.id_tipo_evento
					LEFT JOIN grupo g ON g.id_grupo = e.id_grupo
					WHERE a.id_usuario = ?
						AND a.estado = 'CONFIRMADA'
						AND e.estado != 'CANCELADO'
						AND datetime(e.fecha_fin) < datetime('now')
					ORDER BY datetime(e.fecha_fin) DESC`
				)
				.bind(idUsuario)
				.all();

			return json({
				ok: true,
				id_usuario: idUsuario,
				eventos: eventos.results,
			});
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

		// -------------------------------------------------------------------------
		// Event announcements
		// -------------------------------------------------------------------------
		const anunciosEventoMatch = url.pathname.match(/^\/eventos\/(\d+)\/anuncios$/);

		if (request.method === "GET" && anunciosEventoMatch) {
			const idEvento = Number(anunciosEventoMatch[1]);
			const evento = await env.unparche_db
				.prepare("SELECT id_evento FROM evento WHERE id_evento = ?")
				.bind(idEvento)
				.first();

			if (!evento) {
				return json({ ok: false, error: "Evento no encontrado." }, { status: 404 });
			}

			const anuncios = await env.unparche_db
				.prepare(
					`SELECT
						a.id_anuncio,
						a.contenido,
						a.fecha_publicacion,
						a.id_autor,
						u.nombre || ' ' || u.apellido AS autor_nombre,
						u.nickname AS autor_nickname,
						a.id_evento
					FROM anuncio a
					JOIN usuario u ON u.id_usuario = a.id_autor
					WHERE a.id_evento = ?
					ORDER BY datetime(a.fecha_publicacion) DESC, a.id_anuncio DESC`
				)
				.bind(idEvento)
				.all();

			return json({ ok: true, id_evento: idEvento, anuncios: anuncios.results });
		}

		if (request.method === "POST" && anunciosEventoMatch) {
			const idEvento = Number(anunciosEventoMatch[1]);
			let body: CrearAnuncioBody;
			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			const idAutor = toInteger(body.id_autor);
			const contenido = typeof body.contenido === "string" ? body.contenido.trim() : "";
			if (idAutor === null || !contenido) {
				return json({ ok: false, error: "id_autor y contenido son obligatorios." }, { status: 400 });
			}
			if (contenido.length > 1000) {
				return json({ ok: false, error: "El anuncio no puede superar 1000 caracteres." }, { status: 400 });
			}

			const evento = await env.unparche_db
				.prepare(
					`SELECT id_evento, titulo, estado, fecha_eliminacion, id_organizador
					FROM evento
					WHERE id_evento = ?`
				)
				.bind(idEvento)
				.first<{
					id_evento: number;
					titulo: string;
					estado: string;
					fecha_eliminacion: string | null;
					id_organizador: number;
				}>();

			if (!evento) {
				return json({ ok: false, error: "Evento no encontrado." }, { status: 404 });
			}
			if (evento.id_organizador !== idAutor) {
				return json({ ok: false, error: "Solo el organizador puede publicar anuncios." }, { status: 403 });
			}
			if (evento.fecha_eliminacion !== null || ["CANCELADO", "FINALIZADO"].includes(evento.estado)) {
				return json({ ok: false, error: "No se pueden publicar anuncios en un evento finalizado." }, { status: 409 });
			}

			const result = await env.unparche_db
				.prepare(
					`INSERT INTO anuncio (contenido, id_autor, id_evento)
					SELECT ?, ?, ?
					WHERE NOT EXISTS (
						SELECT 1 FROM anuncio WHERE id_evento = ?
					)`
				)
				.bind(contenido, idAutor, idEvento, idEvento)
				.run();
			if (Number(result.meta.changes ?? 0) === 0) {
				return json(
					{ ok: false, error: "El evento ya tiene un anuncio publicado." },
					{ status: 409 }
				);
			}
			const idAnuncio = Number(result.meta.last_row_id);
			const anuncio = await env.unparche_db
				.prepare(
					`SELECT
						a.id_anuncio,
						a.contenido,
						a.fecha_publicacion,
						a.id_autor,
						u.nombre || ' ' || u.apellido AS autor_nombre,
						u.nickname AS autor_nickname,
						a.id_evento
					FROM anuncio a
					JOIN usuario u ON u.id_usuario = a.id_autor
					WHERE a.id_anuncio = ?`
				)
				.bind(idAnuncio)
				.first();

			const destinatarios = await env.unparche_db
				.prepare(
					`SELECT u.correo_institucional
					FROM asistencia a
					JOIN usuario u ON u.id_usuario = a.id_usuario
					WHERE a.id_evento = ?
						AND a.estado = 'CONFIRMADA'
						AND a.notificaciones_activas = 1
						AND a.id_usuario != ?`
				)
				.bind(idEvento, idAutor)
				.all<{ correo_institucional: string }>();

			let notificacionesEnviadas = 0;
			if (env.RESEND_API_KEY && destinatarios.results.length > 0) {
				const deliveries = await Promise.allSettled(
					destinatarios.results.map((destinatario) => sendEmail(
						env.RESEND_API_KEY!,
						destinatario.correo_institucional,
						`Novedad en ${evento.titulo}`,
						buildAnnouncementEmailHtml(evento.titulo, contenido),
					))
				);
				notificacionesEnviadas = deliveries.filter((delivery) => delivery.status === "fulfilled").length;
			}

			return json(
				{
					ok: true,
					message: "Anuncio publicado correctamente.",
					anuncio,
					notificaciones_enviadas: notificacionesEnviadas,
				},
				{ status: 201 }
			);
		}


		// -------------------------------------------------------------------------
		// Event detail and organizer mutations
		// -------------------------------------------------------------------------
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
			const idUsuarioParam = url.searchParams.get("id_usuario");
			const idUsuario = idUsuarioParam === null ? null : Number(idUsuarioParam);

			if (idUsuario === null || !Number.isInteger(idUsuario)) {
				return json(
					{ ok: false, error: "id_usuario debe ser entero." },
					{ status: 400 }
				);
			}

			const eventoActual = await env.unparche_db
				.prepare(
					`SELECT
						id_evento,
						titulo,
						estado,
						fecha_eliminacion,
						id_organizador
					FROM evento
					WHERE id_evento = ?
					AND ${activeEventCondition}`
				)
				.bind(idEvento)
				.first();

			if (!eventoActual) {
				return json({ ok: false, error: "Evento no encontrado." }, { status: 404 });
			}

			if ((eventoActual as { id_organizador: number }).id_organizador !== idUsuario) {
				return json(
					{ ok: false, error: "Solo el creador puede eliminar este evento." },
					{ status: 403 }
				);
			}

			try {
				await env.unparche_db
					.prepare(
						`UPDATE evento
						SET
							estado = 'CANCELADO',
							fecha_eliminacion = CURRENT_TIMESTAMP
						WHERE id_evento = ?
						AND id_organizador = ?
						AND fecha_eliminacion IS NULL`
					)
					.bind(idEvento, idUsuario)
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

		// -------------------------------------------------------------------------
		// Attendance
		// -------------------------------------------------------------------------
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
				// The unique user-event pair turns repeated taps into an idempotent update.
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

		// PATCH notification preference for a confirmed attendance.
		const notificacionesAsistenciaMatch = url.pathname.match(
			/^\/eventos\/(\d+)\/asistencias\/(\d+)\/notificaciones$/
		);

		if (request.method === "PATCH" && notificacionesAsistenciaMatch) {
			const idEvento = Number(notificacionesAsistenciaMatch[1]);
			const idUsuario = Number(notificacionesAsistenciaMatch[2]);
			let body: ActualizarNotificacionesBody;
			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			if (typeof body.activas !== "boolean") {
				return json({ ok: false, error: "activas debe ser booleano." }, { status: 400 });
			}

			const asistencia = await env.unparche_db
				.prepare(
					`SELECT id_asistencia
					FROM asistencia
					WHERE id_evento = ? AND id_usuario = ? AND estado = 'CONFIRMADA'`
				)
				.bind(idEvento, idUsuario)
				.first();
			if (!asistencia) {
				return json({ ok: false, error: "Debes confirmar asistencia antes de activar avisos." }, { status: 409 });
			}

			await env.unparche_db
				.prepare(
					`UPDATE asistencia
					SET notificaciones_activas = ?
					WHERE id_evento = ? AND id_usuario = ?`
				)
				.bind(body.activas ? 1 : 0, idEvento, idUsuario)
				.run();

			return json({
				ok: true,
				id_evento: idEvento,
				id_usuario: idUsuario,
				notificaciones_activas: body.activas,
			});
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
					SET estado = 'CANCELADA', notificaciones_activas = 0
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

		// GET asistentes confirmados de un evento (/eventos/:id/asistencias)
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

			const asistencias = await env.unparche_db
				.prepare(
					`SELECT
						a.id_asistencia,
						a.id_usuario,
						u.nombre || ' ' || u.apellido AS usuario_nombre,
						u.nombre,
						u.apellido,
						u.nickname,
						u.carrera,
						u.informacion_personal,
						u.foto_perfil,
						a.id_evento,
						a.estado,
						a.fecha_confirmacion
					FROM asistencia a
					JOIN usuario u ON u.id_usuario = a.id_usuario
					WHERE a.id_evento = ?
					AND a.estado = 'CONFIRMADA'
					ORDER BY a.fecha_confirmacion DESC`
				)
				.bind(idEvento)
				.all();

			return json({
				ok: true,
				evento,
				total_confirmadas: asistencias.results.length,
				asistencias: asistencias.results,
			});
		}


		// -------------------------------------------------------------------------
		// Event collection routes
		// -------------------------------------------------------------------------
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
						NULL AS fecha_confirmacion,
						NULL AS notificaciones_activas`
				: `a.estado AS estado_asistencia,
						a.fecha_confirmacion,
						a.notificaciones_activas`;
			const asistenciaJoin = idUsuario === null
				? ""
				: `LEFT JOIN asistencia a
					ON a.id_evento = e.id_evento
					AND a.id_usuario = ?`;
			const visibilidadCondition = idUsuario === null
				? `e.visibilidad = 'PUBLICA'`
				: `(e.visibilidad = 'PUBLICA'
					OR e.id_organizador = ?
					OR (e.visibilidad = 'SOLO_GRUPO' AND EXISTS (
						SELECT 1 FROM membresia_grupo vm
						WHERE vm.id_grupo = e.id_grupo
						AND vm.id_usuario = ?
						AND vm.estado = 'ACTIVA'
					)))`;
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
			WHERE ${visibleEventHistoryConditionForAlias("e")}
			AND ${visibilidadCondition}
			ORDER BY e.fecha_inicio DESC`;
			const eventosStatement = env.unparche_db.prepare(eventosQuery);
			const eventos = idUsuario === null
				? await eventosStatement.all()
				: await eventosStatement.bind(idUsuario, idUsuario, idUsuario).all();

			return json({ ok: true, eventos: eventos.results });
		}


		// Creation remains after GET collection matching so each branch is explicit.
		// POST eventos
		if (request.method === "POST" && url.pathname === "/eventos") {
			let body: CrearEventoBody;

			try {
				body = await request.json();
			} catch {
				return json({ ok: false, error: "El body debe ser JSON valido." }, { status: 400 });
			}

			// Normalize the decoded DTO once before applying domain validation.
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

			if (visibilidad === "SOLO_GRUPO" && idGrupo === null) {
				return json({ ok: false, error: "Debes seleccionar un grupo para esta visibilidad." }, { status: 400 });
			}

			if (idGrupo !== null) {
				// Group events can only be created by an active member of that group.
				const membresia = await env.unparche_db.prepare(
					`SELECT id_membresia FROM membresia_grupo
					 WHERE id_grupo = ? AND id_usuario = ? AND estado = 'ACTIVA'`
				).bind(idGrupo, idOrganizador).first();
				if (!membresia) {
					return json({ ok: false, error: "Solo puedes asociar eventos a grupos a los que perteneces." }, { status: 403 });
				}
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
