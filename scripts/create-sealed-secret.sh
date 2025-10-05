#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="${REPO_ROOT}/manifests/secrets"

# Auto-detect kubeconfig
if [ -z "$KUBECONFIG" ]; then
    # Try common locations
    if [ -f "/etc/rancher/k3s/k3s.yaml" ]; then
        # Running on k3s server
        export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
        echo -e "${YELLOW}Using k3s config: /etc/rancher/k3s/k3s.yaml${NC}"
    elif [ -f "$HOME/.kube/config" ]; then
        # Standard kubectl config
        export KUBECONFIG="$HOME/.kube/config"
        echo -e "${YELLOW}Using kubectl config: ~/.kube/config${NC}"
    else
        # Use kubectl's default behavior (uses current context)
        echo -e "${YELLOW}Using kubectl default configuration${NC}"
    fi
else
    echo -e "${YELLOW}Using KUBECONFIG: $KUBECONFIG${NC}"
fi
echo ""

echo -e "${GREEN}=== Sealed Secret Generator ===${NC}"
echo ""

# 1. Get secret name
read -p "Enter secret name (e.g., postgres-secret): " SECRET_NAME
if [ -z "$SECRET_NAME" ]; then
    echo -e "${RED}Error: Secret name is required${NC}"
    exit 1
fi

# 2. Get namespace
read -p "Enter namespace (e.g., movie, db): " NAMESPACE
if [ -z "$NAMESPACE" ]; then
    echo -e "${RED}Error: Namespace is required${NC}"
    exit 1
fi

# 3. Get scope
echo ""
echo "Select scope:"
echo "  1) namespace-wide (recommended)"
echo "  2) strict"
echo "  3) cluster-wide"
read -p "Enter choice [1-3] (default: 1): " SCOPE_CHOICE
SCOPE_CHOICE=${SCOPE_CHOICE:-1}

case $SCOPE_CHOICE in
    1) SCOPE="namespace-wide" ;;
    2) SCOPE="strict" ;;
    3) SCOPE="cluster-wide" ;;
    *)
        echo -e "${RED}Invalid choice. Using namespace-wide.${NC}"
        SCOPE="namespace-wide"
        ;;
esac

# 4. Collect secret data
echo ""
echo -e "${YELLOW}Enter secret data (key=value format, empty line to finish):${NC}"
declare -A SECRET_DATA
while true; do
    read -p "  " KEY_VALUE
    if [ -z "$KEY_VALUE" ]; then
        break
    fi

    # Parse key=value
    if [[ "$KEY_VALUE" =~ ^([^=]+)=(.+)$ ]]; then
        KEY="${BASH_REMATCH[1]}"
        VALUE="${BASH_REMATCH[2]}"
        SECRET_DATA[$KEY]="$VALUE"
        echo -e "    ${GREEN}✓${NC} Added: $KEY"
    else
        echo -e "    ${RED}✗${NC} Invalid format. Use: key=value"
    fi
done

if [ ${#SECRET_DATA[@]} -eq 0 ]; then
    echo -e "${RED}Error: At least one secret key-value pair is required${NC}"
    exit 1
fi

# 5. Generate temporary secret YAML
TEMP_SECRET="/tmp/secret-${SECRET_NAME}-${NAMESPACE}.yaml"
cat > "$TEMP_SECRET" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
EOF

if [ "$SCOPE" = "namespace-wide" ] || [ "$SCOPE" = "cluster-wide" ]; then
    cat >> "$TEMP_SECRET" <<EOF
  annotations:
    sealedsecrets.bitnami.com/${SCOPE}: "true"
EOF
fi

cat >> "$TEMP_SECRET" <<EOF
type: Opaque
stringData:
EOF

for KEY in "${!SECRET_DATA[@]}"; do
    VALUE="${SECRET_DATA[$KEY]}"
    # Properly escape YAML special characters
    ESCAPED_VALUE=$(echo "$VALUE" | sed 's/"/\\"/g')
    echo "  ${KEY}: \"${ESCAPED_VALUE}\"" >> "$TEMP_SECRET"
done

# 6. Generate sealed secret
OUTPUT_FILE="${SECRETS_DIR}/sealed-${SECRET_NAME}-${NAMESPACE}.yaml"

echo ""
echo -e "${YELLOW}Generating sealed secret...${NC}"

if kubeseal -o yaml --scope "$SCOPE" \
    --controller-name sealed-secrets \
    --controller-namespace kube-system \
    < "$TEMP_SECRET" > "$OUTPUT_FILE"; then
    echo -e "${GREEN}✓ Sealed secret created: ${OUTPUT_FILE}${NC}"
else
    echo -e "${RED}Error: Failed to create sealed secret${NC}"
    echo -e "${RED}Tip: Make sure kubectl can access your cluster${NC}"
    echo -e "${RED}     Run 'kubectl cluster-info' to verify connection${NC}"
    rm -f "$TEMP_SECRET"
    exit 1
fi

# Cleanup
rm -f "$TEMP_SECRET"

# 7. Show summary
echo ""
echo -e "${GREEN}=== Summary ===${NC}"
echo "  Secret name: ${SECRET_NAME}"
echo "  Namespace: ${NAMESPACE}"
echo "  Scope: ${SCOPE}"
echo "  Keys: ${!SECRET_DATA[@]}"
echo "  Output: ${OUTPUT_FILE}"
echo ""

# 8. Ask to commit
read -p "Do you want to commit and push? [y/N]: " COMMIT_CHOICE
if [[ "$COMMIT_CHOICE" =~ ^[Yy]$ ]]; then
    cd "$REPO_ROOT"

    git add "$OUTPUT_FILE"

    read -p "Enter commit message (default: Add sealed secret ${SECRET_NAME} for ${NAMESPACE}): " COMMIT_MSG
    COMMIT_MSG=${COMMIT_MSG:-"Add sealed secret ${SECRET_NAME} for ${NAMESPACE}"}

    git commit -m "$COMMIT_MSG"

    read -p "Push to remote? [y/N]: " PUSH_CHOICE
    if [[ "$PUSH_CHOICE" =~ ^[Yy]$ ]]; then
        git push
        echo -e "${GREEN}✓ Changes pushed to remote${NC}"
    else
        echo -e "${YELLOW}⚠ Changes committed but not pushed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ File created but not committed${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
