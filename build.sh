#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_dir"

if [[ -x .venv/Scripts/resume-markdown.exe ]]; then
    resume_cli=.venv/Scripts/resume-markdown.exe
elif command -v resume-markdown >/dev/null 2>&1; then
    resume_cli=resume-markdown
else
    echo "resume-markdown is not installed." >&2
    echo "Run: python -m venv .venv && source .venv/Scripts/activate && python -m pip install ." >&2
    exit 1
fi

build_args=(build)
if [[ -n "${CHROME_PATH:-}" ]]; then
    build_args+=("--chrome-path=$CHROME_PATH")
fi

"$resume_cli" "${build_args[@]}"

mkdir -p docs
cp resume.html docs/index.html

echo "Built resume.html and resume.pdf; copied HTML to docs/index.html."
