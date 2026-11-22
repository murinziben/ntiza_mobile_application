// Creates one verified, active user per role in the running emulators.
// Run after `firebase emulators:start`: node tool/emulator/seed_users.mjs
const PROJECT = process.env.FIREBASE_PROJECT ?? 'ntiza-e9af2';
const AUTH = 'http://localhost:9099';
const FS = `http://localhost:8080/v1/projects/${PROJECT}/databases/(default)/documents`;
const PASSWORD = 'Password123!';
const users = [
  ['farmer', 'Test Farmer'], ['owner', 'Test Owner'], ['expert', 'Dr. Test Expert'],
  ['agent', 'Test Agent'], ['admin', 'Test Admin'],
];
const j = (r) => r.json();
const post = (url, body, headers = {}) =>
  fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...headers }, body: JSON.stringify(body) }).then(j);

for (const [role, name] of users) {
  const email = `${role}@ntiza.test`;
  const { localId, error } = await post(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, { email, password: PASSWORD, displayName: name });
  if (error) { console.log(`${email}: ${error.message}`); continue; }
  await post(`${AUTH}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:update`, { localId, emailVerified: true }, { Authorization: 'Bearer owner' });
  const s = (v) => ({ stringValue: v });
  await fetch(`${FS}/users/${localId}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json', Authorization: 'Bearer owner' },
    body: JSON.stringify({ fields: { name: s(name), email: s(email), phone: s('0788000000'), district: s('Gasabo'), sector: s('Remera'), role: s(role), status: s('active'), createdAt: { timestampValue: new Date().toISOString() } } }),
  });
  console.log(`seeded ${email} (${role})`);
}
console.log(`Password for all: ${PASSWORD}`);
