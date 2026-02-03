const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');
const { exec } = require('child_process');

// CONFIG
const PORT = 8787;
const TARGET_URL = "https://marketsniper-api-3ygzdvszba-uc.a.run.app";

const app = express();

// 1. CORS Middleware (Permissive for Dev)
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Founder-Key', 'X-Autolearn-Enabled']
}));

// 2. Auth Injection Helper
const getIdentityToken = () => {
    return new Promise((resolve, reject) => {
        exec('gcloud auth print-identity-token', (error, stdout, stderr) => {
            if (error) {
                console.error(`[PROXY] gcloud Auth Error: ${error.message}`);
                reject(error);
                return;
            }
            if (stderr && !stdout) {
                console.warn(`[PROXY] gcloud stderr: ${stderr}`);
            }
            resolve(stdout.trim());
        });
    });
};

// 3. Proxy Middleware
const apiProxy = createProxyMiddleware({
    target: TARGET_URL,
    changeOrigin: true,
    secure: true, // Cloud Run uses HTTPS
    logLevel: 'debug',
    onProxyReq: async (proxyReq, req, res) => {
        console.log(`[PROXY] ${req.method} ${req.path} -> ...`);

        try {
            // Inject Token
            const token = await getIdentityToken();
            if (token) {
                proxyReq.setHeader('Authorization', `Bearer ${token}`);
            } else {
                console.warn("[PROXY] Warning: No token received from gcloud.");
            }
        } catch (err) {
            console.error("[PROXY] Failed to inject token:", err);
            // We verify stop conditions by letting it fail upstream if critical
        }
    },
    onProxyRes: (proxyRes, req, res) => {
        console.log(`[PROXY] ${req.method} ${req.path} -> ${proxyRes.statusCode}`);
    }
});

// 4. Routes
// Handle Health Check locally or pass through? Pass through to verify upstream.
app.use('/', apiProxy);

// 5. Start
app.listen(PORT, () => {
    console.log(`
=============================================
  MARKET SNIPER LOCAL PROXY
=============================================
  Listening: http://localhost:${PORT}
  Target:    ${TARGET_URL}
  Auth:      Auto-injecting gcloud identity token
=============================================
`);
});
