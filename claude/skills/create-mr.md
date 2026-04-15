---
name: create-mr
description: Create a GitLab merge request with the [ad] prefix for auto deploy. Reads the plan file and git history to generate the MR description.
argument-hint: [optional extra context or title override]
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep
---

# Create Merge Request

Create a GitLab merge request for the current branch targeting `master`.

## Step 1: Gather context

- Run `git log master..HEAD --oneline` to see all commits on this branch
- Run `git diff master...HEAD --stat` to see changed files
- Check for a plan file in `plans/` that matches the current branch name
- Read the plan file if it exists for additional context

## Step 2: Build the MR title

Format: `[ad] <concise description of the change>`

Rules:
- Always prefix with `[ad]` — this triggers auto deploy
- Keep it short and descriptive (under 72 chars total)
- Use lowercase after the prefix
- If the user provided `$ARGUMENTS`, use that as the description (still add `[ad]` prefix)
- Otherwise, derive the title from the commits and plan

Examples:
- `[ad] add retry logic to advance repayment`
- `[ad] fix rewards postback duplicate check`
- `[ad] cleanup stale plaid accounts`

## Step 3: Build the MR description

Use this format:

```markdown
## Summary
<2-3 sentences describing what this MR does and why>

## Changes
- <bullet point per logical change>

## Testing
- <how this was tested or should be tested>
```

If a plan file exists, use it to inform the summary and changes sections.

## Step 4: Create the MR

1. Push the branch: `git push -u origin HEAD`
2. Create the MR using glab:

```
glab mr create --title "<title>" --description "<description>" --target-branch master
```

Present the MR URL to the user when done.
