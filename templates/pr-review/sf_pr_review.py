#!/usr/bin/env python3
"""ShipFrame AI PR reviewer.

Runs inside GitHub Actions. Reads the PR diff, asks the configured AI provider
for a gatekeeper-style review, and posts/updates ONE comment on the PR
(identified by an HTML marker so later pushes edit it instead of piling up).

Configuration comes from workflow env vars (values are baked in by
`install.sh --pr-review <provider>`):

- SF_REVIEW_API        openai_compatible | anthropic
- SF_REVIEW_BASE_URL   provider API base URL
- SF_REVIEW_MODEL      model name
- SF_REVIEW_API_KEY    secret; never printed
- SF_REVIEW_LANGUAGE   comment language (default es)
- SF_REVIEW_MAX_DIFF_CHARS  diff cap before truncation (default 40000)

Project context: if `.shipframe/profile.md` or `shipframe.profile.md` exists
in the checkout, it is included (truncated) so the review enforces the
project's own conventions. Stdlib only; no pip installs.
"""

import json
import http.client
import os
import sys
import time
import urllib.error
import urllib.request

MARKER = "<!-- shipframe-pr-review -->"
MAX_ATTEMPTS = 3
REQUEST_TIMEOUT = 600  # segundos; los modelos con razonamiento pueden tardar varios minutos
PROFILE_MAX_CHARS = 4000
PROFILE_CANDIDATES = (".shipframe/profile.md", "shipframe.profile.md")


def _env(name: str, default: str = "") -> str:
    value = os.environ.get(name, default)
    if not value:
        print(f"::error::Missing environment variable {name}")
        sys.exit(1)
    return value


def http_json(url: str, method: str, token: str, payload: dict | None = None,
              extra_headers: dict | None = None) -> dict:
    """JSON request with retries on 429/5xx and network errors. Never logs the token."""
    body = json.dumps(payload).encode() if payload is not None else None
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "shipframe-pr-reviewer",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if extra_headers:
        headers.update(extra_headers)
    last_error: Exception | None = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
                data = resp.read().decode()
                if not data:
                    return {}
                try:
                    return json.loads(data)
                except json.JSONDecodeError as exc:
                    raise RuntimeError(f"Non-JSON response from {url}: {data[:200]}") from exc
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode(errors="replace")[:500]
            if exc.code in (408, 429, 500, 502, 503, 504) and attempt < MAX_ATTEMPTS:
                wait = 2 ** attempt
                print(f"HTTP {exc.code} from {url} (attempt {attempt}); retrying in {wait}s")
                time.sleep(wait)
                last_error = exc
                continue
            raise RuntimeError(f"HTTP {exc.code} from {url}: {detail}") from exc
        except (urllib.error.URLError, TimeoutError, http.client.HTTPException,
                ConnectionError) as exc:
            # HTTPException cubre RemoteDisconnected: la API puede cerrar la
            # conexión sin responder; TimeoutError: socket > REQUEST_TIMEOUT.
            if isinstance(exc, TimeoutError) and attempt >= 2:
                raise RuntimeError(
                    f"Provider timed out after {REQUEST_TIMEOUT}s twice ({url}); "
                    "reduce SF_REVIEW_MAX_DIFF_CHARS or pick a faster model"
                ) from exc
            if attempt < MAX_ATTEMPTS:
                wait = 2 ** attempt
                print(f"Network error/timeout (attempt {attempt}); retrying in {wait}s: {exc}")
                time.sleep(wait)
                last_error = exc
                continue
            raise
    raise RuntimeError(f"Gave up after {MAX_ATTEMPTS} attempts: {last_error}")


def load_profile_context() -> str:
    for candidate in PROFILE_CANDIDATES:
        if os.path.isfile(candidate):
            with open(candidate, encoding="utf-8", errors="replace") as fh:
                text = fh.read().strip()
            if text:
                if len(text) > PROFILE_MAX_CHARS:
                    text = text[:PROFILE_MAX_CHARS] + "\n\n[profile truncated]"
                return text
    return ""


def build_messages(title: str, body: str, diff: str) -> tuple[str, str]:
    language = os.environ.get("SF_REVIEW_LANGUAGE", "es")
    system = (
        "You are a strict senior code reviewer (gatekeeper) for this repository.\n"
        f"Always answer in {language}, in Markdown, with exactly this structure:\n\n"
        "**Verdict: approved** or **Verdict: changes needed**\n\n"
        "- pass/fail **Tests**: do new or behavior-changing paths bring tests that exercise them?\n"
        "- pass/fail **Correctness**: bugs, edge cases, wrong logic inside the diff.\n"
        "- pass/fail **Security**: injection, secrets in code, missing input validation, unsafe output.\n"
        "- pass/fail **Conventions**: does the change follow the project conventions below?\n\n"
        "Then an optional '## Suggestions' section with non-blocking improvements.\n"
        "Be concrete: cite files and lines from the diff. Never invent code that is not in the diff. "
        "If the diff is documentation-only, say so and do not block the PR."
    )
    profile = load_profile_context()
    if profile:
        system += f"\n\nProject conventions (shipframe profile):\n{profile}"
    user = (
        f"PR title: {title}\n\nDescription:\n{body or '(no description)'}\n\n"
        f"Diff:\n````diff\n{diff}\n````"
    )
    return system, user


