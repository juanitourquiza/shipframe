# TypeScript Technology Pack

Generic ShipFrame guidance for TypeScript libraries and applications.

- Resolve TypeScript and dependency versions from the lockfile; review the applicable `tsconfig` and package scripts before changing compiler behavior.
- Check strictness, module/module-resolution settings, target/lib, declaration output, and path aliases when affected.
- Run the repository's type-check and tests separately; passing type checks do not replace runtime tests.
- Review public type/API compatibility for exported libraries and generated declarations.
- Use `live-docs` for version-sensitive framework APIs, based on the dependency's resolved version.
