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

(async () => {
  try {
    const snap = await db.collection('payments').get();
    console.log('Total payments in Firestore:', snap.size);
    if (snap.empty) {
      console.log('No payment documents found.');
    } else {
      snap.docs.slice(0, 20).forEach((d, i) => {
        const data = d.data();
        console.log(`--- Payment ${i+1} id=${d.id}`);
        console.log(JSON.stringify(data, null, 2));
      });
      if (snap.size > 20) console.log(`... (${snap.size - 20} more)`);
    }

    // Also show settings mapping payments_by_user if exists
    const settingsDoc = await db.collection('settings').doc('app').get();
    if (settingsDoc.exists) {
      const s = settingsDoc.data() || {};
      console.log('\nSettings.app:', JSON.stringify(s, null, 2));
      if (s.payments_by_user) {
        console.log('\nPayments_by_user mapping counts:');
        Object.entries(s.payments_by_user).forEach(([k,v]) => console.log(k, (v || []).length));
      }
    } else {
      console.log('\nNo settings.app document found.');
    }

    process.exit(0);
  } catch (e) {
    console.error('Error listing payments:', e);
    process.exit(2);
  }
})();
