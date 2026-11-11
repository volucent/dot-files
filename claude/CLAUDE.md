## Writing style

Strongly prefer bullet lists over paragraphs whenever the content is a set of points, options, steps or findings. Keep prose for a single connected argument.

## After a merge request merges

When an MR or PR merges (the user says so, or `glab mr view` / `gh pr view` shows it merged), clean up its local copies:

1. Take the merged state from `glab mr view <branch>` / `gh pr view <branch>`. Squash merges leave the branch looking unmerged to git, so the MR state is the proof, and `git branch -D` is the delete.
2. For each worktree that has the branch checked out (`git worktree list`), run `git worktree remove <path>`. When it holds uncommitted or untracked files, list them and ask before removing. When it is the worktree this session runs in, run `git switch --detach origin/<default-branch>` there instead and leave the directory in place.
3. Delete the local branch: `git branch -D <branch>`.

Done when `git branch --list <branch>` prints nothing and `git worktree list` no longer shows the branch.
