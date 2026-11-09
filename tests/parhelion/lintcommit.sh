#!/usr/bin/env bash
# Reads commits as "<hash> <subject>" lines, as git log --format='%h %s' writes them, and fails naming each subject
# that is not a Conventional Commit.
set -euo pipefail
conventional='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^()]+\))?!?: [^[:space:]]'

status=0
while read -r hash subject; do
  if ! [[ $subject =~ $conventional ]]; then
    printf '%s is not a Conventional Commit: %s\n' "$hash" "$subject" >&2
    status=1
  fi
done

exit "$status"
