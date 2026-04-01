#!/usr/bin/env node
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const keyPath = path.resolve(__dirname, '..', 'serviceAccountKey.json');
if (!fs.existsSync(keyPath)) {
  console.error('serviceAccountKey.json not found at repo root:', keyPath);
  process.exit(1);
}

const serviceAccount = require(keyPath);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const phone = process.argv[2];
const name = process.argv[3] || 'Admin';
const role = process.argv[4] || 'admin';

if (!phone) {
  console.log('Usage: node scripts/create_admin.js +22570123456 "Admin Name" [role]');
  process.exit(1);
}

(async () => {
  try {
    const nowIso = new Date().toISOString();
    const payload = {
      phone,
      name,
      role,
      zone: '',
      activity: '',
      activityZone: '',
      created_at: nowIso,
      updated_at: nowIso,
      registrationDate: nowIso,
      hasPassword: true,
    };

    const docRef = db.collection('users').doc();
    await docRef.set(payload);
    console.log('Admin user created with id:', docRef.id);
    console.log('Phone:', phone);
    console.log('Name:', name);
    console.log('Role:', role);
    console.log('\nNow open the app and login with the phone and any non-empty password.');
    process.exit(0);
  } catch (e) {
    console.error('Error creating admin user:', e);
    process.exit(2);
  }
})();
