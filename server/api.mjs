import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { randomBytes, pbkdf2Sync, createHash, timingSafeEqual } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import pg from 'pg';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PORT = Number(process.env.API_PORT ?? 8787);
const HOST = process.env.API_HOST ?? '127.0.0.1';
const MAX_BODY_BYTES = 10_000_000;

const AUTH_FAILURE_LIMIT = 10;
const AUTH_WINDOW_MS = 60_000;
const authFailures = new Map();

const PBKDF2_ITERATIONS = 150000;
const INT8_OID = 20;
const NUMERIC_OID = 1700;

function requestLog(req, status) {
  const origin = req.headers.origin ?? '-';
  console.log(
    `${new Date().toISOString()} ${req.method} ${req.url} -> ${status} origin=${origin}`,
  );
}

function isThrottled(ip) {
  const now = Date.now();
  const entry = authFailures.get(ip);
  if (!entry) return false;
  if (now - entry.firstAt > AUTH_WINDOW_MS) {
    authFailures.delete(ip);
    return false;
  }
  return entry.count >= AUTH_FAILURE_LIMIT;
}

function recordAuthFailure(ip) {
  const now = Date.now();
  const entry = authFailures.get(ip);
  if (!entry || now - entry.firstAt > AUTH_WINDOW_MS) {
    authFailures.set(ip, { count: 1, firstAt: now });
    return;
  }
  entry.count += 1;
}

