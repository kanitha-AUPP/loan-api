cat > make_checklist.sh <<'EOF'
#!/usr/bin/env bash
OUT=CHECKLIST.md
F='```'
section() { printf '\n## %s\n' "$1" >> "$OUT"; }
ev() {
  { printf '\nCommand:\n%sbash\n%s\n%s\n\nOutput:\n%s\n' "$F" "$1" "$F" "$F"
    eval "$1" 2>&1
    printf '%s\n' "$F"; } >> "$OUT"
}

echo "# Production checklist: loan-api 1.0.0" > "$OUT"

section "1. Slim base image"
ev "grep '^FROM' Dockerfile.prod"
ev "docker images loan-api"

section "2. Multi-stage build"
ev "grep -nE '^FROM|COPY --from' Dockerfile.prod"
ev "docker run --rm loan-api:prod ls -a /app"

section "3. Dev dependencies separated"
ev "cat requirements.txt"
ev "cat requirements-dev.txt"
ev "docker run --rm loan-api:prod pip show pytest"

section "4. Non-root user"
ev "docker run --rm loan-api:prod whoami"
ev "docker run --rm loan-api:prod id"

section "5. Pinned versions"
ev "grep '^FROM' Dockerfile.prod"
ev "grep -vE '==|^[[:space:]]*\$|^#' requirements.txt || echo 'every line in requirements.txt is pinned'"
ev "grep 'image:' compose.yaml"

section "6. HEALTHCHECK"
ev "docker run -d --name prod -p 8000:8000 loan-api:prod"
ev "sleep 35; docker ps --filter name=prod"
ev "docker inspect --format '{{.State.Health.Status}}' prod"
ev "docker rm -f prod"

section "7. Vulnerability scan (Trivy 0.69.3, HIGH and CRITICAL)"
ev "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.69.3 image --severity HIGH,CRITICAL loan-api:prod"

section "Compose stack on the production image"
ev "docker compose up -d --build"
ev "sleep 35; docker compose ps"
ev "docker compose down"

section "No secrets"
ev "grep -rniE 'password|secret|token|api_key' --exclude-dir=.git --exclude=CHECKLIST.md --exclude=make_checklist.sh . || echo none"
ev "docker history --no-trunc loan-api:prod | grep -iE 'password|secret|token|api_key' || echo 'no secrets in image history'"
EOF
bash make_checklist.sh
rm make_checklist.sh