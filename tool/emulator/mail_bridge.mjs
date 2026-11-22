// Forwards the Auth emulator's verification / password-reset links to Mailpit
// (SMTP localhost:1025) so they show up in the Mailpit inbox (localhost:8025).
// The Auth emulator itself never sends e-mail. Run: node tool/emulator/mail_bridge.mjs
import net from 'node:net';

const PROJECT = process.env.FIREBASE_PROJECT ?? 'ntiza-e9af2';
const AUTH = process.env.AUTH_EMULATOR ?? 'http://localhost:9099';
const SMTP_HOST = process.env.SMTP_HOST ?? 'localhost';
const SMTP_PORT = Number(process.env.SMTP_PORT ?? 1025);
const seen = new Set();

function sendMail(to, subject, body) {
  return new Promise((resolve, reject) => {
    const sock = net.connect(SMTP_PORT, SMTP_HOST);
    const steps = [
      'HELO ntiza.local',
      'MAIL FROM:<noreply@ntiza.local>',
      `RCPT TO:<${to}>`,
      'DATA',
      `From: NTIZA <noreply@ntiza.local>\r\nTo: ${to}\r\nSubject: ${subject}\r\n\r\n${body}\r\n.`,
      'QUIT',
    ];
    let i = -1;
    sock.setEncoding('utf8');
    sock.on('data', () => {
      i += 1;
      if (i < steps.length) sock.write(steps[i] + '\r\n');
      else sock.end();
    });
    sock.on('close', resolve);
    sock.on('error', reject);
  });
}

async function poll() {
  try {
    const res = await fetch(`${AUTH}/emulator/v1/projects/${PROJECT}/oobCodes`);
    const { oobCodes = [] } = await res.json();
    for (const c of oobCodes) {
      if (seen.has(c.oobCode)) continue;
      seen.add(c.oobCode);
      const subject = c.requestType === 'VERIFY_EMAIL' ? 'Verify your NTIZA e-mail' : 'Reset your NTIZA password';
      await sendMail(c.email, subject, `Open this link in a browser on your computer:\r\n\r\n${c.oobLink}`);
      console.log(`mailed ${c.requestType} -> ${c.email}`);
    }
  } catch (e) {
    console.error('bridge:', e.message);
  }
}

console.log(`Bridging ${AUTH} -> smtp://${SMTP_HOST}:${SMTP_PORT}`);
setInterval(poll, 1500);
