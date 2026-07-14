/**
 * Test to verify bcryptjs and jose work correctly in Cloudflare Workers runtime
 */
import { describe, it, expect } from 'vitest';
import bcrypt from 'bcryptjs';
import * as jose from 'jose';

describe('Authentication Libraries Compatibility', () => {
	it('should hash and compare passwords with bcryptjs', async () => {
		const password = 'testPassword123';
		const saltRounds = 10;
		
		// Hash the password
		const hashedPassword = await bcrypt.hash(password, saltRounds);
		expect(hashedPassword).toBeTruthy();
		expect(hashedPassword).not.toBe(password);
		
		// Verify correct password
		const isMatch = await bcrypt.compare(password, hashedPassword);
		expect(isMatch).toBe(true);
		
		// Verify wrong password
		const isWrongMatch = await bcrypt.compare('wrongPassword', hashedPassword);
		expect(isWrongMatch).toBe(false);
	});

	it('should create and verify JWT tokens with jose', async () => {
		const secret = new TextEncoder().encode('test-secret-key-min-32-characters-long-for-hs256');
		const payload = { userId: 1, role: 'user' };
		
		// Create JWT
		const jwt = await new jose.SignJWT(payload)
			.setProtectedHeader({ alg: 'HS256' })
			.setIssuedAt()
			.setExpirationTime('2h')
			.sign(secret);
		
		expect(jwt).toBeTruthy();
		expect(typeof jwt).toBe('string');
		
		// Verify JWT
		const { payload: verifiedPayload } = await jose.jwtVerify(jwt, secret);
		expect(verifiedPayload.userId).toBe(payload.userId);
		expect(verifiedPayload.role).toBe(payload.role);
		expect(verifiedPayload.exp).toBeTruthy();
		expect(verifiedPayload.iat).toBeTruthy();
	});

	it('should reject invalid JWT tokens', async () => {
		const secret = new TextEncoder().encode('test-secret-key-min-32-characters-long-for-hs256');
		const wrongSecret = new TextEncoder().encode('wrong-secret-key-min-32-characters-long-for-test');
		
		// Create JWT with one secret
		const jwt = await new jose.SignJWT({ userId: 1 })
			.setProtectedHeader({ alg: 'HS256' })
			.setIssuedAt()
			.setExpirationTime('2h')
			.sign(secret);
		
		// Try to verify with wrong secret
		await expect(jose.jwtVerify(jwt, wrongSecret)).rejects.toThrow();
	});

	it('should reject expired JWT tokens', async () => {
		const secret = new TextEncoder().encode('test-secret-key-min-32-characters-long-for-hs256');
		
		// Create JWT that expires immediately
		const jwt = await new jose.SignJWT({ userId: 1 })
			.setProtectedHeader({ alg: 'HS256' })
			.setIssuedAt()
			.setExpirationTime('0s')
			.sign(secret);
		
		// Wait a bit to ensure it expires
		await new Promise(resolve => setTimeout(resolve, 100));
		
		// Try to verify expired token
		await expect(jose.jwtVerify(jwt, secret)).rejects.toThrow();
	});
});
