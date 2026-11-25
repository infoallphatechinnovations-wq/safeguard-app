const router = require('express').Router();
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const db = require('../db');
const { requireAuth, signToken } = require('../middleware/auth');
const { wrap, httpError, validEmail } = require('../util');

const pub = (u) => ({
  id: u.id, email: u.email, fullName: u.full_name, phone: u.phone,
  accountType: u.account_type, companyId: u.company_id,
});

const checkCredentials = ({ email, password, fullName }) => {
  if (!validEmail(email) || !fullName || !password || password.length < 8)
    throw httpError(400, 'A valid email, full name and a password of at least 8 characters are required');
};

const newJoinCode = () => crypto.randomBytes(4).toString('hex').toUpperCase();

// Individual signup, or staff signup when a company join code is supplied
router.post('/register', wrap(async (req, res) => {
  checkCredentials(req.body);
  const { email, password, fullName, phone, jobTitle, joinCode } = req.body;
  let companyId = null, type = 'individual';
  if (joinCode) {
    const c = await db.query('SELECT id FROM companies WHERE join_code=$1', [String(joinCode).trim().toUpperCase()]);
    if (!c.rows[0]) throw httpError(400, 'That company code is not valid');
    companyId = c.rows[0].id; type = 'corporate_staff';
  }
  const hash = await bcrypt.hash(password, 10);
  try {
    const r = await db.query(
      `INSERT INTO users(email, phone, password_hash, full_name, account_type, company_id, job_title)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [email.toLowerCase(), phone || null, hash, fullName, type, companyId, jobTitle || null]);
    res.status(201).json({ token: signToken(r.rows[0]), user: pub(r.rows[0]) });
  } catch (e) {
    if (e.code === '23505') throw httpError(409, 'An account with this email already exists');
    throw e;
  }
}));

// Corporate signup: creates the company and its first admin together
router.post('/register-company', wrap(async (req, res) => {
  checkCredentials(req.body);
  const { email, password, fullName, phone, jobTitle, company } = req.body;
  if (!company || !company.name) throw httpError(400, 'Company name is required');
  const hash = await bcrypt.hash(password, 10);
  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    const c = await client.query(
      `INSERT INTO companies(name, rc_number, industry, address, contact_email, contact_phone, join_code)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [company.name, company.rcNumber || null, company.industry || null, company.address || null,
       company.contactEmail || email, company.contactPhone || phone || null, newJoinCode()]);
    const u = await client.query(
      `INSERT INTO users(email, phone, password_hash, full_name, account_type, company_id, job_title)
       VALUES ($1,$2,$3,$4,'corporate_admin',$5,$6) RETURNING *`,
      [email.toLowerCase(), phone || null, hash, fullName, c.rows[0].id, jobTitle || null]);
    await client.query('COMMIT');
    res.status(201).json({ token: signToken(u.rows[0]), user: pub(u.rows[0]), joinCode: c.rows[0].join_code });
  } catch (e) {
    await client.query('ROLLBACK');
    if (e.code === '23505') throw httpError(409, 'An account with this email already exists');
    throw e;
  } finally { client.release(); }
}));

router.post('/login', wrap(async (req, res) => {
  const { email, password } = req.body;
  const r = await db.query('SELECT * FROM users WHERE email=$1', [String(email || '').toLowerCase()]);
  const u = r.rows[0];
  if (!u || !(await bcrypt.compare(String(password || ''), u.password_hash)))
    throw httpError(401, 'Incorrect email or password');
  res.json({ token: signToken(u), user: pub(u) });
}));

router.get('/me', requireAuth, wrap(async (req, res) => {
  const r = await db.query('SELECT * FROM users WHERE id=$1', [req.user.id]);
  if (!r.rows[0]) throw httpError(404, 'Account not found');
  res.json({ user: pub(r.rows[0]) });
}));

router.put('/push-token', requireAuth, wrap(async (req, res) => {
  await db.query('UPDATE users SET push_token=$1 WHERE id=$2', [req.body.token || null, req.user.id]);
  res.json({ ok: true });
}));

module.exports = router;
