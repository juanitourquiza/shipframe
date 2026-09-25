# PHP Technology Pack

Framework-agnostic ShipFrame guidance for PHP applications and libraries.

- Resolve the PHP platform and dependency versions from `composer.lock`; compare them with `composer.json` constraints and runtime/deployment configuration.
- Inspect PSR autoloading, Composer scripts, extensions, and supported PHP versions before changing package or runtime behavior.
- Run repository-defined PHPUnit/Pest tests, PHPStan/Psalm, formatting, and packaging checks; don't assume a tool is installed.
- Review public API and compatibility across supported PHP versions; keep secrets out of Composer config and logs.
- Use `live-docs` for version-specific framework/library APIs. Add a framework pack such as Laravel only when the project actually uses it.
