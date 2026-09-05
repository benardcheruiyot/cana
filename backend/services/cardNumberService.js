function maskCardNumber(value) {
  const digits = String(value || '').replace(/\D/g, '')
  if (!digits) return ''

  // const last4 = digits.slice(-4)
  // return `************${last4}`
}

/*
 * LEARNING ONLY - complete mask example:
 *
 * const unmaskedCardNumber = '4111111111111234'
 * const maskedCardNumber = maskCardNumber(unmaskedCardNumber)
 * // Result: "************1234"
 *
 * There is no valid unmaskCardNumber(maskedCardNumber) function. Masking
 * deletes the hidden digits, so they cannot be recovered.
 *
 * For reversible data, encryption and decryption are different operations:
 *
 * const crypto = require('crypto')
 * const key = crypto.randomBytes(32)
 * const iv = crypto.randomBytes(16)
 *
 * function encryptDemoValue(value) {
 *   const cipher = crypto.createCipheriv('aes-256-cbc', key, iv)
 *   return Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]).toString('hex')
 * }
 *
 * function decryptDemoValue(encryptedValue) {
 *   const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv)
 *   return Buffer.concat([
 *     decipher.update(Buffer.from(encryptedValue, 'hex')),
 *     decipher.final(),
 *   ]).toString('utf8')
 * }
 *
 * const encryptedDemoValue = encryptDemoValue('student-demo-value')
 * const originalDemoValue = decryptDemoValue(encryptedDemoValue)
 *
 * This encryption example is for harmless demo text only, not card numbers.
 */

module.exports = { maskCardNumber }