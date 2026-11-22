// Seeds the running emulators with users in every role plus equipment for the owners.
// Run after `firebase emulators:start`: node tool/emulator/seed_users.mjs
// Safe to re-run: existing users are reused and owners are topped up to 3 machines.
const PROJECT = process.env.FIREBASE_PROJECT ?? 'ntiza-e9af2';
const AUTH = 'http://localhost:9099';
const DOCS = `http://localhost:8080/v1/projects/${PROJECT}/databases/(default)/documents`;
const PASSWORD = 'Password123!';
const MACHINES_PER_OWNER = 3;

// [email, name, role, district, sector]
const users = [
  ['farmer@ntiza.test', 'Test Farmer', 'farmer', 'Gasabo', 'Remera'],
  ['farmer2@ntiza.test', 'Farmer Two', 'farmer', 'Musanze', 'Muhoza'],
  ['farmer3@ntiza.test', 'Farmer Three', 'farmer', 'Huye', 'Ngoma'],
  ['farmer4@ntiza.test', 'Farmer Four', 'farmer', 'Rubavu', 'Gisenyi'],
  ['owner@ntiza.test', 'Test Owner', 'owner', 'Gasabo', 'Remera'],
  ['owner2@ntiza.test', 'Owner Two', 'owner', 'Huye', 'Ngoma'],
  ['expert@ntiza.test', 'Dr. Test Expert', 'expert', 'Gasabo', 'Remera'],
  ['agent@ntiza.test', 'Test Agent', 'agent', 'Gasabo', 'Remera'],
  ['admin@ntiza.test', 'Test Admin', 'admin', 'Gasabo', 'Remera'],
];

// Machines per owner email: [name, type, price, unit, about, specs]
const catalog = {
  'owner@ntiza.test': [
    ['John Deere 5050D', 'Tractor', 60000, 'hour', 'Reliable 50 HP tractor for ploughing and hauling.', [['Power', '50 HP'], ['Drive', '4WD']]],
    ['Kubota Rice Harvester', 'Harvester', 150000, 'day', 'Compact combine harvester for rice and wheat.', [['Cutting width', '2.0 m'], ['Fuel', 'Diesel']]],
    ['Precision Maize Planter', 'Planter', 25000, 'hectare', 'Four-row planter with seed spacing control.', [['Rows', '4'], ['Hopper', '60 L']]],
  ],
  'owner2@ntiza.test': [
    ['Massey Ferguson 290', 'Tractor', 55000, 'hour', 'Sturdy 80 HP tractor, good on hilly fields.', [['Power', '80 HP'], ['Drive', '2WD']]],
    ['Honda Water Pump', 'Pump', 8000, 'hour', 'Petrol irrigation pump with 3-inch outlet.', [['Outlet', '3 inch'], ['Flow', '1000 L/min']]],
    ['Maize Sheller 2000', 'Sheller', 30000, 'day', 'Mobile sheller, around 2 tonnes of maize per hour.', [['Output', '2 t/h'], ['Engine', 'Diesel']]],
  ],
};

const j = (r) => r.json();
const post = (url, body, headers = {}) =>
  fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...headers }, body: JSON.stringify(body) }).then(j);
const admin = { Authorization: 'Bearer owner' };
const s = (v) => ({ stringValue: v });
const i = (v) => ({ integerValue: String(v) });
const now = () => ({ timestampValue: new Date().toISOString() });

async function ensureUser(email, name) {
  const up = await post(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, { email, password: PASSWORD, displayName: name });
  if (!up.error) return { id: up.localId, created: true };
  const inn = await post(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`, { email, password: PASSWORD });
  if (inn.error) throw new Error(`${email}: ${inn.error.message}`);
  return { id: inn.localId, created: false };
}

async function equipmentCount(ownerId) {
  const rows = await post(`${DOCS}:runQuery`, {
    structuredQuery: {
      from: [{ collectionId: 'equipment' }],
      where: { fieldFilter: { field: { fieldPath: 'ownerId' }, op: 'EQUAL', value: s(ownerId) } },
    },
  }, admin);
  return rows.filter((r) => r.document).length;
}

for (const [email, name, role, district, sector] of users) {
  const { id, created } = await ensureUser(email, name);
  if (created) {
    await post(`${AUTH}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:update`, { localId: id, emailVerified: true }, admin);
    await fetch(`${DOCS}/users/${id}`, {
      method: 'PATCH',
      headers: { 'content-type': 'application/json', ...admin },
      body: JSON.stringify({ fields: { name: s(name), email: s(email), phone: s('0788000000'), district: s(district), sector: s(sector), role: s(role), status: s('active'), createdAt: now() } }),
    });
  }
  console.log(`${created ? 'seeded' : 'exists'} ${email} (${role})`);

  const machines = catalog[email];
  if (!machines) continue;
  const have = await equipmentCount(id);
  for (const [mName, type, price, unit, about, specs] of machines.slice(0, Math.max(0, MACHINES_PER_OWNER - have))) {
    await fetch(`${DOCS}/equipment`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...admin },
      body: JSON.stringify({ fields: {
        ownerId: s(id), ownerName: s(name), name: s(mName), type: s(type), district: s(district), sector: s(sector),
        price: i(price), unit: s(unit), inMaintenance: { booleanValue: false }, about: s(about), jobs: i(0), createdAt: now(),
        blockedDates: { arrayValue: {} },
        bookedDates: { arrayValue: {} },
        specs: { arrayValue: { values: specs.map(([k, v]) => ({ mapValue: { fields: { k: s(k), v: s(v) } } })) } },
      } }),
    });
    console.log(`  + ${mName} (${type})`);
  }
}
console.log(`Password for all: ${PASSWORD}`);
