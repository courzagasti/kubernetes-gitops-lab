const express = require('express');
const app = express();
app.get('/', (_req, res) => res.send('Hola desde Kubernetes GitOps - Version 2\n'));
app.get('/health', (_req, res) => res.status(200).json({status: 'ok'}));
app.listen(5000, '0.0.0.0', () => console.log('Escuchando en 5000'));
