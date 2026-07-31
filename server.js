const express = require('express');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const axios = require('axios');

// Inisialisasi Firebase menggunakan pembolehubah individu yang lebih selamat
initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') : undefined
  })
});

const db = getFirestore();
const app = express();

app.use(express.json());

app.get('/refresh-token', async (req, res) => {
  try {
    const docRef = db.collection('settings').doc('facebook_config');
    const doc = await docRef.get();
    if (!doc.exists) return res.status(404).send('Config not found');
    
    const currentToken = doc.data().access_token;
    
    const appId = '1535877565003029';
    const appSecret = 'e6f43c9650f47e54a2dcd1271af2719b';

    const response = await axios.get('https://graph.facebook.com/v25.0/oauth/access_token', {
      params: {
        grant_type: 'fb_exchange_token',
        client_id: appId,
        client_secret: appSecret,
        fb_exchange_token: currentToken
      }
    });

    const newToken = response.data.access_token;

    await docRef.set({
      access_token: newToken,
      updated_at: FieldValue.serverTimestamp()
    }, { merge: true });

    res.status(200).send('Token Facebook berjaya diperbaharui!');
  } catch (error) {
    console.error(error);
    res.status(500).send('Gagal refresh token');
  }
});

app.get('/', (req, res) => {
  res.send('PuoConnect Backend is running successfully! 🚀');
});

app.get('/status', (req, res) => {
  res.status(200).json({ 
    status: 'Online', 
    message: 'Server Puoconnect Backend sedang aktif!',
    timestamp: new Date() 
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server berjalan di port ${PORT}`));