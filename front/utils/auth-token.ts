export function normalizeToken(token: string | null | undefined): string | null {
  if (!token) {
    return null;
  }

  const normalized = token.replace(/^Bearer\s+/i, '').trim();
  return normalized.length > 0 ? normalized : null;
}

export function buildBearerToken(token: string | null | undefined): string | null {
  const normalized = normalizeToken(token);
  return normalized ? `Bearer ${normalized}` : null;
}