/**
 * Test authentication libraries in actual Cloudflare Workers environment
 */
import { describe, it, expect, beforeAll } from 'vitest';
import { env, createExecutionContext, waitOnExecutionContext, SELF } from 'cloudflare:test';
import worker from '../src/index';

describe('Worker Authentication Libraries Compatibility', () => {
	it('should import bcryptjs in worker context', async () => {
		const bcrypt = await import('bcryptjs');
		expect(bcrypt.hash).toBeDefined();
		expect(bcrypt.compare).toBeDefined();
		expect(typeof bcrypt.hash).toBe('function');
	});

	it('should import jose in worker context', async () => {
		const jose = await import('jose');
		expect(jose.SignJWT).toBeDefined();
		expect(jose.jwtVerify).toBeDefined();
	});

	it('should hash password in worker context', async () => {
		const bcrypt = await import('bcryptjs');
		const password = 'testPassword123';
		const hash = await bcrypt.hash(password, 10);
		
		expect(hash).toBeTruthy();
		expect(hash.length).toBeGreaterThan(20);
		expect(hash).toMatch(/^\$2[aby]\$/); // bcrypt hash format
	});

	it('should create JWT in worker context', async () => {
		const jose = await import('jose');
		const secret = new TextEncoder().encode('test-secret-key-min-32-chars-long');
		
		const jwt = await new jose.SignJWT({ userId: 1, role: 'user' })
			.setProtectedHeader({ alg: 'HS256' })
			.setIssuedAt()
			.setExpirationTime('2h')
			.sign(secret);
		
		expect(jwt).toBeTruthy();
		expect(typeof jwt).toBe('string');
		expect(jwt.split('.')).toHaveLength(3); // JWT has 3 parts
	});
});
