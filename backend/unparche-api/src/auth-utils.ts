/**
 * Authentication Utilities Module
 * 
 * Provides secure password hashing and verification utilities for the UNparche API.
 * Uses bcryptjs for password hashing, compatible with Cloudflare Workers runtime.
 * 
 * Password Hashing Algorithm:
 * - Library: bcryptjs
 * - Cost Factor: 10 rounds
 * - Rationale: bcryptjs is fully compatible with Cloudflare Workers and provides
 *   secure password hashing without requiring native crypto APIs that may have
 *   limited support in the Workers environment.
 */

import bcrypt from 'bcryptjs';

/**
 * Hashes a plaintext password using bcryptjs with a cost factor of 10 rounds.
 * 
 * @param password - The plaintext password to hash
 * @returns A promise that resolves to the hashed password string
 * @throws Error if password is empty or hashing fails
 * 
 * @example
 * ```typescript
 * const hash = await hashPassword('mySecurePassword123');
 * // Returns: $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
 * ```
 * 
 * Requirements: 9.1, 9.2
 */
export async function hashPassword(password: string): Promise<string> {
	if (!password || typeof password !== 'string') {
		throw new Error('Password must be a non-empty string');
	}

	if (password.trim().length === 0) {
		throw new Error('Password cannot be empty or whitespace only');
	}

	try {
		const SALT_ROUNDS = 10;
		const hash = await bcrypt.hash(password, SALT_ROUNDS);
		return hash;
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		throw new Error(`Password hashing failed: ${message}`);
	}
}
