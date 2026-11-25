# Safeguard API

Backend for the Safeguard Safety & Management Center mobile app (Node.js + PostgreSQL).

## Run it locally
```bash
cp .env.example .env        # set JWT_SECRET and the admin login
docker compose up -d        # PostgreSQL with schema.sql loaded
npm install
npm run seed                # loads courses/prices from the website and creates the admin
npm run dev                 # http://localhost:3000/health
```

## Endpoints (all under /api)

| Who | Method & path | Purpose |
|---|---|---|
| Public | GET /categories, /courses, /courses/:slug | Catalogue (`?category=`, `?q=`, `?international=true`) |
| Public | GET /sessions | Training calendar (`?from=&to=&category=`) |
| Public | GET /certificates/verify/:number, /certificates/verify-token/:token | Certificate verification (rate limited) |
| Public | POST /auth/register, /auth/register-company, /auth/login | Sign up (add `joinCode` for staff) and log in |
| Signed in | GET /auth/me, PUT /auth/push-token | Profile, device token |
| Signed in | POST /registrations, GET /registrations/mine, DELETE /registrations/:id | Register for a session, see and cancel bookings |
| Signed in | GET /certificates/mine | Certificates linked to the user |
| Company admin | POST /registrations/bulk | Register several staff for a session |
| Company admin | GET /company, /company/staff, /company/registrations | Company profile, join code, staff, bookings |
| Company admin | POST /quotes | Request in-company training or a quote |
| Safeguard admin | POST/PATCH /admin/courses, /admin/sessions | Publish courses and training dates |
| Safeguard admin | GET/PATCH /admin/registrations | Manage bookings and payment status |
| Safeguard admin | POST /admin/certificates, POST /admin/certificates/:number/revoke | Issue and revoke certificates |
| Safeguard admin | GET/PATCH /admin/quotes | Handle quote requests |

Send the token as `Authorization: Bearer <token>`. Prices are in kobo.

## Not built yet
Online payments (Paystack/Flutterwave), email and push notifications, certificate PDFs, and a web admin screen.
