---
name: git-workflow
description: Perform safe local Git operations and create focused Conventional Commits without disturbing unrelated work. Use when Codex needs to inspect repository state, stage changes, create commits, propose commit messages, or perform a task involving branches, merges, rebases, stashes, restores, or other Git state changes. Do not use for GitHub-only issue or pull-request triage that does not affect a local repository.
---

# Git Workflow

Use simple, non-destructive Git operations. Follow repository-specific instructions, existing conventions, and `.gitignore`.

## Protect Repository State

- Inspect `git status` and relevant staged and unstaged diffs before staging or committing.
- Identify unrelated pre-existing changes and leave them untouched.
- Do not modify, discard, stage, commit, stash, or restore unrelated changes.
- Never discard uncommitted work or run destructive commands such as `git reset --hard` or `git clean -fd` unless explicitly requested.
- Do not rewrite published history or force-push unless explicitly requested.
- Do not create, switch, merge, rebase, or delete branches unless the task requires it.
- Treat direct commits to the current branch as acceptable for personal repositories.
- Stop before committing secrets, credentials, `.env` files, datasets, model checkpoints, caches, logs, or unintended large or generated files.

## Prepare Atomic Commits

1. Determine which files and hunks belong to the current task.
2. Separate unrelated logical changes into different commits.
3. Stage only the explicit files or hunks for one coherent change. Avoid broad staging when the worktree contains unrelated changes.
4. Review the complete staged diff before committing.
5. Confirm the staged diff contains the intended change, contains no unrelated work, and follows `.gitignore` and repository conventions.

## Write Commit Messages

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) for message structure and meaning:

```text
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

- Use `feat` for new features and `fix` for bug fixes. Other types are allowed; prefer `perf`, `refactor`, `test`, `docs`, `build`, `ci`, and `chore` when appropriate, following repository conventions.
- Put an optional scope in parentheses; use a noun identifying the affected part of the codebase. Follow the colon with a space and a short description.
- Separate the body and footer section from preceding content with a blank line. Use trailers such as `Refs: #123` or `Closes #123`; footer tokens use hyphens instead of spaces, except for `BREAKING CHANGE`.
- Mark any breaking change, regardless of type, with `!` immediately before the colon (for example, `feat(api)!:`), a `BREAKING CHANGE: <description>` footer, or both. When using only `!`, describe the breaking change in the subject. Keep `BREAKING CHANGE` uppercase; `BREAKING-CHANGE` is also valid as a footer token.
- Preserve release meaning: `fix` corresponds to PATCH, `feat` to MINOR, and any breaking change to MAJOR. Other types have no implicit version bump unless they mark a breaking change.

Apply these local writing defaults unless repository-specific instructions override them; they are additional preferences, not requirements of Conventional Commits:

- Use a concise, lowercase scope only when it adds useful context.
- Keep the full subject line, including the prefix, specific, imperative, and no longer than 72 characters.
- Do not end the subject with a period.
- Add a body only when the motivation or non-obvious details are unclear from the subject.
- Do not add emoji, AI attribution, Codex attribution, or co-author attribution unless explicitly requested.

Use these patterns as guidance:

```text
feat(selector): add progressive frame selection
fix(loader): handle missing video timestamps
perf(encoder): batch frame embedding extraction
refactor(scorer): simplify relevance normalization
docs: add reproduction instructions
```

For a breaking change that needs migration context:

```text
feat(config)!: require an explicit model path

Remove automatic model discovery to make model selection reproducible.

BREAKING CHANGE: set model_path in the config; automatic discovery is removed.
```

## Commit and Verify

1. Run the smallest relevant verification available before committing when practical.
2. Create the commit without bypassing hooks unless the user explicitly requests it.
3. If a hook fails or modifies files, inspect the resulting state before taking further action. Do not silently amend or discard changes.
4. Inspect the new commit and `git status` after committing.
5. Report the commit hash and subject, verification performed, and all remaining working-tree changes.