def call_openai_compatible(base_url: str, model: str, api_key: str, system: str, user: str) -> str:
    url = f"{base_url.rstrip('/')}/chat/completions"
    resp = http_json(url, "POST", api_key, {
        "model": model,
        "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
        "temperature": 0.2,
    })
    try:
        return resp["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError) as exc:
        raise RuntimeError(f"Unexpected provider response: {json.dumps(resp)[:500]}") from exc


def call_anthropic(base_url: str, model: str, api_key: str, system: str, user: str) -> str:
    url = f"{base_url.rstrip('/')}/v1/messages"
    resp = http_json(url, "POST", "", {
        "model": model,
        "max_tokens": 4096,
        "system": system,
        "messages": [{"role": "user", "content": user}],
    }, extra_headers={"x-api-key": api_key, "anthropic-version": "2023-06-01"})
    try:
        return "".join(block.get("text", "") for block in resp["content"]).strip()
    except (KeyError, TypeError) as exc:
        raise RuntimeError(f"Unexpected provider response: {json.dumps(resp)[:500]}") from exc


def ask_provider(api: str, base_url: str, model: str, api_key: str, system: str, user: str) -> str:
    if api == "anthropic":
        return call_anthropic(base_url, model, api_key, system, user)
    if api == "openai_compatible":
        return call_openai_compatible(base_url, model, api_key, system, user)
    raise RuntimeError(f"Unknown SF_REVIEW_API: {api}")


def load_diff() -> str:
    max_chars = int(os.environ.get("SF_REVIEW_MAX_DIFF_CHARS", "40000"))
    path = os.environ.get("DIFF_PATH", "pr.diff")
    if not os.path.exists(path):
        # Fail closed: sin diff no hay veredicto (un falso aprobado es el peor
        # modo de fallo de un gatekeeper).
        raise RuntimeError(
            f"{path} not found: the diff step failed; refusing to post a verdict"
        )
    with open(path, encoding="utf-8", errors="replace") as fh:
        diff = fh.read()
    if not diff.strip():
        raise RuntimeError("Empty diff: refusing to post a verdict (fail closed).")
    if len(diff) > max_chars:
        return diff[:max_chars] + f"\n\n[DIFF TRUNCATED: {len(diff)} -> {max_chars} chars; read the full PR on GitHub]"
    return diff


def publish_comment(repo: str, pr_number: str, token: str, sha: str, model: str, review: str) -> None:
    body = (
        f"{MARKER}\n## 🤖 ShipFrame AI review (`{model}`)\n\n{review}\n\n---\n"
        f"<sub>Reviewed commit `{sha[:12]}` · updates on every push · shipframe PR reviewer</sub>"
    )
    base = f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments?per_page=100"
    page = 1
    matches = []
    while True:
        existing = http_json(f"{base}&page={page}" if "?" in base else f"{base}?page={page}", "GET", token)
        matches.extend(c for c in existing if MARKER in c.get("body", ""))
        if len(existing) < 100:
            break
        page += 1

    def delete_comment(comment_id: int) -> None:
        http_json(f"https://api.github.com/repos/{repo}/issues/comments/{comment_id}",
                  "DELETE", token)

    if not matches:
        http_json(f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments",
                  "POST", token, {"body": body})
        print("Posted new review comment.")
        return

    own = max(matches, key=lambda c: c["id"])
    updated = False
    try:
        http_json(f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments/{own['id']}",
                  "PATCH", token, {"body": body})
        updated = True
        print(f"Updated comment {own['id']}.")
    except RuntimeError as exc:
        # El comentario puede no ser editable (comentarios del bot con
        # GITHUB_TOKEN); se reemplaza por uno nuevo en vez de fallar.
        if "HTTP 404" not in str(exc) and "HTTP 410" not in str(exc):
            raise
        print(f"Could not update comment {own['id']} ({exc}); replacing it.")
    # Converger a un solo comentario: borrar los marcados que quedaron.
    for c in matches:
        if updated and c["id"] == own["id"]:
            continue
        try:
            delete_comment(c["id"])
            print(f"Deleted comment {c['id']}.")
        except RuntimeError as dexc:
            print(f"Could not delete comment {c['id']} ({dexc}); leaving it.")
    if not updated:
        http_json(f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments",
                  "POST", token, {"body": body})
        print("Posted new review comment.")


def main() -> None:
    api = _env("SF_REVIEW_API")
    base_url = _env("SF_REVIEW_BASE_URL")
    model = _env("SF_REVIEW_MODEL")
    api_key = _env("SF_REVIEW_API_KEY")
    repo = _env("REPO")
    pr_number = _env("PR_NUMBER")
    sha = _env("HEAD_SHA")
    token = _env("GITHUB_TOKEN")

    diff = load_diff()
    system, user = build_messages(_env("PR_TITLE"), os.environ.get("PR_BODY", ""), diff)
    print(f"Asking {model} ({api}) to review {len(diff)} diff chars...")
    review = ask_provider(api, base_url, model, api_key, system, user)
    publish_comment(repo, pr_number, token, sha, model, review)
    print("Review complete.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        # Surface the real cause as a check-run annotation; logs are private.
        # Collapse newlines: a multi-line annotation message renders broken.
        flat = " ".join(str(exc).split())
        print(f"::error title=AI review failed::{flat}", file=sys.stderr)
        raise SystemExit(1)
