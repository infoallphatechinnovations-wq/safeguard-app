// Loads categories and courses from the Safeguard website, and creates the first admin.
// Prices are in naira here and stored as kobo. Course titles that the site shortened were
// completed from their page addresses; review them in the admin tools before launch.
require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('../src/db');

const CATEGORIES = ['NEBOSH', 'ISO CQI/IRCA', 'HSE Professional', 'HSE Technical', 'Offshore', 'Management'];

// [category, title, slug, priceNaira | null (price on request)]
const COURSES = [
  ['NEBOSH', 'Health and Safety at Work', 'health-and-safety-at-work', 175000],
  ['NEBOSH', 'NEBOSH HSE Introduction to Incident Investigation', 'nebosh-hse-introduction-to-incident-investigation', 100000],
  ['NEBOSH', 'Managing Risks and Risk Assessment at Work', 'managing-risks-and-risk-assessment-at-work', 150000],
  ['NEBOSH', 'NEBOSH Certificate in Fire Safety', 'certificate-in-fire-safety', 220000],
  ['NEBOSH', 'Certificate in Environmental Management', 'certificate-in-environmental-management', 220000],
  ['NEBOSH', 'NEBOSH HSE Certificate in Process Safety Management', 'nebosh-hse-certificate-in-process-safety-management', 220000],
  ['NEBOSH', 'International General Certificate in Occupational Health and Safety', 'international-general-certificate-in-occupational-health-and-safety', 220000],
  ['NEBOSH', 'NEBOSH International Technical Certificate in Oil and Gas Operational Safety', 'international-technical-certificate-in-oil-and-gas-operational-safety', 220000],
  ['NEBOSH', 'NEBOSH HSE Certificate in Health and Safety Leadership Excellence', 'nebosh-hse-certificate-in-health-and-safety-leadership-excellence', 175000],
  ['NEBOSH', 'International Diploma in Occupational Health and Safety (3 Units)', 'international-diploma-in-occupational-health-and-safety-3-units', 400000],
  ['NEBOSH', 'International Diploma in Environmental Management', 'international-diploma-in-environmental-management', 600000],
  ['NEBOSH', 'NEBOSH Working with Wellbeing', 'nebosh-working-with-wellbeing', 150000],
  ['NEBOSH', 'NEBOSH HSE Certificate in Managing Stress at Work', 'nebosh-hse-certificate-in-managing-stress-at-work', 175000],
  ['NEBOSH', 'NEBOSH IIRSM Certificate in Managing Risk', 'nebosh-iirsm-certificate-in-managing-risk', null],
  ['NEBOSH', 'NEBOSH Health and Safety Management for Construction (International)', 'nebosh-health-and-safety-for-construction-international', 320000],

  ['ISO CQI/IRCA', 'ISO 9001:2015 Lead Auditor (QMS)', 'iso-9001-2015-lead-auditor', null],
  ['ISO CQI/IRCA', 'ISO 14001:2015 Lead Auditor (EMS)', 'iso-14001-2015-lead-auditor', null],
  ['ISO CQI/IRCA', 'ISO 45001:2018 Lead Auditor (OHSMS)', 'iso-45001-2018-lead-auditor', null],
  ['ISO CQI/IRCA', 'ISO 22000:2018 Lead Auditor (FSMS)', 'iso-22000-2018-lead-auditor', null],
  ['ISO CQI/IRCA', 'ISO 50001:2018 Lead Auditor (EnMS)', 'iso-50001-2018-lead-auditor', null],
  ['ISO CQI/IRCA', 'ISO 27001:2022 Lead Auditor (ISMS)', 'iso-27001-2022-lead-auditor', null],

  ['HSE Professional', 'Control of Substances Hazardous to Health (COSHH)', 'control-of-substances-hazardous-to-health-coshh', 30000],
  ['HSE Professional', 'Behavior Based Safety (BBS) Training', 'behavior-based-safety-bbs-training', 50000],
  ['HSE Professional', 'Bow-Tie / Fault Tree Analysis Program', 'bow-tiefault-tree-analysis-program', 85000],
  ['HSE Professional', 'Defensive Driving Training', 'defensive-driving-training', 30000],
  ['HSE Professional', 'Environmental Waste Management', 'environmental-waste-management', 40000],
  ['HSE Professional', 'Environmental Risk Control and Management', 'environmental-risk-control-and-management', 40000],
  ['HSE Professional', 'Food Handling Safety and Hygiene', 'food-handling-safety-and-hygiene', 40000],
  ['HSE Professional', 'Advanced Certificate Program (HSE-ACP)', 'advanced-certificate-program-hse-acp', 40000],
  ['HSE Professional', 'Incident / Accident Investigation', 'incidentaccident-investigation', 30000],
  ['HSE Professional', 'Journey Management Training', 'journey-management-training', 40000],

  ['HSE Technical', 'Basic Electrical Safety Training', 'basic-electrical-safety-training', 40000],
  ['HSE Technical', 'Confined Space and Gas Testing Training', 'confined-space-and-gas-testing-training', 70000],
  ['HSE Technical', 'Confined Space Entry and Permit to Work', 'confined-space-entry-and-permit-to-work', 40000],
  ['HSE Technical', 'Confined Space, Gas Testing and Breathing Apparatus Wearer Training', 'confined-space-gas-testing-and-breathing-apparatus-wearer-training', 100000],
  ['HSE Technical', 'Confined Space, BA Wearer and Emergency Evacuation', 'confined-space-ba-wearer-and-emergency-evacuation', 85000],
  ['HSE Technical', 'Crane, Sling and Rigging Safety', 'crane-sling-and-rigging-safety', 40000],
  ['HSE Technical', 'Forklift Safety Training', 'forklift-safety-training', 40000],
  ['HSE Technical', 'Gas Testing Training', 'gas-testing-training', 40000],
  ['HSE Technical', 'Gas Testing and Breathing Apparatus', 'gas-testing-and-breathing-apparatus', 70000],
  ['HSE Technical', 'Hydrogen Sulphide Safety Training', 'hydrogen-sulphide-safety-training', 35000],
  ['HSE Technical', 'Lift Truck, Empty Container Handler and Reach Stacker Safety', 'lift-truck-empty-container-handler-and-reach-stacker-safety', 60000],
  ['HSE Technical', 'Lockout and Tag-Out Training', 'lockout-and-tag-out-training', 30000],
  ['HSE Technical', 'Permit to Work System', 'permit-to-work-system', 35000],
  ['HSE Technical', 'Rig Floor Safety Course', 'rig-floor-safety-course', 50000],
  ['HSE Technical', 'Rigging Safety and Rigging Inspectors Course', 'rigging-safety-and-rigging-inspectors-course', 50000],
  ['HSE Technical', 'Working at Height Training', 'working-at-height-training', 35000],

  ['Offshore', 'Basic Offshore Safety Induction and Emergency Training (BOSIET)', 'basic-offshore-safety-induction-and-emergency-training-bosiet', 250000],
  ['Offshore', 'Helicopter Underwater Escape Training (HUET)', 'helicopter-underwater-escape-training-huet', 70000],
  ['Offshore', 'Survival at Sea (SAS) Training', 'survival-at-sea-sas-training', 250000],

  ['Management', 'Executive Stress Management Training', 'executive-stress-management-training', 75000],
  ['Management', 'Project Management Course', 'project-management-course-nigeria', 150000],
  ['Management', 'Supply Chain Management', 'supply-chain-management-nigeria', 150000],
  ['Management', 'Transport and Logistics Management Course', 'transport-and-logistics-management-course-nigeria', 150000],
];

