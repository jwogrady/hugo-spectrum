# Releasing

Releases are cut by [release-please](https://github.com/googleapis/release-please).

## How it works

`.github/workflows/release-please.yml` runs on every push to `master`.
release-please reads **the commit messages on `master` since the last release
tag** and builds the changelog from them. It does not care how those commits
arrived — a direct push, a merge commit and a squash are all just pushes.

It then opens a release pull request, `chore(master): release X.Y.Z`, carrying
the generated `CHANGELOG.md` and the version bump. Merging that PR tags the
release, publishes it, and writes the new version into
`.release-please-manifest.json`.

Further pushes to `master` update the open release PR in place rather than
opening a second one, so work can keep landing and the release is cut when you
choose.

## Before the first release on a new remote

Both of these are off by default and both are silent failures:

```sh
gh repo edit --default-branch master
gh api -X PUT repos/<owner>/<repo>/actions/permissions/workflow \
  -f default_workflow_permissions=write -F can_approve_pull_request_reviews=true
```

Without the second, release-please fails with *"GitHub Actions is not permitted
to create or approve pull requests"*.

## Changelog granularity is a merge-strategy decision

| how the work reaches `master` | changelog |
|---|---|
| pushed directly | one entry per commit |
| PR merged with a merge or rebase commit | one entry per commit |
| PR squashed | one entry per **PR** |
| PR squashed with `scripts/release-message.sh` | one entry per commit |

One entry per PR is release-please's own assumption, and it is usually the
right one for a public changelog: twelve `style:` commits refining a footer are
true history and poor release notes.

## If you squash, do not merge from the GitHub UI

The UI's squash body prefixes every replayed commit with `* `:

```
* fix: the browser tab carried the machine key, not the title
```

release-please splits a commit body only where a blank line is followed by a
conventional-commit header, and `* fix:` is not one — so every commit but the
title is dropped, and the release gets a single line. `scripts/release-message.sh`
emits the headers at line-start; merge from the CLI so its output survives:

```sh
scripts/release-message.sh master > /tmp/squash.txt
gh pr merge <n> --squash --subject "$(head -1 /tmp/squash.txt)" \
                         --body-file <(tail -n +3 /tmp/squash.txt)
```

## What is releasable

`release-please-config.json` sets `bump-minor-pre-major`, so before 1.0 a
`feat:` bumps the minor and a `fix:` the patch. `chore:`, `ci:` and `test:`
never bump a version on their own. A subject that is not a conventional commit
is dropped from the changelog silently, so the subject line is the release
note — write it for a reader of the release, not for the diff.
