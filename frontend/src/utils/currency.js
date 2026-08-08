function normalizeCents(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount)) return 0;
  return amount;
}

export function formatCents(value, currencyPrefix) {
  const cents = normalizeCents(value);
  return `${currencyPrefix}${(cents / 100).toFixed(2)}`;
}

export function formatKShCents(value) {
  return formatCents(value, 'KSh');
}

export function formatRpCents(value) {
  return formatCents(value, 'Rp');
}
