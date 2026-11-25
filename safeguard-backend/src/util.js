const httpError = (status, message) => Object.assign(new Error(message), { status });
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
const validEmail = (e) => typeof e === 'string' && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(e);

// Build a safe UPDATE from a fixed map of { bodyKey: columnName }
function buildUpdate(body, map) {
  const sets = [], vals = [];
  for (const [key, col] of Object.entries(map)) {
    if (body[key] !== undefined) { vals.push(body[key]); sets.push(`${col}=$${vals.length}`); }
  }
  return { sets, vals };
}

module.exports = { httpError, wrap, validEmail, buildUpdate };
