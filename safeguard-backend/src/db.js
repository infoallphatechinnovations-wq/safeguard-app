const { Pool, types } = require('pg');

// Return DATE columns as plain 'YYYY-MM-DD' strings so time zones can never shift a training date
types.setTypeParser(1082, (v) => v);
// Return BIGINT (prices in kobo) as numbers instead of strings
types.setTypeParser(20, (v) => parseInt(v, 10));

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
module.exports = { query: (text, params) => pool.query(text, params), pool };
