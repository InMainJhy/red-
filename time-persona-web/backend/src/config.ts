import path from 'node:path';
import { fileURLToPath } from 'node:url';

export interface AppConfig {
  port: number;
  backendRoot: string;
  databaseUrl: string;
}

const moduleDir = path.dirname(fileURLToPath(import.meta.url));

export function getConfig(): AppConfig {
  const parsed = Number(process.env.PORT);
  const port = Number.isFinite(parsed) && parsed > 0 ? parsed : 3030;
  return {
    port,
    backendRoot: path.resolve(moduleDir, '..'),
    databaseUrl: process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:5432/time_persona',
  };
}
