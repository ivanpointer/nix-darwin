SHELL := /bin/zsh
.ONESHELL:

.PHONY: apply push

apply:
	sudo darwin-rebuild switch

push:
	set -euo pipefail
	git rev-parse --is-inside-work-tree >/dev/null
	git add -A
	if git diff --cached --quiet; then
		echo "No changes to commit."
		exit 0
	fi
	msg_file="$$(mktemp)"
	trap 'rm -f "$$msg_file"' EXIT
	codex exec --sandbox read-only --ask-for-approval never --output-last-message "$$msg_file" "You are writing a git commit message for the currently staged changes in this repository. Inspect the staged diff with git diff --cached. Output only the commit message: a concise imperative subject line under 72 characters, followed by a blank line and a short body only if useful. Do not use markdown fences, bullets, or commentary."
	git commit -F "$$msg_file"
	git push
