require('dotenv').config()
const app = require('./app')
const { port } = require('./config')

app.listen(port, '0.0.0.0', () => {
  console.log(`Backend listening on http://0.0.0.0:${port}`)
})
