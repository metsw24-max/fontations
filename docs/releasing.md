# Releasing

We use [`cargo-release`] to help guide the release process. It can be installed
with `cargo install cargo-release`. You may need to install `pkg-config` via
your package manager for this to work.

Releasing involves two main steps:

## 1. Assessment

1. **Determine modified crates**: Run `cargo release changes` to see which crates have been modified since their last release.
2. **Determine new versions**: Decide on the new versions for the crates.
   * Before 1.0, breaking changes bump the *minor* version number, and non-breaking changes modify the *patch* number.

## 2. Execution

1. **Update manifest versions**: Use `./resources/scripts/bump-version.sh` to update manifest versions.
   * `cargo release` does all the heavy lifting under the hood.

   ```shell
   # To see usage
   ./resources/scripts/bump-version.sh
   # To do the thing
   ./resources/scripts/bump-version.sh read-fonts write-fonts patch
   ```

2. **Commit and Merge**: Commit these changes to a new branch, get it approved and merged, and switch to the up-to-date `main`.
3. **Publish crates**: Run `./resources/scripts/release.sh` to publish the crates.
   * You will be prompted to review changes along the way.

   ```shell
   # To see usage
   ./resources/scripts/release.sh
   # To do the thing
   ./resources/scripts/release.sh read-fonts write-fonts
   ```

[`cargo-release`]: https://github.com/crate-ci/cargo-release
