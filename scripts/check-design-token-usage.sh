#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

pattern='PoengjegerTheme\.|Color\(red:|UIColor\(red:|Color\.(primary|secondary|white|black|clear|red|green|blue|orange|yellow|gray)|\.foregroundStyle\(\.(primary|secondary|tertiary|white|black|red|green|blue|orange|yellow|gray)|\.font\(\.|\.padding\([^\n]*[,-] ?-?[0-9]|(HStack|VStack|LazyVStack|LazyHStack)\([^\n]*spacing: -?[0-9]|Spacer\(minLength: -?[0-9]|cornerRadius: -?[0-9]|opacity\([0-9.]|lineWidth: [0-9.]'

if violations=$(rg -n --glob '*.swift' --glob '!DesignTokens.swift' "$pattern" Poengjeger); then
    echo "Design-token violations found:"
    echo "$violations"
    echo
    echo "Use a named value from DesignTokens.swift instead."
    exit 1
fi

echo "Design-token usage check passed."
