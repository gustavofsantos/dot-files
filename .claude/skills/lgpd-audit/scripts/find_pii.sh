#!/usr/bin/env bash
# Seed a PII inventory. Candidates only — confirm by reading context.
# Usage: find_pii.sh <path>
set -euo pipefail
ROOT="${1:-.}"
RG="$(command -v rg || true)"
[ -z "$RG" ] && { echo "ripgrep (rg) required"; exit 1; }

# BR identifiers + common PII field names (PT/EN). Word-ish boundaries, case-insensitive.
PATTERNS='cpf|cnpj|\brg\b|\bpis\b|pasep|cns|titulo_eleitor|cep\b|rne|passaporte|passport|nis|nit|\bssn\b|email|e_mail|e-mail|phone|telefone|celular|whatsapp|address|endereco|logradouro|birth|nascimento|data_nasc|dob|full_name|nome_completo|first_name|last_name|sobrenome|gender|genero|sexo|race|raca|etnia|religion|religiao|health|saude|prontuario|diagnos|biometr|geolocation|geolocalizacao|lat(itude)?|lng|longitude|ip_address|device_id|account_number|conta|agencia|card_number|cartao|salary|salario|renda'

echo "== PII field candidates =="
rg -ni --no-heading -e "$PATTERNS" \
  -g '!**/node_modules/**' -g '!**/.git/**' -g '!**/*.lock' -g '!**/dist/**' -g '!**/build/**' \
  "$ROOT" || echo "(none found)"

echo
echo "== Schema / model definitions touching PII (review minimization) =="
rg -ni --no-heading -e "$PATTERNS" \
  -g '*.sql' -g '*migration*' -g '*schema*' -g '*model*' -g '*.proto' -g '*entity*' \
  "$ROOT" || echo "(none found)"
