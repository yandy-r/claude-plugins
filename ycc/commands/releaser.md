---
description: Prepare and cut a GitHub release for any project — detects toolchain, drafts changelog, plans platform/arch artifacts, optionally generates or audits release CI. Emits commands; never auto-publishes. External-project counterpart to /ycc:bundle-release.
argument-hint: '[version] [--arch=list] [--os=list] [--ci[=generate|audit]] [--platform=name] [--skip-notes] [--dry-run]'
---

Invoke the **releaser** skill with `$ARGUMENTS` passed through.

The skill:

1. Detects the project's language, build system, and version-bearing manifests.
2. Proposes a semver bump from conventional-commit history if no version is supplied.
3. Resolves the `{os × arch}` release matrix from language defaults or explicit flags.
4. Drafts a grouped changelog and a release-notes file.
5. Bumps version in manifests (package.json / pyproject.toml / Cargo.toml) without
   editing anything else.
6. Optionally generates a release workflow (`--ci=generate`) or audits the existing
   one (`--ci=audit`) for supply-chain, caching, and permissions best practices.
7. Emits the exact `git tag`, `git push`, and `gh release create` commands to run.

Never auto-commits, pushes, or publishes. Use `/ycc:bundle-release` for this repo's
internal ycc bundle release — this command is the generic external-project variant.
