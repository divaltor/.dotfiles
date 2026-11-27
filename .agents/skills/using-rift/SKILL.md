---
name: using-rift
description: "Creates isolated copy-on-write workspaces with Rift instead of Git worktrees. Use before creating a worktree, parallel agent checkout, or isolated workspace, and when listing, recovering work from, or removing Rift workspaces. Not for ordinary branch switches or requests that explicitly require Git linked worktrees."
---

# Using Rift

Use Rift for new isolated working directories, regardless of which agent or editor will use them. This is a workspace-creation preference, not a replacement for Git commands: Rift snapshots have independent repositories and detached HEADs, not shared Git worktree refs.

## Choose the workspace

1. If the task can run in its existing checkout, keep it there. This skill does not require isolation for every task.
2. If a new isolated checkout is needed, use Rift. If the user explicitly requires a Git linked worktree, follow that requirement instead.
3. If the task requires a particular starting commit or shared refs, explain the mismatch before creating anything. Rift snapshots the current directory state; it does not implement `git worktree add <path> <ref>`. Do not switch or reset the user's checkout to manufacture a source.
4. If the source is a linked Git worktree, has an in-progress Git operation, or contains repository lock files, leave it untouched. Identify a suitable primary checkout or ask which source to use; do not remove locks, abort operations, or silently fall back to Git worktrees.
5. For a jj repository, check current upstream support before proceeding. A filesystem copy is not proof that jj workspace registration and repository paths remain valid.

## Create and enter

Check `command -v rift` and read `rift init --help` and `rift create --help`. If Rift is missing, ask to install the CLI using the [upstream installation instructions](https://github.com/anomalyco/rift#install). Do not install an editor plugin or substitute another workspace tool.

Inspect the source's branch, HEAD, staged changes, and unstaged/untracked files. Rift preserves dirty state, so distinguish pre-existing edits from the work this task will produce. Never stash or clean the source just to make a snapshot.

Initialize only the selected repository root, never its parent collection such as `~/dev`. `rift init` registers that root and creates its `.rift` marker; reuse an existing registration.

Use the CLI directly rather than relying on interactive shell functions. For example, after choosing an absolute source path and an unused task name:

```sh
source=/absolute/path/to/repository
name=task-name
command rift init "$source"
workspace="$(command rift create "$source" --name "$name" --copy-all --no-hooks)"
```

Check each command's exit status before continuing. Capture the returned path instead of guessing where Rift put the workspace. The destination must be on the same CoW-capable volume as the source.

- Default to `--copy-all` so dependencies, ignored files, and build caches are available without reinstalling. These are independent CoW copies, not writable symlinks back into the source. Omit it only when the task calls for a clean dependency/build environment.
- Default to `--no-hooks` because repository `.rift.toml` hooks execute commands. Enable hooks only after reading them and confirming their effects are within the task's authorization.
- Run subsequent commands with the returned workspace as their explicit working directory. Start agents and editors there; do not let their automatic worktree options create a second checkout.
- Inspect the new checkout's HEAD and Git status against the recorded source state. Create a task branch there before making branch-based commits. Do not commit inherited edits as part of the task.
- Check that interpreters and build tools resolve inside the new workspace. CoW does not rewrite absolute paths embedded in virtualenvs, caches, or symlinks; recreate affected environments locally instead of running tools that still target the source. For Python/`uv` workspaces with a copied `.venv`, run `uv pip install --no-deps -e .` (or recreate `.venv` with `uv sync --frozen` when `.venv/bin` shebangs or `.pth` files point back to the source checkout).

## Return work and clean up

Commits and branches created in a Rift do not automatically appear in the source repository. Before any handoff, state which checkout owns the changes. When integration is requested, transfer the task's commits through a local fetch/cherry-pick or the project's normal review flow; preserve unrelated dirty source edits.

Use `rift list` for direct children and `rift ancestors` for parent workspaces. Git's worktree inventory does not track Rifts, so use `rift remove`, not `git worktree remove`, for cleanup.

Before removing a workspace, inspect its staged, unstaged, untracked, and ignored files and verify that work to keep exists outside it. A clean Git status alone does not prove its commits or ignored files are disposable. Leave the workspace before removing it, and inspect child Rifts before removing their parent.

`rift remove <workspace-path> --no-hooks` moves a created workspace subtree to trash. `rift gc` permanently deletes Rift trash, not just the last removed workspace; run it only when that broader deletion is explicitly authorized. Do not unregister a source root as routine workspace cleanup.

If creation or removal fails, inspect the reported path and Rift inventory before retrying: a post-hook failure can occur after the filesystem operation completed. Report the actual workspace and remaining work rather than claiming rollback.
