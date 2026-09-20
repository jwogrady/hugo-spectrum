#!/usr/bin/env bash
# Builds the squash-merge commit message for a release of this theme.
#
# master carries one squash commit per release; the alpha-v<version> branch
# carries the individual commits and preserves the development history. A
# squash would normally collapse all of that into a single changelog line.
#
# release-please splits a commit body wherever a blank line is followed by a
# conventional-commit header (see splitMessages in its src/commit.ts), so
# replaying every subject into the body, blank-line separated, gives one
# CHANGELOG entry per commit instead of one per release.
#
#   git commit -F <(scripts/release-message.sh)
#
# Usage: release-message.sh [base-ref]
#   base-ref  commits after this ref are replayed; defaults to master, or the
#             whole branch when master does not exist yet (the first release).
#   $RELEASE_SUBJECT overrides the first line.
set -uo pipefail

TYPES='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'

base="${1:-}"
if [ -z "$base" ]; then
  for candidate in master origin/master; do
    if git rev-parse --verify -q "$candidate" >/dev/null; then base="$candidate"; break; fi
  done
fi
[ -n "$base" ] && range="$base..HEAD" || range="HEAD"

branch="$(git rev-parse --abbrev-ref HEAD)"
subjects="$(git log --no-merges --reverse --format=%s "$range")"
[ -z "$subjects" ] && { echo "release-message.sh: no commits in $range" >&2; exit 1; }
count="$(printf '%s\n' "$subjects" | wc -l | tr -d ' ')"

# Replaying against the wrong base yields a short changelog that still looks
# plausible, so state the base and the count before anything is committed.
printf 'release-message.sh: replaying %s commits from %s (%s)\n' \
  "$count" "${base:-the root commit}" "$(git rev-parse --short "${base:-HEAD}")" >&2

# A subject that is not a conventional commit is dropped from the changelog
# silently, so say so loudly here instead.
stray="$(printf '%s\n' "$subjects" | grep -vE "^($TYPES)(\(.*\))?!?: " || true)"
if [ -n "$stray" ]; then
  echo "release-message.sh: these subjects are not conventional commits and will" >&2
  echo "not appear in the changelog:" >&2
  printf '  %s\n' "$stray" >&2
fi

printf '%s\n\n' "${RELEASE_SUBJECT:-feat: initial alpha release of the Spectrum theme}"
printf 'Squashes the %s commits on %s, which preserves the full development\n' "$count" "$branch"
printf 'history. Each entry below is one of those commits, replayed oldest-first.\n\n'
printf '%s\n\n' "$subjects" | awk 'NF {print; print ""}'
