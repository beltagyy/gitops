#!/usr/bin/env bash
# Create a new app from the template
# Usage: ./create-app.sh <app-name> <namespace> <image>

set -euo pipefail

APP_NAME="${1:?Usage: $0 <app-name> <namespace> <image>}"
NAMESPACE="${2:-default}"
IMAGE="${3:-nginx:latest}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
TARGET_DIR="$SCRIPT_DIR/$APP_NAME"

if [ -d "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR already exists"
  exit 1
fi

echo "Creating app: $APP_NAME in namespace: $NAMESPACE"

mkdir -p "$TARGET_DIR"

for file in deployment.yaml service.yaml ingress.yaml; do
  sed \
    -e "s/APP_NAME/$APP_NAME/g" \
    -e "s/NAMESPACE/$NAMESPACE/g" \
    -e "s|APP_IMAGE|$IMAGE|g" \
    -e "s|APP_NAME.example.com|$APP_NAME.example.com|g" \
    "$TEMPLATE_DIR/$file" > "$TARGET_DIR/$file"
done

echo "Created:"
ls -1 "$TARGET_DIR"
echo ""
echo "Next steps:"
echo "  1. Edit $TARGET_DIR/*.yaml for your app"
echo "  2. kubectl apply -R -f $TARGET_DIR/"
echo "  3. git add $TARGET_DIR/ && git commit -m 'feat: add $APP_NAME app'"
