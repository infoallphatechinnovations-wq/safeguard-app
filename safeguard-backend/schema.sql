-- Safeguard Safety & Management Center: backend schema (PostgreSQL)
-- Money is stored in kobo (integer) to avoid rounding errors. NGN 175,000 = 17500000.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE account_type      AS ENUM ('individual', 'corporate_admin', 'corporate_staff', 'admin');
CREATE TYPE session_status    AS ENUM ('open', 'full', 'closed', 'cancelled');
CREATE TYPE reg_status        AS ENUM ('pending', 'confirmed', 'cancelled', 'completed', 'no_show');
CREATE TYPE payment_status    AS ENUM ('unpaid', 'pending', 'paid', 'refunded', 'invoiced');
CREATE TYPE certificate_state AS ENUM ('valid', 'expired', 'revoked');
CREATE TYPE quote_status      AS ENUM ('new', 'contacted', 'quoted', 'won', 'lost');

-- Companies (corporate accounts)
CREATE TABLE companies (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  rc_number     TEXT,                      -- CAC registration number (optional)
  industry      TEXT,
  address       TEXT,
  contact_email TEXT NOT NULL,
  contact_phone TEXT,
  join_code     TEXT UNIQUE,               -- staff can join a company with this code
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Users (individuals, company admins, company staff, Safeguard admins)
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT NOT NULL UNIQUE,
  phone         TEXT,
  password_hash TEXT NOT NULL,
  full_name     TEXT NOT NULL,
  account_type  account_type NOT NULL DEFAULT 'individual',
  company_id    UUID REFERENCES companies(id) ON DELETE SET NULL,
  job_title     TEXT,
  email_verified BOOLEAN NOT NULL DEFAULT false,
  push_token    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_users_company ON users(company_id);

-- Course catalogue
CREATE TABLE categories (
  id    SERIAL PRIMARY KEY,
  name  TEXT NOT NULL UNIQUE,              -- NEBOSH, ISO CQI/IRCA, HSE Technical, Offshore, Management...
  sort  INT NOT NULL DEFAULT 0
);

CREATE TABLE courses (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   INT NOT NULL REFERENCES categories(id),
  slug          TEXT NOT NULL UNIQUE,
  title         TEXT NOT NULL,
  summary       TEXT,
  description   TEXT,
  audience      TEXT,
  requirements  TEXT,
  duration_days INT,
  price_kobo    BIGINT,                    -- NULL = price on request
  delivery_mode TEXT NOT NULL DEFAULT 'classroom',   -- classroom | online | hybrid
  is_international BOOLEAN NOT NULL DEFAULT false,   -- overseas learners listing
  is_active     BOOLEAN NOT NULL DEFAULT true,
  image_url     TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_courses_category ON courses(category_id);

-- Scheduled training dates for a course (the training calendar)
CREATE TABLE course_sessions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id   UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  exam_date   DATE,
  location    TEXT,                        -- Port Harcourt | Lagos | Online
  capacity    INT,
  status      session_status NOT NULL DEFAULT 'open',
  CHECK (end_date >= start_date)
);
CREATE INDEX idx_sessions_start ON course_sessions(start_date);

-- Registrations. Corporate admins register staff who may not have app accounts,
-- so attendee details are stored on the row; user_id is optional.
CREATE TABLE registrations (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id     UUID NOT NULL REFERENCES course_sessions(id),
  registered_by  UUID NOT NULL REFERENCES users(id),
  user_id        UUID REFERENCES users(id),
  company_id     UUID REFERENCES companies(id),
  attendee_name  TEXT NOT NULL,
  attendee_email TEXT NOT NULL,
  attendee_phone TEXT,
  status         reg_status NOT NULL DEFAULT 'pending',
  payment_status payment_status NOT NULL DEFAULT 'unpaid',
  amount_kobo    BIGINT,
  notes          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (session_id, attendee_email)
);
CREATE INDEX idx_reg_company ON registrations(company_id);
CREATE INDEX idx_reg_user ON registrations(user_id);

CREATE TABLE payments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id UUID REFERENCES registrations(id),
  company_id    UUID REFERENCES companies(id),
  reference     TEXT NOT NULL UNIQUE,      -- gateway reference (Paystack/Flutterwave)
  amount_kobo   BIGINT NOT NULL,
  status        payment_status NOT NULL DEFAULT 'pending',
  paid_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Certificates and public verification
CREATE TABLE certificates (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  certificate_number TEXT NOT NULL UNIQUE,   -- what the person types or scans
  verify_token       TEXT NOT NULL UNIQUE,   -- random token embedded in the QR code
  registration_id    UUID REFERENCES registrations(id),
  holder_name        TEXT NOT NULL,
  course_title       TEXT NOT NULL,
  awarding_body      TEXT,                   -- NEBOSH | CQI/IRCA | Safeguard
  issued_on          DATE NOT NULL,
  expires_on         DATE,
  state              certificate_state NOT NULL DEFAULT 'valid',
  pdf_url            TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Corporate quote / in-company training requests
CREATE TABLE quote_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    UUID REFERENCES companies(id),
  requested_by  UUID REFERENCES users(id),
  course_id     UUID REFERENCES courses(id),
  course_text   TEXT,                       -- free text if course not in catalogue
  headcount     INT,
  preferred_dates TEXT,
  message       TEXT,
  status        quote_status NOT NULL DEFAULT 'new',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT,
  read       BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
