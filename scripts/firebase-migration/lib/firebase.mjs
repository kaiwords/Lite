import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { readFileSync } from 'node:fs';

let app;

function init(serviceAccountPath) {
  if (!app) {
    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
    app = getApps()[0] ?? initializeApp({ credential: cert(serviceAccount) });
  }
  return app;
}

export function firestore(serviceAccountPath) {
  init(serviceAccountPath);
  return getFirestore();
}

export function firebaseAuth(serviceAccountPath) {
  init(serviceAccountPath);
  return getAuth();
}

// Firestore timestamps come back as a Timestamp object with .toDate(); plain
// strings/nulls pass through as-is so this is safe to call on any field.
export function tsToIso(value) {
  if (value && typeof value.toDate === 'function') return value.toDate().toISOString();
  return value ?? null;
}
