function cardNumber(value) {
  return String(value || '').replace(/\D/g, '')
}

module.exports = { cardNumber }