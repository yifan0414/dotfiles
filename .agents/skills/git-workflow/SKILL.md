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

Use Conventional Commits in one of these forms:

```text
<type>: <imperative summary>
<type>(<scope>): <imperative summary>
```

- Prefer `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `build`, `ci`, and `chore`.
- Use a concise, lowercase scope only when it adds useful context.
- Keep the subject specific, imperative, and no longer than 72 characters.
- Do not end the subject with a period.
- Add a body only when the motivation or non-obvious details are unclear from the subject.
- Mark breaking changes with `!` or a `BREAKING CHANGE:` footer.
- Do not add emoji, AI attribution, Codex attribution, or co-author attribution unless explicitly requested.

Use these patterns as guidance:

```text
feat(selector): add progressive frame selection
fix(loader): handle missing video timestamps
perf(encoder): batch frame embedding extraction
refactor(scorer): simplify relevance normalization
docs: add reproduction instructions
```

## Commit and Verify

1. Run the smallest relevant verification available before committing when practical.
2. Create the commit without bypassing hooks unless the user explicitly requests it.
3. If a hook fails or modifies files, inspect the resulting state before taking further action. Do not silently amend or discard changes.
4. Inspect the new commit and `git status` after committing.
5. Report the commit hash and subject, verification performed, and all remaining working-tree changes.
