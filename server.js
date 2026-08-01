const express = require('express');
const axios = require('axios');
const app = express(); // 🌟 WAJIB ADA DI ATAS SEKALI

// Kod route anda di sini:
app.get('/refresh-token', async (req, res) => {
  try {
    const targets = req.query.target 
      ? [req.query.target] 
      : ['facebook_config', 'jabatan_teknologi_maklumat', 'jabatan_matematik_sains_komputer'];
    
    let results = [];
    const appId = '1535877565003029';
    const appSecret = 'e6f43c9650f47e54a2dcd1271af2719b';

    for (const targetConfig of targets) {
      const docRef = db.collection('settings').doc(targetConfig);
      const doc = await docRef.get();
      
      if (!doc.exists) {
        results.push(`Config ${targetConfig} not found`);
        continue;
      }
      
      const currentToken = doc.data().access_token;
      if (!currentToken) {
        results.push(`Token for ${targetConfig} is missing`);
        continue;
      }

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

      results.push(`Token Facebook bagi [${targetConfig}] berjaya diperbaharui!`);
    }

    // 🌟 Diubah kepada format JSON ringkas untuk elak ralat "output too large"
    res.status(200).json({ 
      success: true, 
      message: "Semua token berjaya diperbaharui!",
      details: results 
    });

  } catch (error) {
    console.error(error.response?.data || error);
    res.status(500).json({ success: false, error: 'Gagal refresh token' });
  }
});

// Jangan lupa untuk tetapkan port untuk server mendengar
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server berjalan di port ${PORT}`);
});