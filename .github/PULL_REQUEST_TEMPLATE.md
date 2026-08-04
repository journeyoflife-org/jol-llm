<!-- Title must follow Conventional Commits: type(scope): summary -->

## What / Why

<!-- What does this change and why. Link the issue: Closes #NNN -->

## Verification

<!-- Required per CONTRIBUTING.md. Paste command output summaries. -->

- [ ] Tested on staging host (host: ___, date: ___)
- [ ] `shellcheck` clean (scripts touched)
- [ ] `ansible-playbook --syntax-check` (infra touched)
- [ ] `systemd-analyze verify` (unit files touched)
- [ ] Docs link check passes (docs touched)

## Risk & rollback

- Risk level: [ ] low [ ] medium [ ] high
- Rollback procedure: <!-- reference docs/02-deployment/rollback-procedures.md -->

## Compliance attestations

- [ ] No secrets introduced
- [ ] No prompt/completion content introduced
- [ ] Security-sensitive paths touched → two reviewers assigned
- [ ] Threat model / hardening checklist updated if controls changed
- [ ] CHANGELOG.md updated

## Checklist

- [ ] Conventional commit messages
- [ ] Docs updated for user-visible behavior changes
- [ ] New model manifests include pinned SHA256 and license audit
