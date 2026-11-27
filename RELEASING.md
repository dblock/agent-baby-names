# Releasing

This is provisional until the plugin is implemented.

Plugins install from this repository, so a release is a version bump and a Git tag, not a registry upload. Releasing requires explicit maintainer authorization.

1. Make sure `master` is green and the Next section of the changelog describes the release.
2. In a PR, set the version in `bin/agent-baby-names`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and `.github/plugin/plugin.json`, and change `## <version> (Next)` to `## <version> (YYYY/MM/DD)`.
3. After it merges, tag the merged commit `v<version>`, push the tag, and create a GitHub Release with the changelog section.
4. In a PR, add `## <next version> (Next)` with `- Your contribution here.` and bump the versions to the next development version.
5. Install the tagged plugin in both hosts and confirm it names a new session.
