![Naev Logo](https://naev.org/imgs/naev.png "Naev Logo")

## Official Flatpak for Naev

#### Check out the upstream project here: https://naev.org/
#### Report Upstream issues here: https://naev.org/contact/

### Build the Flatpak locally
1. Clone this repo
2. Install flatpak and flatpak-builder for your distro
3. Run the build script with: `./local-build.sh` (or `./local-build.sh --debug` for a debug build)
4. Install the test build with: `flatpak install --user ./org.naev.Naev.flatpak`

### Updating Rust Dependencies
The Rust dependencies are vendored for the Flatpak build. To update them:
1. Download the updated `Cargo.lock` from the latest release action for the version you want to update on [Codeberg](https://codeberg.org/naev/naev/actions?workflow=naev_release.yml).
2. Replace the `Cargo.lock` in this repository with the downloaded one.
3. Run the source generation script to update `cargo-sources.json`:
   ```bash
   ./gen-sources.sh
   ```
4. Commit both `Cargo.lock` and `cargo-sources.json`.
