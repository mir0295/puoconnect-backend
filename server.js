app.get('/refresh-token', async (req, res) => {
  try {
    // Jika parameter 'target' diberikan dalam URL, proses satu target sahaja.
    // Jika tiada, senaraikan semua jabatan untuk dikemas kini serentak.
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

      // Minta long-lived token (60 hari) daripada Meta
      const response = await axios.get('https://graph.facebook.com/v25.0/oauth/access_token', {
        params: {
          grant_type: 'fb_exchange_token',
          client_id: appId,
          client_secret: appSecret,
          fb_exchange_token: currentToken
        }
      });

      const newToken = response.data.access_token;

      // Simpan semula token baru ke Firestore
      await docRef.set({
        access_token: newToken,
        updated_at: FieldValue.serverTimestamp()
      }, { merge: true });

      results.push(`Token Facebook bagi [${targetConfig}] berjaya diperbaharui!`);
    }

    res.status(200).send(results.join('\n'));
  } catch (error) {
    console.error(error.response?.data || error);
    res.status(500).send('Gagal refresh token');
  }
});