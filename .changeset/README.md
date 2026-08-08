# Changesets

Run `npm run changeset` for each user-facing change and commit the generated
Markdown file with the change. Select patch, minor, or major according to
semantic versioning.

Changesets updates the release pull request on `main`. Merging that pull
request creates a Git tag and GitHub Release. This private package is never
published to npm.
