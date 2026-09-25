# Next.js Project Pack

Generic release and review notes for Next.js repositories.

- Identify App Router vs Pages Router, Next.js/React versions, runtime target, and deployment adapter before editing.
- Check server/client component boundaries, route handlers, middleware/proxy behavior, caching/revalidation, and metadata when affected.
- Use the repository's package manager and scripts for lint, typecheck, tests, and production build; do not assume a Vercel deploy.
- Smoke affected routes and server-rendered behavior in the intended runtime; separate local build proof from deployed proof.
- Review secrets and server-only values at the server/client boundary.
