const express = require('express')
const cors = require('cors')
const fs = require('fs')
const path = require('path')
const productsRouter = require('./routes/products')
const imageProxyRouter = require('./routes/imageProxy')
const ordersRouter = require('./routes/orders')
const { eventsLogPath } = require('./services/logger')
const { notFoundHandler, errorHandler } = require('./middleware/errorHandler')

const app = express()
const frontendDistPath = path.join(__dirname, '../frontend/dist')
const hasFrontendDist = fs.existsSync(frontendDistPath)

app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }))
app.use(express.json())
app.use('/images', express.static(path.join(__dirname, 'public/images')))
app.use('/api/products', productsRouter)
app.use('/api/image', imageProxyRouter)
app.use('/api/orders', ordersRouter)
app.get('/api/health', (req, res) => res.json({ status: 'ok' }))
app.get('/api/logs/events', (req, res) => {
  const maxLines = Math.min(Math.max(Number(req.query.lines) || 200, 1), 1000)
  if (!fs.existsSync(eventsLogPath)) {
    return res.json({ ok: true, lines: [] })
  }

  const content = fs.readFileSync(eventsLogPath, 'utf8')
  const lines = content
    .split(/\r?\n/)
    .filter(Boolean)
    .slice(-maxLines)

  return res.json({ ok: true, lines })
})

if (hasFrontendDist) {
  app.use(express.static(frontendDistPath))
  app.get('*', (req, res) => {
    res.sendFile(path.join(frontendDistPath, 'index.html'))
  })
} else {
  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api')) return next()
    res.status(404).send('Frontend build not found. Run `npm run build` from the root before starting in production.')
  })
}

app.use(notFoundHandler)
app.use(errorHandler)

module.exports = app
