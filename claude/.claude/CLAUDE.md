# Global Instructions

- **Load the `git-workflow` skill before the first git write** (branch, commit, push, PR,
  merge, `gw` mutation or worktree-pool operation).
- **Merge PRs only in `zawakin/*` and `lanegrid/*`, never elsewhere**, and only once CI
  (or, without CI, the repo's verify) has passed on the PR's head. Elsewhere a human merges.
- **Keep personal identifiers out of outbound requests.** No personal name, personal email,
  account handle, or private repository name/URL in User-Agents, URLs, or payloads. If a
  service asks for a contact, use only the public contact the repository defines.
