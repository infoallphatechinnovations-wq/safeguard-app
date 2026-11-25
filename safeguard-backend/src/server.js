require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

if (!process.env.JWT_SECRET || !process.env.DATABASE_URL) {
  console.error('Missing JWT_SECRET or DATABASE_URL. Copy .env.example to .env and fill it in.');
  process.exit(1);
}

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => res.json({ ok: true }));
app.use('/api/auth', require('./routes/auth'));
app.use('/api', require('./routes/catalogue'));
app.use('/api', require('./routes/registrations'));
app.use('/api', require('./routes/company'));
app.use('/api', require('./routes/certificates'));
app.use('/api', require('./routes/admin'));

app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

// Central error handler: friendly messages for common database errors
app.use((err, _req, res, _next) => {
  if (err.status) return res.status(err.status).json({ error: err.message });
  if (err.code === '22P02' || err.code === '23503' || err.code === '23514' || err.code === '22007')
    return res.status(400).json({ error: 'One of the values you sent is not valid' });
  console.error(err);
  res.status(500).json({ error: 'Something went wrong on our side' });
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Safeguard API listening on port ${port}`));
