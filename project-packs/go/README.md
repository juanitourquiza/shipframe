# Go Project Pack

Generic release and review notes for Go repositories.

- Identify Go toolchain version, module boundaries, executable entry points, HTTP/RPC transport, and generated code.
- Run repository-defined `go test`, `go vet`, lint, and build commands; use race tests where concurrency changes warrant them.
- Review context cancellation, error wrapping, goroutine ownership, resource closure, and API compatibility when affected.
- Inspect migration/job/queue behavior and configuration changes before release.
- Smoke the intended binary/service and report local tests separately from deployed dependency/provider evidence.
