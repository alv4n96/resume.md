#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_dir"

find_command() {
    local command_name
    for command_name in "$@"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            command -v "$command_name"
            return 0
        fi
    done
    return 1
}

find_path() {
    local candidate
    for candidate in "$@"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

if [[ -x .venv/Scripts/resume-markdown.exe ]]; then
    resume_cli=.venv/Scripts/resume-markdown.exe
elif [[ -x .venv/bin/resume-markdown ]]; then
    resume_cli=.venv/bin/resume-markdown
elif command -v resume-markdown >/dev/null 2>&1; then
    resume_cli=resume-markdown
else
    echo "resume-markdown is not installed." >&2
    echo "Create a virtual environment and install the project before running this script." >&2
    exit 1
fi

browser_path=""
browser_name=""

if [[ -n "${CHROME_PATH:-}" && -x "$CHROME_PATH" ]]; then
    browser_path="$CHROME_PATH"
elif browser_path="$(find_command google-chrome chrome chromium chromium-browser || true)" && [[ -n "$browser_path" ]]; then
    :
else
    browser_path="$(find_path \
        "${LOCALAPPDATA:-}/Google/Chrome/Application/chrome.exe" \
        "${PROGRAMFILES:-}/Google/Chrome/Application/chrome.exe" \
        "/c/Program Files/Google/Chrome/Application/chrome.exe" \
        "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
        "/usr/bin/google-chrome" \
        "/usr/bin/chromium" || true)"
fi

if [[ -n "$browser_path" ]]; then
    browser_name="Google Chrome"
else
    browser_path="$(find_command microsoft-edge microsoft-edge-stable msedge || true)"
    if [[ -z "$browser_path" ]]; then
        browser_path="$(find_path \
            "${LOCALAPPDATA:-}/Microsoft/Edge/Application/msedge.exe" \
            "${PROGRAMFILES:-}/Microsoft/Edge/Application/msedge.exe" \
            "/c/Program Files/Microsoft/Edge/Application/msedge.exe" \
            "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
            "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
            "/usr/bin/microsoft-edge" \
            "/usr/bin/microsoft-edge-stable" || true)"
    fi
    if [[ -n "$browser_path" ]]; then
        browser_name="Microsoft Edge"
    fi
fi

if [[ -z "$browser_path" ]]; then
    echo "Google Chrome or Microsoft Edge is required to generate and open resume.pdf." >&2
    exit 1
fi

"$resume_cli" build "--chrome-path=$browser_path"

generated_pdf_path="$project_dir/resume.pdf"
pdf_filename="Resume-Moch. Noor Alfan.pdf"
pdf_path="$project_dir/$pdf_filename"

if [[ ! -f "$generated_pdf_path" ]]; then
    echo "Build completed, but resume.pdf was not created." >&2
    exit 1
fi

mv -f "$generated_pdf_path" "$pdf_path"

mkdir -p docs
cp resume.html docs/index.html

browser_pdf_path="$pdf_path"
if command -v cygpath >/dev/null 2>&1; then
    browser_pdf_path="$(cygpath -w "$pdf_path")"
fi

"$browser_path" "$browser_pdf_path" >/dev/null 2>&1 &

echo "Built resume.html and $pdf_filename; copied HTML to docs/index.html."
echo "Opened $pdf_filename in $browser_name."
