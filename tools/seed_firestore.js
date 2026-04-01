/**
 * Seed Firestore from SQLite or JSON
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

/* ------------------ Firebase init ------------------ */
const keyPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(process.cwd(), 'serviceAccountKey.json');

if (!fs.existsSync(keyPath)) {
  console.error('❌ serviceAccountKey.json introuvable');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(keyPath)),
});

const firestore = admin.firestore();

/* ------------------ Helpers ------------------ */
function normalizeDate(value) {
  if (!value) return null;
  if (typeof value === 'number') return new Date(value);
  if (value._seconds) return new Date(value._seconds * 1000);
  const parsed = Date.parse(value);
  return isNaN(parsed) ? value : new Date(parsed);
}

async function seedCollection(name, rows) {
  if (!rows || !rows.length) return;
  const col = firestore.collection(name);

  for (const row of rows) {
    const id = row.id ? String(row.id) : undefined;
    const doc = id ? col.doc(id) : col.doc();

    const data = { ...row };
    delete data.id;

    for (const k of Object.keys(data)) {
      if (k.toLowerCase().includes('date')) {
        data[k] = normalizeDate(data[k]);
      }
    }

    console.log(`✔ ${name}/${doc.id}`);
    await doc.set(data);
  }
}

/* ------------------ SQLite read ------------------ */
function readSQLite(dbPath) {
  return new Promise((resolve) => {
    if (!fs.existsSync(dbPath)) return resolve(null);

    const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY);
    const tables = ['users', 'taxes', 'payments'];
    const out = {};
    let pending = tables.length;

    tables.forEach((t) => {
      db.all(`SELECT * FROM ${t}`, [], (err, rows) => {
        out[t] = err ? [] : rows;
        if (--pending === 0) {
          db.close();
          resolve(out);
        }
      });
    });
  });
}

/* ------------------ Main ------------------ */
(async () => {
  try {
    // Check several candidate paths for a local SQLite DB
    const candidates = [
      path.join(process.cwd(), 'backend', 'server.db'),
      path.join(process.cwd(), 'server.db'),
      path.join(process.cwd(), 'test_db.sqlite3'),
    ];

    let sqliteData = null;
    for (const p of candidates) {
      if (fs.existsSync(p)) {
        console.log('🔎 Found SQLite DB at', p);
        sqliteData = await readSQLite(p);
        break;
      }
    }

    if (sqliteData) {
      console.log('📦 SQLite détectée → migration Firestore');
      await seedCollection('users', sqliteData.users || []);
      await seedCollection('taxes', sqliteData.taxes || []);
      await seedCollection('payments', sqliteData.payments || []);
      console.log('🎉 Migration terminée');
      process.exit(0);
    }

    // Fallback: try to seed from bundled JSON if present
    const fallbackJson = path.join(process.cwd(), 'tools', 'seed_data.json');
    if (fs.existsSync(fallbackJson)) {
      const raw = fs.readFileSync(fallbackJson, 'utf8');
      const data = JSON.parse(raw);
      console.log('📦 Using fallback JSON seed data');
      await seedCollection('users', data.users || []);
      await seedCollection('taxes', data.taxes || []);
      await seedCollection('payments', data.payments || []);
      console.log('🎉 Fallback seeding complete');
      process.exit(0);
    }

    console.log('⚠️ Aucun source de données local trouvée (checked: backend/server.db, server.db, test_db.sqlite3, tools/seed_data.json)');
    process.exit(0);
  } catch (err) {
    console.error('❌ Erreur seed:', err);
    process.exit(1);
  }
})();
