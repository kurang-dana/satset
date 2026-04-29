# Pull Request Template

## Summary

Provide a concise description of the changes and the specific problem they resolve.

## Technical Implementation

Detail the technical changes made in this pull request. Reference specific modules, buffer handling logic, memory optimizations, or architectural adjustments.

## Changelog Entry

Provide a single-line summary intended for CHANGELOG.md.
Format: `- **[Module]**: [Action]. [Technical result/impact].`
Example: `- **Serialization**: Implementation of u4 sub-byte type. Reduces bandwidth for small integers by 50%.`

## Type of Change

- [ ] Feature
- [ ] Bug Fix
- [ ] Performance Optimization
- [ ] Documentation Update
- [ ] Maintenance / Chore

## Verification and Standards

- [ ] I have adhered to the [Development Patterns](docs/guide/development-patterns.md).
- [ ] I have verified that all CI/CD linting and formatting checks pass.
- [ ] I have confirmed the changes within a Rojo-supported environment.
- [ ] I have updated the technical documentation for any API or architectural changes.
