import {
	env,
	createExecutionContext,
	waitOnExecutionContext,
	SELF,
} from "cloudflare:test";
import { describe, it, expect } from "vitest";
import worker from "../src/index";

// For now, you'll need to do something like this to get a correctly-typed
// `Request` to pass to `worker.fetch()`.
const IncomingRequest = Request<unknown, IncomingRequestCfProperties>;

describe("UNparche API worker", () => {
	it("responds with API metadata (unit style)", async () => {
		const request = new IncomingRequest("http://example.com");
		// Create an empty context to pass to `worker.fetch()`.
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		// Wait for all `Promise`s passed to `ctx.waitUntil()` to settle before running test assertions
		await waitOnExecutionContext(ctx);
		await expect(response.json()).resolves.toEqual({ ok: true, message: "UNparche API" });
	});

	it("responds with API metadata (integration style)", async () => {
		const response = await SELF.fetch("https://example.com");
		await expect(response.json()).resolves.toEqual({ ok: true, message: "UNparche API" });
	});

	it("lists groups", async () => {
		const grupos = [
			{
				id_grupo: 1,
				nombre: "Ajedrez UN",
				descripcion: "Grupo para jugar ajedrez en la universidad",
				categoria: "SOCIAL",
				es_oficial: 0,
				estado_verificacion: "NO_SOLICITADO",
				fecha_creacion: "2026-07-01 10:00:00",
				id_administrador: 1,
				administrador_nombre: "Daniel Lopez",
				total_miembros: 2,
			},
		];
		const request = new IncomingRequest("http://example.com/grupos");
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: () => ({
					all: async () => ({ results: grupos }),
				}),
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({ ok: true, grupos });
	});

	it("lists event types", async () => {
		const tiposEvento = [
			{ id_tipo_evento: 1, nombre: "ACADEMICO", icono_svg: null },
			{ id_tipo_evento: 2, nombre: "CULTURAL", icono_svg: null },
		];
		const request = new IncomingRequest("http://example.com/tipos-evento");
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: () => ({
					all: async () => ({ results: tiposEvento }),
				}),
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({ ok: true, tipos_evento: tiposEvento });
	});

	it("lists current events and up to six months of finalized history", async () => {
		const eventos = [
			{
				id_evento: 1,
				titulo: "Torneo de ajedrez",
				fecha_fin: "2026-07-10T16:00:00.000Z",
				fecha_eliminacion: null,
				chat_habilitado: 1,
			},
		];
		let sql = "";
		const request = new IncomingRequest("http://example.com/eventos");
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: (query: string) => {
					sql = query;

					return {
						all: async () => ({ results: eventos }),
						bind: () => ({
							all: async () => ({ results: eventos }),
						}),
					};
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(sql).toContain("e.fecha_eliminacion IS NULL OR e.estado = 'FINALIZADO'");
		expect(sql).toContain("datetime(e.fecha_fin) >= datetime('now', '-6 months')");
		await expect(response.json()).resolves.toEqual({ ok: true, eventos });
	});

	it("lists events with attendance status for a user", async () => {
		const eventos = [
			{
				id_evento: 1,
				titulo: "Torneo de ajedrez",
				estado_asistencia: "CONFIRMADA",
				fecha_confirmacion: "2026-07-02 20:30:00",
			},
		];
		let sql = "";
		let boundUserId: unknown = null;
		const request = new IncomingRequest("http://example.com/eventos?id_usuario=2");
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: (query: string) => {
					sql = query;

					return {
						bind: (idUsuario: unknown) => {
							boundUserId = idUsuario;

							return {
								all: async () => ({ results: eventos }),
							};
						},
					};
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(boundUserId).toBe(2);
		expect(sql).toContain("a.estado AS estado_asistencia");
		expect(sql).toContain("LEFT JOIN asistencia a");
		expect(sql).toContain("e.visibilidad = 'PUBLICA'");
		expect(sql).toContain("e.visibilidad = 'SOLO_GRUPO'");
		expect(sql).toContain("FROM membresia_grupo vm");
		expect(sql).toContain("vm.estado = 'ACTIVA'");
		await expect(response.json()).resolves.toEqual({ ok: true, eventos });
	});

	it("gets a group by id", async () => {
		const grupo = {
			id_grupo: 1,
			nombre: "Ajedrez UN",
			descripcion: "Grupo para jugar ajedrez en la universidad",
			categoria: "SOCIAL",
			es_oficial: 0,
			estado_verificacion: "NO_SOLICITADO",
			fecha_creacion: "2026-07-01 10:00:00",
			id_administrador: 1,
			administrador_nombre: "Daniel Lopez",
			total_miembros: 2,
		};
		const request = new IncomingRequest("http://example.com/grupos/1");
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: () => ({
					bind: () => ({
						first: async () => grupo,
					}),
				}),
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({ ok: true, grupo });
	});

	it("allows only the creator to delete a group", async () => {
		const group = { id_grupo: 1, nombre: "Ajedrez UN", id_administrador: 1 };
		const request = new IncomingRequest("http://example.com/grupos/1?id_usuario=2", { method: "DELETE" });
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: () => ({ bind: () => ({ first: async () => group }) }),
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };
		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(403);
		await expect(response.json()).resolves.toEqual({ ok: false, error: "Solo el creador puede eliminar este grupo." });
	});

	it("deletes a group when requested by its creator", async () => {
		const group = { id_grupo: 1, nombre: "Ajedrez UN", id_administrador: 1 };
		let prepareCall = 0;
		let deleteSql = "";
		const request = new IncomingRequest("http://example.com/grupos/1?id_usuario=1", { method: "DELETE" });
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: (query: string) => {
					prepareCall += 1;
					if (prepareCall === 1) return { bind: () => ({ first: async () => group }) };
					deleteSql = query;
					return { bind: () => ({ run: async () => ({ success: true }) }) };
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };
		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(200);
		expect(deleteSql).toContain("DELETE FROM grupo");
		await expect(response.json()).resolves.toEqual({ ok: true, message: "Grupo eliminado correctamente.", grupo: group });
	});

	it("creates a group and administrator membership", async () => {
		const grupo = {
			id_grupo: 2,
			nombre: "Programacion Competitiva",
			descripcion: "Entrenamientos y retos de programacion",
			categoria: "ACADEMICO",
			es_oficial: 0,
			estado_verificacion: "NO_SOLICITADO",
			fecha_creacion: "2026-07-02 21:10:00",
			id_administrador: 1,
			administrador_nombre: "Daniel Lopez",
			total_miembros: 1,
		};
		let prepareCall = 0;
		const request = new IncomingRequest("http://example.com/grupos", {
			method: "POST",
			body: JSON.stringify({
				nombre: "Programacion Competitiva",
				descripcion: "Entrenamientos y retos de programacion",
				categoria: "ACADEMICO",
				id_administrador: 1,
			}),
			headers: { "Content-Type": "application/json" },
		});
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: () => {
					prepareCall += 1;

					if (prepareCall === 1) {
						return {
							bind: () => ({
								run: async () => ({ meta: { last_row_id: 2 } }),
							}),
						};
					}

					if (prepareCall === 2) {
						return {
							bind: () => ({
								run: async () => ({ success: true }),
							}),
						};
					}

					return {
						bind: () => ({
							first: async () => grupo,
						}),
					};
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(201);
		await expect(response.json()).resolves.toEqual({
			ok: true,
			message: "Grupo creado correctamente.",
			grupo,
		});
	});

	it("blocks joining a group without an invitation", async () => {
		const request = new IncomingRequest("http://example.com/grupos/1/miembros", {
			method: "POST",
			body: JSON.stringify({ id_usuario: 2 }),
			headers: { "Content-Type": "application/json" },
		});
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, { unparche_db: {} as D1Database } as Env, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(403);
		await expect(response.json()).resolves.toEqual({
			ok: false,
			error: "Solo puedes unirte a un grupo mediante una invitacion aceptada.",
		});
	});

	it("allows only the group creator to invite a user", async () => {
		const request = new IncomingRequest("http://example.com/grupos/1/invitaciones", {
			method: "POST",
			body: JSON.stringify({ id_invitador: 2, correo_institucional: "user@unal.edu.co" }),
			headers: { "Content-Type": "application/json" },
		});
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: () => ({ bind: () => ({ first: async () => ({ id_grupo: 1, id_administrador: 1 }) }) }),
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };
		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(403);
		await expect(response.json()).resolves.toEqual({
			ok: false,
			error: "Solo el creador del grupo puede enviar invitaciones.",
		});
	});

	it("creates a pending invitation when the creator invites a registered user", async () => {
		const invitation = {
			id_invitacion_grupo: 8,
			estado: "PENDIENTE",
			id_grupo: 1,
			id_invitado: 2,
			id_invitador: 1,
			nombre: "Ajedrez UN",
			nombre_invitador: "Admin UN",
		};
		let prepareCall = 0;
		const request = new IncomingRequest("http://example.com/grupos/1/invitaciones", {
			method: "POST",
			body: JSON.stringify({ id_invitador: 1, correo_institucional: "user@unal.edu.co" }),
			headers: { "Content-Type": "application/json" },
		});
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: () => {
					prepareCall += 1;
					if (prepareCall === 1) return { bind: () => ({ first: async () => ({ id_grupo: 1, id_administrador: 1 }) }) };
					if (prepareCall === 2) return { bind: () => ({ first: async () => ({ id_usuario: 2 }) }) };
					if (prepareCall === 3 || prepareCall === 4) return { bind: () => ({ first: async () => null }) };
					if (prepareCall === 5) return { bind: () => ({ run: async () => ({ meta: { last_row_id: 8 } }) }) };
					return { bind: () => ({ first: async () => invitation }) };
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(201);
		await expect(response.json()).resolves.toEqual({
			ok: true,
			message: "Invitacion enviada correctamente.",
			invitacion: invitation,
		});
	});

	it("accepts an invitation and creates the active membership", async () => {
		const invitation = {
			id_invitacion_grupo: 8,
			estado: "ACEPTADA",
			id_grupo: 1,
			id_invitado: 2,
			id_invitador: 1,
		};
		let prepareCall = 0;
		let membershipSql = "";
		const request = new IncomingRequest("http://example.com/invitaciones-grupo/8", {
			method: "PATCH",
			body: JSON.stringify({ estado: "ACEPTADA", id_usuario: 2 }),
			headers: { "Content-Type": "application/json" },
		});
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: (query: string) => {
					prepareCall += 1;
					if (prepareCall === 1) {
						return { bind: () => ({ first: async () => ({ ...invitation, estado: "PENDIENTE" }) }) };
					}
					if (prepareCall === 2) return { bind: () => ({ run: async () => ({ success: true }) }) };
					if (prepareCall === 3) {
						membershipSql = query;
						return { bind: () => ({ run: async () => ({ success: true }) }) };
					}
					return { bind: () => ({ first: async () => invitation }) };
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(200);
		expect(membershipSql).toContain("INSERT OR IGNORE INTO membresia_grupo");
		expect(membershipSql).toContain("'MIEMBRO', 'ACTIVA'");
		await expect(response.json()).resolves.toEqual({ ok: true, invitacion: invitation });
	});

	it("gets an event by id", async () => {
		const evento = {
			id_evento: 1,
			titulo: "Torneo de ajedrez",
			descripcion: "Partidas amistosas",
			fecha_inicio: "2026-07-10 14:00:00",
			duracion_minutos: 120,
			fecha_fin: "2026-07-10 16:00:00",
			fecha_publicacion: "2026-07-01 10:00:00",
			fecha_eliminacion: null,
			latitud: 4.637,
			longitud: -74.083,
			visibilidad: "PUBLICA",
			chat_habilitado: 1,
			estado: "PROGRAMADO",
			id_organizador: 1,
			organizador_nombre: "Daniel Lopez",
			id_grupo: 1,
			grupo_nombre: "Ajedrez UN",
			id_tipo_evento: 4,
			tipo_evento_nombre: "SOCIAL",
			tipo_evento_icono: null,
		};
		const request = new IncomingRequest("http://example.com/eventos/1");
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: () => ({
					bind: () => ({
						first: async () => evento,
					}),
				}),
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({ ok: true, evento });
	});

	it("lists attended event history including lifecycle-archived events", async () => {
		const eventos = [
			{
				id_evento: 7,
				titulo: "Taller finalizado",
				fecha_fin: "2026-07-01 18:00:00",
				fecha_eliminacion: "2026-07-02 18:00:00",
				estado: "FINALIZADO",
				estado_asistencia: "CONFIRMADA",
			},
		];
		const queries: string[] = [];
		let prepareCall = 0;
		let boundUserId: unknown = null;
		const request = new IncomingRequest(
			"http://example.com/usuarios/2/eventos/historial"
		);
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: (query: string) => {
					queries.push(query);
					prepareCall += 1;

					if (prepareCall === 1) {
						return {
							bind: () => ({ first: async () => ({ id_usuario: 2 }) }),
						};
					}

					return {
						bind: (idUsuario: unknown) => {
							boundUserId = idUsuario;
							return { all: async () => ({ results: eventos }) };
						},
					};
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(boundUserId).toBe(2);
		expect(queries[1]).toContain("a.estado = 'CONFIRMADA'");
		expect(queries[1]).toContain("datetime(e.fecha_fin) < datetime('now')");
		expect(queries[1]).toContain("e.fecha_eliminacion");
		expect(queries[1]).not.toContain("e.fecha_eliminacion IS NULL");
		await expect(response.json()).resolves.toEqual({
			ok: true,
			id_usuario: 2,
			eventos,
		});
	});

	it("registers event attendance", async () => {
		const evento = {
			id_evento: 1,
			chat_habilitado: 1,
		};
		const asistencia = {
			id_asistencia: 1,
			id_usuario: 2,
			usuario_nombre: "Juan Perez",
			id_evento: 1,
			evento_titulo: "Torneo de ajedrez",
			estado: "CONFIRMADA",
			notificaciones_activas: 0,
			fecha_confirmacion: "2026-07-02 20:30:00",
		};
		let prepareCall = 0;
		const request = new IncomingRequest("http://example.com/eventos/1/asistencias", {
			method: "POST",
			body: JSON.stringify({ id_usuario: 2 }),
			headers: { "Content-Type": "application/json" },
		});
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: () => {
					prepareCall += 1;

					if (prepareCall === 1) {
						return {
							bind: () => ({
								first: async () => evento,
							}),
						};
					}

					if (prepareCall === 2) {
						return {
							bind: () => ({
								run: async () => ({ success: true }),
							}),
						};
					}

					return {
						bind: () => ({
							first: async () => asistencia,
						}),
					};
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(201);
		await expect(response.json()).resolves.toEqual({
			ok: true,
			message: "Asistencia registrada correctamente.",
			asistencia,
		});
	});

	it("lists only confirmed attendees with public profile data", async () => {
		const evento = { id_evento: 1, titulo: "Torneo de ajedrez" };
		const asistencias = [{
			id_asistencia: 1,
			id_usuario: 2,
			usuario_nombre: "Juan Perez",
			nombre: "Juan",
			apellido: "Perez",
			nickname: "juanp",
			carrera: "Ingenieria",
			informacion_personal: "Ajedrecista",
			foto_perfil: null,
			id_evento: 1,
			estado: "CONFIRMADA",
			fecha_confirmacion: "2026-07-02 20:30:00",
		}];
		let prepareCall = 0;
		let attendeesSql = "";
		const request = new IncomingRequest("http://example.com/eventos/1/asistencias");
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: (query: string) => {
					prepareCall += 1;
					if (prepareCall === 1) {
						return { bind: () => ({ first: async () => evento }) };
					}
					attendeesSql = query;
					return { bind: () => ({ all: async () => ({ results: asistencias }) }) };
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		const response = await worker.fetch(request, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(attendeesSql).toContain("a.estado = 'CONFIRMADA'");
		expect(attendeesSql).not.toContain("u.correo_institucional");
		await expect(response.json()).resolves.toEqual({
			ok: true,
			evento,
			total_confirmadas: 1,
			asistencias,
		});
	});

	it("prunes events that ended more than 24 hours ago on schedule", async () => {
		let sql = "";
		const ctx = createExecutionContext();
		const testEnv = {
			unparche_db: {
				prepare: (query: string) => {
					sql = query;

					return {
						run: async () => ({ success: true, meta: { changes: 2 } }),
					};
				},
			} as unknown as D1Database,
		} as Env & { unparche_db: D1Database };

		await worker.scheduled?.({} as ScheduledController, testEnv, ctx);
		await waitOnExecutionContext(ctx);

		expect(sql).toContain("estado = 'FINALIZADO'");
		expect(sql).toContain("fecha_eliminacion = CURRENT_TIMESTAMP");
		expect(sql).toContain("chat_habilitado = 0");
		expect(sql).toContain("datetime(fecha_fin) <= datetime('now', '-24 hours')");
	});
});
