const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// --- USERS ---
app.get('/users', async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map(doc => doc.data());
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- TAXES ---
app.get('/taxes', async (req, res) => {
  try {
    const snapshot = await db.collection('taxes').get();
    const taxes = snapshot.docs.map(doc => doc.data());
    res.json(taxes);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- PAYMENTS ---
app.get('/payments', async (req, res) => {
  try {
    const snapshot = await db.collection('payments').get();
    const payments = snapshot.docs.map(doc => doc.data());
    res.json(payments);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- POST PAYMENT ---
app.post('/payments', async (req, res) => {
  try {
    const data = req.body;
    const ref = await db.collection('payments').add(data);
    res.json({ id: ref.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

exports.api = functions.https.onRequest(app);
