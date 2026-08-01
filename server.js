const express = require('express');
const axios = require('axios');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Inisialisasi terus menggunakan objek JSON credentials
const serviceAccount = {
  "type": "service_account",
  "project_id": "puoconnect",
  "private_key_id": "e3f894d9de20d73a90d4e1a38ea67bb269a4a2d1",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC/nc2djNI8nn5J\nv6vmfCunrMWu17B302IumhuB3awBpWTe3w40mlQ5PkTG2onz3LS/Yl2HOveDF2v4\n11s0hyotUp1nRZWubVmqVw7W8opqv7HOHcvj0AvxsTZQSdOHc2NCE0XOn4TfjQ+L\nXOwc7Kas+REVHsHwaD24brW7I1jPh9gv6Kb6a80mzT7K9/n2ugvpgJFMrZ2DpJrj\nAYlpJCJoy8eBiB4P7jDnIO3EoYsUazUYCpMdrj3bjyH6SI2a3rm78EF1vkGXRx72\nagmSjJansh0oVqB+bfHEXdg9Jl8PofsMuAGIm910ZrFxNZJfqhB57IQhdvFDTNQP\nfRDcZRYdAgMBAAECggEACnMaoXrqhC/Ih1ESmNEwuEYtyaktkHtQoWX6Fgz2smhI\npfbYGXpJGY4Rxh5o44mnucAthZBrqxR96OYlrSmp3SriNp2O2iJQf3+b6ZD0h3nI\nworRca0I2bdmVN6R0JM0WIggiHIelupkbJ82qSUmucwjaFlzDh9BLmurMXduAnM3\n3dz4BnUs8Z89tcog6hHCPiQhvmv16Qma3I7sgEq1RWT3kvaBJZs2NoxufJS2t+84\nii3tZuo9pr+Uqo4n1ky0P0eRaEZOAq5Zlcqmi5J/MsAnNdXVkCvM3ZusM3k98BTr\nC1desDgmJ+Iq0TrWtjtRdXJAD9m7Oe44NP8/XSlHqQKBgQDrC/xkVlCGzjxZxCyP\nL/Xs5kOziRBpo7b6F5jItOmo/DK/ENQqdALjyR6E8Y2mIsxmDLGKMWRbTdb4Jt8x\nKkbaRqUFWr9icGnWPg9I80A4ibQos2mZO3+hb9tAceYGnMa2qERhNF3sZiLceoU7\nMLi7T7fohmMNLBRQc3Zwx23UPwKBgQDQsrCsZ9pHb1ShnztAEluFcs7abfe3mXsH\npCwUR2jrvF/yhubxc8gSr4MfjDkMSwRYCnRtSSUHA2NlsowASwVs2pb37SyM2g2K\n5QikYnuWU+cuC/yvuytEVsOAgRWNyeU26FyPT5kGr2fh5mHXCPo8nPmfCWZ5GiAm\njHMwK0SOowKBgEdwYirg7SK75i3maSCwFBAHwIX938Yr4z5KE77U9bvNw2K9K68n\niYVQKH2BqWrYYsWVkBSPhJAXrYHI1sdrsRNAq4FgHpE9130taZnjjR5iBCbmuO7A\n3b7kb4A73g0ec2sq43Wj4/Qo6umWN45Q9aTAywXaapqjTh1RqqsGgkQjAoGAeo2E\nTCnMN4i8BRDxhUWCcxIhQIm1Hx7E7Y7Nx7bLeSssmMn5Ui6wfbCNang4g+yFh4HU\nLtz2HnEx7GV16zIi5HJUlxCyyZ++tiKa+ZVPh86LgjHN2BAsbzwYIB0tYA8ASEcZ\nG5sdfJyCf1h/efwunmt79pVZlKHv4VM2zUGLR8sCgYAXMWcRi4YeBFJeGBkVf0Bo\ngWRN87Xl43hKWJFuiORvl3pPDhLNQIIkEs1j1nVk2nR+urrBfPp8VzB/ZwhiIYiv\nlX/SehEBKwD90SaAEQMcxTAYlGM6H3O0RWdf2tkfyw586SGQK25mRoxhHmkQluKv\HYjdVAJW3YnSdTZo/aaeQA==\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@puoconnect.iam.gserviceaccount.com",
  "client_id": "108889466657921182177",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40puoconnect.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();
const app = express();

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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server berjalan di port ${PORT}`);
});