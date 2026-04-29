# Contributing

Contributions to Satset are welcome. This document covers what you need to know before submitting changes.

## Workflow

1. **Fork**: Fork the repository on GitHub to your own account.
2. **Clone**: Clone your fork to your local machine.
3. **Branch**: Create a new branch for your changes (`git checkout -b feat/my-new-feature`).

## Setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit) and run `rokit install` to get tooling.
2. Run `rojo serve` and connect from Roblox Studio.

## Code style

- **Formatting**: Run `stylua` on all changed `.luau` files before committing.
- **Linting**: Run `selene` and resolve all errors.
- **Strict mode**: The workspace uses global strict typing via `.luaurc`. Do not add `--!strict` headers to individual files.
- **Naming**: PascalCase for types and modules, camelCase for variables and functions, SCREAMING_SNAKE_CASE for constants.

## Commits

Follow Conventional Commits. One logical change per commit.

```yaml
type(scope?): brief description
```

Types: `feat`, `fix`, `refactor`, `perf`, `docs`, `chore`, `test`, `style`.

## Pull requests

- Keep changes small and focused.
- Include a description of what changed and why.
- Add or update tests where applicable.

## Benchmarks

If your change touches a hot path (Batcher, Serializer, Bridge), run the benchmark harness in `benchmark/` and include results in your PR description.
