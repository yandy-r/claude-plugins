---
description: Rust testing patterns including unit tests, integration tests, async testing, property-based testing, mocking, and coverage. Follows TDD methodology. Use when the user is writing Rust tests, adding test coverage to Rust code, asks about #[cfg(test)] modules, rstest, proptest, mockall, tokio::test, criterion benchmarks, cargo-llvm-cov coverage, doc tests, or wants TDD guidance for a Rust project.
---

# Rust Testing Command

Provide Rust testing patterns and TDD guidance using the standard `cargo test` workflow and ecosystem crates.

**Load and follow the `ycc:rust-testing` skill**, passing through `$ARGUMENTS`.

The skill covers:

- Unit tests in `#[cfg(test)]` modules and integration tests in `tests/`
- Parameterized tests with `rstest`
- Property-based testing with `proptest`
- Mocking with `mockall`
- Async testing with `#[tokio::test]`
- Benchmarks with `criterion`
- Doc tests and coverage with `cargo-llvm-cov`
