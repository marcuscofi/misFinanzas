#!/bin/sh
set -e

requeridas="FIREBASE_API_KEY FIREBASE_APP_ID FIREBASE_MESSAGING_SENDER_ID FIREBASE_PROJECT_ID FIREBASE_AUTH_DOMAIN FIREBASE_STORAGE_BUCKET E2EE_KEY"
faltantes=""
for variable in $requeridas; do
  if [ -z "$(printenv "$variable" || true)" ]; then
    faltantes="$faltantes $variable"
  fi
done

if [ -n "$faltantes" ]; then
  echo "ERROR: faltan variables de entorno:$faltantes" >&2
  echo "Configúralas en Vercel (Production, Preview y Development) antes de desplegar." >&2
  exit 1
fi

if [ ! -d flutter-sdk ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter-sdk
fi

flutter-sdk/bin/flutter build web --release \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
  --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
  --dart-define=E2EE_KEY="$E2EE_KEY"