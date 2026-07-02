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
});
