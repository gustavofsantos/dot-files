#!/usr/bin/env bash
# Principle VII (security) + high-risk leads. Candidates only — confirm by reading.
# Usage: scan_security.sh <path>
set -euo pipefail
ROOT="${1:-.}"
command -v rg >/dev/null || { echo "ripgrep (rg) required"; exit 1; }
IGN=(-g '!**/node_modules/**' -g '!**/.git/**' -g '!**/*.lock' -g '!**/dist/**' -g '!**/build/**')
PII='cpf|cnpj|rg|email|telefone|celular|password|senha|token|secret|cartao|card_number|cvv|biometr|prontuario|saude'

scan () { echo; echo "== $1 =="; shift; rg -ni --no-heading "${IGN[@]}" "$@" "$ROOT" || echo "(none)"; }

# PII flowing into logs (most common real violation)
scan "PII into log/print statements" \
  -e "(log|logger|logging|println|console\.(log|error)|print|puts|fmt\.Print|System\.out)[^;\n]*($PII)"

# Secrets / PII hardcoded in config & fixtures
scan "PII/secret literals in config/fixtures" \
  -g '*.env*' -g '*.yml' -g '*.yaml' -g '*.json' -g '*config*' -g '*fixture*' -g '*seed*' \
  -e "($PII)\s*[:=]"

# PII in URLs / query strings (leaks to logs, referrers, history)
scan "PII in URL / query params" \
  -e "[?&]($PII)="

# Over-fetching
scan "SELECT * (minimization risk on PII tables)" -e "SELECT\s+\*"

# Errors exposing internals to clients
scan "Stack traces / raw errors returned to client" \
  -e "(printStackTrace|traceback|e\.getMessage|err\.Error\(\)|str\(e\))"

# Missing-at-rest hints: PII columns without crypto nearby is manual; flag crypto absence keywords
scan "Encryption references (presence = good; total absence near PII = review)" \
  -e "encrypt|bcrypt|argon2|pbkdf2|kms|aes|tls|hash" || true

echo
echo "NOTE: hits are leads. Read each in context before reporting as a finding."
