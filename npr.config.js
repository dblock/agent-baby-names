// Releases the plugin as a GitHub Release with a zip of its files, without a registry; see RELEASING.md.
import { HookValidator, IntrideaChangelog, ReleaseWorkflow, ZipArchive } from "npm-package-release";

export default new ReleaseWorkflow({
  changelog: new IntrideaChangelog(),
  project: new ZipArchive(),
  publisher: null,
  versionReferences: {
    "bin/agent-baby-names": [/^VERSION="(?<version>\d+\.\d+\.\d+)"$/mu],
    ".claude-plugin/plugin.json": [/^ {2}"version": "(?<version>\d+\.\d+\.\d+)"/mu],
    ".github/plugin/plugin.json": [/^ {2}"version": "(?<version>\d+\.\d+\.\d+)"/mu],
  },
  validator: new HookValidator({
    // Runs the plugin from the extracted zip, whose files have no executable bits, and checks its version.
    async validateArtifact({ consumer, run, version }) {
      const output = await run("bash", [`${consumer}/bin/agent-baby-names`, "--version"]);
      if (output.trim() !== `agent-baby-names ${version}`) {
        throw new Error(`The zip prints "${output.trim()}" instead of version ${version}.`);
      }
    },
  }),
});