function constantTimeEquals(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function loadEnvJson() {
  if (process.env.DATABASE_URL && process.env.API_BRIDGE_TOKEN) {
    return {
      DATABASE_URL: process.env.DATABASE_URL,
      API_BRIDGE_TOKEN: process.env.API_BRIDGE_TOKEN,
    };
  }
  const envFile = path.resolve(__dirname, '..', 'flutter', 'env.json');
  const json = JSON.parse(readFileSync(envFile, 'utf8'));
  return { DATABASE_URL: json.NEON_DATABASE_URL, API_BRIDGE_TOKEN: json.API_BRIDGE_TOKEN };
}

const { DATABASE_URL, API_BRIDGE_TOKEN } = loadEnvJson();

if (!DATABASE_URL) {
  console.error('NEON_DATABASE_URL missing from flutter/env.json (or DATABASE_URL).');
  process.exit(1);
}
if (!API_BRIDGE_TOKEN) {
  console.error(
    'API_BRIDGE_TOKEN missing from flutter/env.json.\n' +
      'Generate one with:\n' +
      "  node -e \"console.log(require('crypto').randomBytes(32).toString('hex'))\"\n" +
      'and add it as "API_BRIDGE_TOKEN" in flutter/env.json.',
  );
  process.exit(1);
}

const pool = new pg.Pool({
  connectionString: DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 5,
  idleTimeoutMillis: 120_000,
  connectionTimeoutMillis: 10_000,
  keepAlive: true,
});

pool.query('ALTER TABLE buildtrack_users ADD COLUMN IF NOT EXISTS avatar_url text').catch((err) => {
  console.log('Migration note:', err.message);
});

function hashPassword(password) {
  const salt = randomBytes(16);
  const hash = pbkdf2Sync(password, salt, PBKDF2_ITERATIONS, 32, 'sha256');
  return `pbkdf2-sha256$${PBKDF2_ITERATIONS}$${salt.toString('hex')}$${hash.toString('hex')}`;
}

function legacyHash(password, salt) {
  return createHash('sha256').update(`${salt}::${password}`).digest('hex');
}

function safeEqual(a, b) {
  const left = Buffer.from(String(a));
  const right = Buffer.from(String(b));
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

function verifyPassword(password, stored) {
  if (typeof stored !== 'string' || stored.length === 0) return false;
  if (stored.startsWith('pbkdf2-sha256$')) {
    const parts = stored.split('$');
    if (parts.length !== 4) return false;
    const iterations = Number.parseInt(parts[1], 10);
    if (!Number.isFinite(iterations) || iterations <= 0) return false;
    const expected = Buffer.from(parts[3], 'hex');
    if (expected.length === 0) return false;
    const actual = pbkdf2Sync(password, Buffer.from(parts[2], 'hex'), iterations, expected.length, 'sha256');
    return safeEqual(actual, expected);
  }
  const separator = stored.indexOf(':');
  if (separator < 0) return false;
  return safeEqual(legacyHash(password, stored.slice(0, separator)), stored.slice(separator + 1));
}

function isLegacyHash(stored) {
  return typeof stored === 'string' && !stored.startsWith('pbkdf2-sha256$');
}

function publicUser(row) {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    company: row.company ?? '',
    phone: row.phone ?? '',
    role: row.role ?? 'Project Manager',
    avatarUrl: row.avatar_url ?? null,
  };
}

class AuthError extends Error {
  constructor(message) {
    super(message);
    this.name = 'AuthError';
  }
}

async function handleSignIn(body) {
  const email = String(body?.email ?? '').trim().toLowerCase();
  const password = String(body?.password ?? '');
  if (!email || !password) throw new AuthError('Wrong email or password.');

  const { rows } = await pool.query(
    'select id::text as id, name, email, password_hash, company, phone, role, avatar_url from buildtrack_users where email = $1',
    [email],
  );
  if (rows.length === 0) throw new AuthError('Wrong email or password.');
  const row = rows[0];
  if (!verifyPassword(password, row.password_hash)) {
    throw new AuthError('Wrong email or password.');
  }

  if (isLegacyHash(row.password_hash)) {
    try {
      await pool.query('update buildtrack_users set password_hash = $1 where id = $2', [
        hashPassword(password),
        row.id,
      ]);
    } catch {
    }
  }

  delete row.password_hash;
  return { user: publicUser(row) };
}

async function handleSignUp(body) {
  const email = String(body?.email ?? '').trim().toLowerCase();
  const password = String(body?.password ?? '');
  const name = String(body?.name ?? '').trim();
  if (!email || !password || !name) throw new AuthError('All fields are required.');

  const existing = await pool.query('select 1 from buildtrack_users where email = $1', [email]);
  if (existing.rows.length > 0) {
    throw new AuthError('An account with this email already exists.');
  }

  const { rows } = await pool.query(
    'insert into buildtrack_users (name, email, password_hash, company, phone, role) '
      + 'values ($1, $2, $3, $4, $5, $6) returning id::text as id, name, email, company, phone, role, avatar_url',
    [
      name,
      email,
      hashPassword(password),
      String(body?.company ?? '').trim(),
      String(body?.phone ?? '').trim(),
      String(body?.role ?? 'Project Manager'),
    ],
  );
  return { user: publicUser(rows[0]) };
}

function digitsOnly(value) {
  return String(value ?? '').replace(/\D/g, '');
}

async function handleReset(body, ip) {
  const email = String(body?.email ?? '').trim().toLowerCase();
  const phone = digitsOnly(body?.phone);
  const password = String(body?.password ?? '');
  const mismatch = 'Email and phone number do not match any account.';

  if (isThrottled(ip)) {
    throw new AuthError('Too many attempts. Try again in a minute.');
  }
  if (!email || phone.length < 6) throw new AuthError(mismatch);
  if (password.length < 8) throw new AuthError('Password must be at least 8 characters.');

  const { rows } = await pool.query(
    'select id::text as id, name, email, company, phone, role, avatar_url from buildtrack_users where email = $1',
    [email],
  );
  const storedPhone = rows.length ? digitsOnly(rows[0].phone) : '';
  if (rows.length === 0 || storedPhone.length < 6 || storedPhone !== phone) {
    recordAuthFailure(ip);
    throw new AuthError(mismatch);
  }

  await pool.query('update buildtrack_users set password_hash = $1 where id = $2', [
    hashPassword(password),
    rows[0].id,
  ]);
  return { user: publicUser(rows[0]) };
}

function toPositional(sql, parameters) {
  const names = [...sql.matchAll(/@([A-Za-z_][A-Za-z0-9_]*)/g)].map((m) => m[1]);
  const seen = [];
  for (const name of names) {
    if (!(name in parameters)) {
      throw new Error(`Missing parameter "@${name}"`);
    }
    if (!seen.includes(name)) seen.push(name);
  }
  const positional = seen.map((name) => parameters[name]);
  const rewritten = sql.replace(/@([A-Za-z_][A-Za-z0-9_]*)/g, (_, name) => {
    return `$${seen.indexOf(name) + 1}`;
  });
  return { rewritten, positional };
}

function encodeValue(value, oid) {
  if (value === null || value === undefined) return { $t: 'null' };
  if (value instanceof Date) return { $t: 'datetime', v: value.toISOString() };
  if (oid === INT8_OID && typeof value === 'string') return { $t: 'bigint', v: value };
  if (oid === NUMERIC_OID && typeof value === 'string') return { $t: 'numeric', v: value };
  if (typeof value === 'bigint') return { $t: 'bigint', v: value.toString() };
  return value;
}

function encodeRow(row, fields) {
  const out = {};
  for (const field of fields) {
    out[field.name] = encodeValue(row[field.name], field.dataTypeID);
  }
  return out;
}

async function handleQuery(body) {
  const { sql, parameters } = body ?? {};
  if (typeof sql !== 'string' || sql.trim() === '') {
    throw new Error('Body must be { sql: string, parameters?: object }');
  }
  const { rewritten, positional } = toPositional(sql, parameters ?? {});
  const result = await pool.query(rewritten, positional);
  const rows = result.rows.map((row) => encodeRow(row, result.fields));
  return { rows, rowCount: result.rowCount };
}

function isAuthorized(req) {
  const header = req.headers.authorization ?? '';
  const match = /^Bearer (.+)$/.exec(header);
  if (!match) return false;
  return constantTimeEquals(match[1], API_BRIDGE_TOKEN);
}

function readBody(req, res, onComplete) {
  let raw = '';
  req.on('data', (chunk) => {
    raw += chunk;
    if (raw.length > MAX_BODY_BYTES) {
      res.writeHead(413, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Payload too large' }));
      requestLog(req, 413);
      req.destroy();
    }
  });
  req.on('end', () => onComplete(raw ? JSON.parse(raw) : {}));
}

const server = createServer((req, res) => {
  const clientIp = req.socket.remoteAddress ?? 'unknown';
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Vary', 'Origin');

  if (req.method === 'OPTIONS') {
    res.writeHead(204).end();
    requestLog(req, 204);
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host}`);
  const send = (status, payload) => {
    res.writeHead(status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(payload));
    requestLog(req, status);
  };

  if (req.method === 'GET' && url.pathname === '/health') {
    send(200, { ok: true, service: 'buildtrack-api' });
    return;
  }

  if (!isAuthorized(req)) {
    if (!isThrottled(clientIp)) recordAuthFailure(clientIp);
    send(401, { error: 'Unauthorized: missing or invalid bearer token.' });
    return;
  }
  if (isThrottled(clientIp)) {
    send(429, { error: 'Too many failed authentication attempts. Try again shortly.' });
    return;
  }

  if (req.method === 'POST' && url.pathname === '/query') {
    readBody(req, res, async (body) => {
      try {
        send(200, await handleQuery(body));
      } catch (err) {
        send(400, { error: String(err?.message ?? err) });
      }
    });
    return;
  }

  if (req.method === 'POST' && (url.pathname === '/auth/signin' || url.pathname === '/auth/signup')) {
    const isSignIn = url.pathname === '/auth/signin';
    readBody(req, res, async (body) => {
      try {
        const payload = isSignIn ? await handleSignIn(body) : await handleSignUp(body);
        send(200, payload);
      } catch (err) {
        if (err instanceof AuthError) {
          send(isSignIn ? 401 : 409, { error: err.message });
          return;
        }
        send(400, { error: String(err?.message ?? err) });
      }
    });
    return;
  }

  if (req.method === 'POST' && url.pathname === '/auth/reset') {
    readBody(req, res, async (body) => {
      try {
        send(200, await handleReset(body, clientIp));
      } catch (err) {
        if (err instanceof AuthError) {
          send(401, { error: err.message });
          return;
        }
        send(400, { error: String(err?.message ?? err) });
      }
    });
    return;
  }

  send(404, { error: 'Not found. Use POST /query, /auth/signin, /auth/signup or GET /health.' });
});

server.listen(PORT, HOST, () => {
  console.log(`buildtrack-api listening on http://${HOST}:${PORT} (auth required)`);
  pool
    .query('select 1')
    .then(() => console.log('database connection pool warm'))
    .catch((err) => console.error(`pool warm-up failed: ${err.message}`));
});
