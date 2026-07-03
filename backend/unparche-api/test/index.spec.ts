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

	it("registers event attendance", async () => {
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
});
