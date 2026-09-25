# Bloom RNG — Clean Release Artifact Pipeline

The gameplay workflow now publishes a release-candidate artifact only after the complete deterministic suite succeeds.

Artifact contents:

- `BloomRNG.rbxl` — clean build from `default.project.json` using Rojo 7.7.0;
- `BloomRNG.rbxl.sha256` — checksum for the exact built place file;
- `release-source.json` — Git commit, Git ref, workflow run ID, and Rojo version.

Artifact name:

`BloomRNG-clean-<full git sha>`

Retention is 14 days so release candidates do not accumulate indefinitely.

This does **not** mark the final checkpoint or publish tasks complete. Their remaining gates are intentional: runtime/RC acceptance, final source freeze/tag, Roblox publish, and a live smoke test.
