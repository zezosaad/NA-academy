import * as crypto from 'crypto';

const CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 32 chars (no I, O, 0, 1)

/**
 * Generates an automated cryptographic 12 char sequence matching regex `[A-Z2-9]{12}` cleanly
 */
export function generateRandomCode(length: number = 12): string {
  const bytes = crypto.randomBytes(length);
  let code = '';
  for (let i = 0; i < length; i++) {
    // We map 0-255 bounds directly onto our 32-charset space using modulo operations
    code += CHARSET[bytes[i] % 32];
  }
  return code;
}

/**
 * Returns a formatted visual separation: `XXXX-XXXX-XXXX`
 */
export function formatCode(code: string): string {
  return code.replace(/(.{4})/g, '$1-').slice(0, -1);
}

/**
 * Generate a bulk array resolving collisions natively.
 */
export function generateBatch(size: number, length: number = 12): string[] {
  const set = new Set<string>();
  while (set.size < size) {
    set.add(generateRandomCode(length));
  }
  return Array.from(set);
}

export function generateBatchId(): string {
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, ''); // yyyymmdd
  const rnd = crypto.randomBytes(2).toString('hex'); // 4 hex chars
  return `batch_${dateStr}_${rnd}`;
}
