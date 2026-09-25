# Rust Technology Pack

Generic ShipFrame guidance for Rust applications and libraries.

- Resolve the toolchain from `rust-toolchain.toml`/`rust-toolchain` and dependencies from `Cargo.lock`; confirm edition and workspace boundaries.
- Run repository-defined `cargo fmt --check`, `cargo clippy`, `cargo test`, and build/release checks as applicable.
- Review ownership/lifetimes, error propagation, unsafe blocks, feature flags, async runtime choices, and resource cleanup when affected.
- For libraries, check semver and public API compatibility; test supported targets/features rather than only the default build.
- Use `live-docs` for version-sensitive crate APIs and prefer crate docs matching the locked version.
