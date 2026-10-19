import { Pool } from 'pg';
import dotenv from 'dotenv';
import dns from 'dns';

dotenv.config();

// Ensure Node.js prioritizes IPv4 over IPv6 on environments without IPv6 routing like Render free tier
try {
  dns.setDefaultResultOrder('ipv4first');
} catch (_) {}

function getEffectiveConnectionString(): string {
  let conn =
    process.env.DATABASE_URL ||
    'postgresql://postgres.actqetxmyfdmoqyykwxj:henzsolo31012002!@aws-0-eu-west-1.pooler.supabase.com:5432/postgres';

  // If the direct Supabase IPv6-only hostname is passed in env, auto-translate to IPv4 pooler
  if (conn.includes('db.actqetxmyfdmoqyykwxj.supabase.co')) {
    console.log('🔄 Translating Supabase direct IPv6 connection to IPv4 connection pooler (eu-west-1)...');
    conn = conn
      .replace('db.actqetxmyfdmoqyykwxj.supabase.co', 'aws-0-eu-west-1.pooler.supabase.com')
      .replace('//postgres:', '//postgres.actqetxmyfdmoqyykwxj:');
  }

  return conn;
}

const connectionString = getEffectiveConnectionString();

export const pool = new Pool({
  connectionString,
  ssl: {
    rejectUnauthorized: false,
  },
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client', err);
});