(async () => {
  for (const [i, name] of CATEGORIES.entries())
    await db.query('INSERT INTO categories(name, sort) VALUES ($1,$2) ON CONFLICT (name) DO NOTHING', [name, i]);
  const cats = Object.fromEntries((await db.query('SELECT id, name FROM categories')).rows.map(r => [r.name, r.id]));

  for (const [cat, title, slug, naira] of COURSES)
    await db.query(
      `INSERT INTO courses(category_id, slug, title, price_kobo) VALUES ($1,$2,$3,$4)
       ON CONFLICT (slug) DO UPDATE SET title = EXCLUDED.title, price_kobo = EXCLUDED.price_kobo`,
      [cats[cat], slug, title, naira == null ? null : naira * 100]);
  console.log(`Seeded ${CATEGORIES.length} categories and ${COURSES.length} courses`);

  if (process.env.ADMIN_EMAIL && process.env.ADMIN_PASSWORD) {
    const hash = await bcrypt.hash(process.env.ADMIN_PASSWORD, 10);
    await db.query(
      `INSERT INTO users(email, password_hash, full_name, account_type, email_verified)
       VALUES ($1,$2,'Safeguard Admin','admin',true) ON CONFLICT (email) DO NOTHING`,
      [process.env.ADMIN_EMAIL.toLowerCase(), hash]);
    console.log(`Admin account ready: ${process.env.ADMIN_EMAIL}`);
  }
  await db.pool.end();
})().catch((e) => { console.error(e); process.exit(1); });
