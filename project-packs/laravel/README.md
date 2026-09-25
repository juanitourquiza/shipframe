# Laravel Project Pack

Generic ShipFrame profile notes for Laravel/API projects.

- Resolve `laravel/framework`, PHP, and relevant package versions from `composer.lock`; use `live-docs` for APIs matching those versions.
- Review routes/middleware, policies/auth, Eloquent queries, migrations, queues, scheduled jobs, and events when affected.
- Run repository-defined PHPUnit/Pest, static analysis, and config/cache checks where applicable; avoid destructive cache or migration commands without approval.
- Smoke health and affected web/API endpoints in the intended environment.
- Document required environment-variable changes without committing secret values.
