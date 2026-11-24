#!/usr/bin/env bash
# Usage: ./scripts/generate_keystore.sh <flavor>
#
# Creates the flavor's release (upload) keystore if it does not exist yet:
#   android/keystore/<flavor>/upload-keystore.jks
#   android/keystore/<flavor>/key.properties     (read by android/app/build.gradle.kts)
#   android/keystore/<flavor>/credentials.txt    (passwords + certificate hashes)
# All three are gitignored. An existing keystore is never overwritten: Play
# only accepts updates signed with the same upload key.
set -euo pipefail

cd "$(dirname "$0")/.."

FLAVOR="${1:-}"
CONFIG="config/flavors/$FLAVOR.json"
if [[ -z "$FLAVOR" || ! -f "$CONFIG" ]]; then
  echo "Usage: ./scripts/generate_keystore.sh <flavor>  (flavor must have $CONFIG)"
  exit 1
fi

KEY_DIR="android/keystore/$FLAVOR"
STORE_FILE="upload-keystore.jks"
ALIAS="upload"

if [[ -f "$KEY_DIR/key.properties" && -f "$KEY_DIR/$STORE_FILE" ]]; then
  echo "Keystore for $FLAVOR already exists ($KEY_DIR) - keeping it."
  exit 0
fi
if [[ -f "$KEY_DIR/$STORE_FILE" || -f "$KEY_DIR/key.properties" ]]; then
  echo "$KEY_DIR is incomplete (only one of $STORE_FILE / key.properties exists)."
  echo "Restore the missing file from your backup; refusing to create a new key over it."
  exit 1
fi

# keytool ships with Android Studio's bundled JDK even when no JDK is on PATH.
KEYTOOL=""
for candidate in \
  "${JAVA_HOME:-}/bin/keytool" \
  "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"; do
  if [[ -x "$candidate" ]]; then KEYTOOL="$candidate"; break; fi
done
if [[ -z "$KEYTOOL" ]] && command -v keytool >/dev/null && keytool -help >/dev/null 2>&1; then
  KEYTOOL="keytool"
fi
if [[ -z "$KEYTOOL" ]]; then
  echo "keytool not found. Install Android Studio or a JDK (or set JAVA_HOME)."
  exit 1
fi

APP_NAME="$(sed -nE 's/.*"APP_NAME"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' "$CONFIG" | head -n 1)"
APP_NAME="${APP_NAME:-$FLAVOR}"
# keytool treats commas in a DN as separators.
DN_NAME="${APP_NAME//,/ }"

# PKCS12 keystores use one password for store + key. Pass KEYSTORE_PASSWORD to
# choose it; otherwise a random per-flavor password is generated.
PASSWORD="${KEYSTORE_PASSWORD:-$(openssl rand -hex 24)}"

mkdir -p "$KEY_DIR"
"$KEYTOOL" -genkeypair -noprompt \
  -keystore "$KEY_DIR/$STORE_FILE" -storetype PKCS12 \
  -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASSWORD" -keypass "$PASSWORD" \
  -dname "CN=$DN_NAME, O=$DN_NAME" >/dev/null 2>&1

umask 077
cat > "$KEY_DIR/key.properties" <<EOF
storeFile=$STORE_FILE
storePassword=$PASSWORD
keyAlias=$ALIAS
keyPassword=$PASSWORD
EOF

CERT_SHA256="$("$KEYTOOL" -list -v -keystore "$KEY_DIR/$STORE_FILE" -storepass "$PASSWORD" -alias "$ALIAS" \
  | sed -nE 's/^[[:space:]]*SHA256:[[:space:]]*//p')"
CERT_SHA256_BASE64="$("$KEYTOOL" -exportcert -keystore "$KEY_DIR/$STORE_FILE" -storepass "$PASSWORD" -alias "$ALIAS" \
  | openssl dgst -sha256 -binary | base64)"

cat > "$KEY_DIR/credentials.txt" <<EOF
$APP_NAME ($FLAVOR) - Android upload keystore
Created: $(date '+%Y-%m-%d %H:%M')

Keystore file : $KEY_DIR/$STORE_FILE
Key alias     : $ALIAS
Store password: $PASSWORD
Key password  : $PASSWORD

Upload certificate SHA-256          : $CERT_SHA256
Upload certificate SHA-256 (base64) : $CERT_SHA256_BASE64

BACK UP this whole folder outside the repo. Losing it means asking Google
(Play App Signing) to reset the upload key before you can ship updates.
EOF

echo "Created keystore for $FLAVOR in $KEY_DIR"
echo "  Upload cert SHA-256: $CERT_SHA256"
echo "  Passwords + hashes : $KEY_DIR/credentials.txt  (back this folder up!)"
