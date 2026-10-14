import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

const app = express();
app.use(helmet());
const allowedOrigins = (process.env.CLIENT_URL ?? 'http://localhost:5173').split(',').map(x => x.trim());
app.use(cors({ origin: (origin, callback) => {
  if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
  return callback(new Error('Origin is not allowed by CORS'));
} }));
app.use(express.json({ limit: '1mb' }));
app.get('/api/health', (_req, res) => res.json({ ok: true, service: 'gamesphere-api', timestamp: new Date().toISOString() }));
app.get('/api', (_req, res) => res.json({ name: 'GameSphere API', version: '1.0.0', status: 'starter', docs: 'See docs/API.md' }));
app.use((req, res) => res.status(404).json({ error: 'Route not found', path: req.path }));
app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});
export default app;
