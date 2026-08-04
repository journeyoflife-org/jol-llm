# Contributing to jol-llm

Thank you for improving the JOL LLM platform. This repository is
**production infrastructure documentation and code** — treat every change as
if it runs on `llm-prod-lt01` tomorrow.

## Ground rules

1. **Correctness over convenience.** Never document or script an unverified
   procedure. If you did not test it against the staging host, say so in the
   PR description.
2. **No secrets, ever.** No API keys, vault passwords, private keys, or real
   client identifiers in any file. `git-secrets`/gitleaks runs in the
   pre-commit hook and CI.
3. **No prompt data.** Never include real prompts, completions, or client
   content in docs, tests, or examples. Use the canned strings in
   `tests/integration/`.
4. **Idempotency.** Shell and Ansible changes must be safe to run twice.

## Development environment

```bash
git clone git@git.jol.internal:jol/jol-llm.git
cd jol-llm
git config core.hooksPath .git-hooks   # enables pre-commit + commit-msg hooks
```

Recommended local tooling: `shellcheck`, `yamllint`, `markdownlint-cli`,
`ansible-lint`, `actionlint`.

## Branching and commit conventions

- Branch naming: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`,
  `sec/<topic>` (security fixes), `ops/<topic>`.
- **Conventional Commits** are enforced by `.git-hooks/commit-msg`:

  ```
  <type>(<scope>): <short imperative summary>

  [optional body — wrap at 72 chars]

  [optional footer: Closes #123 / BREAKING CHANGE: ...]
  ```

  Types: `feat`, `fix`, `docs`, `sec`, `ops`, `refactor`, `test`, `chore`,
  `ci`. Common scopes: `ollama`, `caddy`, `ansible`, `models`, `runbook`,
  `ci`, `monitoring`.

- Security-sensitive changes (`security/`, `infra/`, `deploy/`, `config/`,
  `scripts/security/`) require **two approving reviews** per CODEOWNERS and
  must reference the threat-model entry they affect, where applicable.

## Pull request checklist

- [ ] Conventional commit messages; CI green (lint, compliance scan,
      manifest validation, docs build).
- [ ] Shell scripts pass `shellcheck` with the repo `.ci/shellcheckrc`.
- [ ] New models: manifest added with SHA256 pinned, license audited in
      `docs/05-models/license-compliance.md`, benchmark row appended.
- [ ] Runbook changes include a "Last verified" date and host.
- [ ] No secrets or prompt content introduced (attest in PR template).
- [ ] CHANGELOG.md updated for user-visible changes.

## Testing requirements

| Change type | Required verification |
|---|---|
| Scripts | Run on staging host; paste output in PR |
| Ansible | `ansible-playbook --syntax-check` + staging run |
| systemd/Quadlet | `systemd-analyze verify` + staging reload |
| Models | `scripts/install/03-model-pull.sh --verify-only` |
| Docs | Link check (`markdown-link-check`) passes |

## Review SLA

Security-tagged PRs: reviewed within 1 business day. Others: 3 business days.
Stale PRs (>30 days) may be closed.

## Questions

Open a discussion issue; tag `@jol/platform-eng`.
