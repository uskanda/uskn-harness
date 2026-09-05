---
name: release
description: Tag the tip of the remote default branch with the next CalVer tag (vYY.MM.X) and publish a GitHub or GitLab release with notes generated from the commits since the previous tag. Use when the user asks to cut or publish a release.
allowed-tools: Bash
---

# Create a tag and a release from the default branch

## Context

Use the `<repo-context>` block injected at session start: platform and CLI, the default branch, and `release_tag`. If the block is absent, run
`"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh" --json`.
If `release_tag` is not `calver`, ask the user for the exact tag to use instead of computing one. Notes language: follow the user or repository instructions; default to Japanese.

## Tag rule (calver)

1. `git fetch --tags origin` and `git fetch origin <default>`.
2. `YM=$(TZ=Asia/Tokyo date '+%y.%m')`. Tags for this month match `v$YM.*`.
3. `X` is the largest existing `X` in `v$YM.X` plus one; `1` when the month has no tag yet. New tag: `v$YM.X` (example `v26.09.2`).

## Steps

1. **Is the tip already tagged?** If `git tag --points-at origin/<default>` already lists a `vYY.MM.X` tag, do not create a new tag. Check whether a release exists for it (`gh release view <tag>` / `glab release view <tag>`); if it does, report and stop; if not, create only the release for that tag (step 4) and finish.
2. **Previous tag.** The most recent `vYY.MM.X` tag by version sort: `git tag -l 'v[0-9][0-9].[0-9][0-9].*' | sort -V | tail -n 1`.
3. **Notes.** From `git log --oneline <previous>..origin/<default>`: one line per user-facing change, at the level a user understands; keep any `#<issue>` from the commit message at the start of the line; drop merge commits, formatting-only changes, and other noise.
4. **Create tag and release** (the CLI creates the tag on the remote):

   GitHub: `gh release create <tag> --target <default> --title "<tag>" --notes "<notes>"`

   GitLab: `glab release create <tag> --ref <default> --name "<tag>" --notes "<notes>"`

5. Report the release URL and the notes.
