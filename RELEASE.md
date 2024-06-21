# Release

This document describes the release process for the project.

1. Determine the next version number based on the changes since the last release.
2. Create a branch named `vX.Y.Z` where `X.Y.Z` is the version number. Tag the HEAD of the branch with the version number.
3. Push the changes upstream including the tags by running `git push origin vX.Y.Z --tags`.
4. Once continuous integration passes, merge the branch, and create the release through GitHub's UI generating the release notes automatically.