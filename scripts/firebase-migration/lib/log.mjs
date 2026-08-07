// run-all.mjs dynamically imports every phase into the same process, and ES
// modules are cached by resolved URL — without resetting, this array (and
// therefore each phase's printed count) would leak across phases.
let fallbacks = [];

export function logFallback(entry) {
  fallbacks.push(entry);
  console.warn('  [fallback]', JSON.stringify(entry));
}

export function printSummary(label, processed) {
  console.log(`\n${label}: ${processed} row(s) processed, ${fallbacks.length} fallback(s) logged.`);
  if (fallbacks.length) console.table(fallbacks);
  fallbacks = [];
}
