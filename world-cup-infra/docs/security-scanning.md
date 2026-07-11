# Security Scanning — Snyk and SonarQube

## What they do

**Snyk** — scans for known vulnerabilities in three places: your Python dependencies (SAST/SCA), your Dockerfile and base image (container scanning), and your infrastructure-as-code manifests (IaC scanning). It checks against a continuously updated vulnerability database and blocks CI if critical issues are found.

**SonarQube / SonarCloud** — static code analysis focused on code quality and security. Detects security hotspots (e.g. hardcoded credentials, SQL injection patterns, insecure deserialization), code smells, and test coverage gaps. SonarCloud is the hosted version — free for public repos, paid for private. You can also self-host SonarQube for free.

The distinction: Snyk focuses on known CVEs in dependencies and container layers. SonarQube focuses on your code logic and quality. Both are needed because they catch different classes of issues.

## Snyk

### How it works

Snyk reads your `pyproject.toml` (or `requirements.txt`), resolves the full dependency tree, and checks every package version against the Snyk vulnerability database. It reports CVEs, their severity (Critical/High/Medium/Low), and whether a fix is available.

For container scanning, it pulls your built image layers and checks every OS package and Python package installed in the image.

### Setup

1. Create a free account at [snyk.io](https://snyk.io)
2. Copy your API token from Account Settings
3. Add it as a GitHub Actions secret: `SNYK_TOKEN`

### In the GitHub Actions workflow

```yaml
- name: Snyk dependency scan
  uses: snyk/actions/python@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  with:
    args: --severity-threshold=high --file=pyproject.toml

- name: Snyk container scan
  uses: snyk/actions/docker@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  with:
    image: ${{ env.IMAGE_URI }}
    args: --severity-threshold=high
```

`--severity-threshold=high` means only Critical and High findings block the pipeline. Medium and Low are reported but do not fail the build.

### CLI commands (local)

```bash
# Install Snyk CLI
npm install -g snyk

# Authenticate
snyk auth

# Scan Python dependencies
snyk test --file=pyproject.toml

# Scan with a severity threshold (exit 0 unless High or Critical found)
snyk test --file=pyproject.toml --severity-threshold=high

# Scan a Docker image
snyk container test world-cup:latest --severity-threshold=high

# Scan Terraform IaC files
snyk iac test terraform/

# Open issues in browser (Snyk web dashboard)
snyk monitor --file=pyproject.toml

# Generate an SBOM (Software Bill of Materials)
snyk sbom --format=cyclonedx+json --file=pyproject.toml > sbom.json

# Ignore a specific vulnerability (with expiry and reason)
snyk ignore --id=SNYK-PYTHON-SOMEPACKAGE-123456 \
  --expiry=2025-12-31 \
  --reason="No fix available; mitigated by network isolation"
```

### Reading Snyk output

Snyk output shows:

```
✗ High severity vulnerability found in requests
  Description: Certificate verification disabled
  Info: https://snyk.io/vuln/SNYK-PYTHON-REQUESTS-123
  Introduced through: httpx@0.27.0 > requests@2.31.0
  Fixed in: requests@2.32.0
```

Key fields: severity, affected package, how it was introduced (which direct dependency pulled it in), and whether a fix version exists.

**Triaging findings:**
- If a fix version exists, upgrade the package
- If no fix exists, assess exploitability in your context and use `snyk ignore` with a documented reason and expiry date
- False positives (finding is in a code path never executed) can also be ignored with a reason

## SonarQube / SonarCloud

### How it works

SonarQube runs static analysis on your Python source code. It parses the AST and applies rules across several categories:

- **Security hotspots** — code that might be a security issue and needs human review (e.g. a `random` module call — is it used for cryptography?)
- **Vulnerabilities** — confirmed security issues (e.g. hardcoded password, SQL built with string concatenation)
- **Code smells** — maintainability issues (e.g. a function too complex, dead code, too many parameters)
- **Coverage** — percentage of code covered by tests

The quality gate is a set of conditions (e.g. no new Criticals, coverage above 80%) that must pass for the build to succeed.

### Setup (SonarCloud — hosted)

1. Create an account at [sonarcloud.io](https://sonarcloud.io) (log in with GitHub)
2. Import the `world-cup-app` repository
3. Generate a token in your SonarCloud account settings
4. Add as a GitHub Actions secret: `SONAR_TOKEN`
5. Note your organization key (shown in SonarCloud UI): add as `SONAR_ORGANIZATION`

### In the GitHub Actions workflow

```yaml
- name: SonarCloud scan
  uses: SonarSource/sonarcloud-github-action@master
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  with:
    args: >
      -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }}
      -Dsonar.projectKey=world-cup-app
      -Dsonar.python.coverage.reportPaths=coverage.xml
```

A `sonar-project.properties` file in your repo root configures the project key, exclusions, and quality gate settings.

### `sonar-project.properties`

```properties
sonar.projectKey=world-cup-app
sonar.sources=src
sonar.tests=tests
sonar.python.version=3.12
sonar.exclusions=**/__pycache__/**,**/.venv/**
sonar.coverage.exclusions=tests/**
```

### CLI commands (local with self-hosted SonarQube)

```bash
# Pull and run SonarQube locally (for learning)
docker run -d --name sonarqube -p 9000:9000 sonarqube:community

# Wait ~60 seconds, then open http://localhost:9000
# Default credentials: admin / admin (change on first login)

# Install sonar-scanner CLI
brew install sonar-scanner   # macOS
# or download from: https://docs.sonarqube.org/latest/analyzing-source-code/scanners/sonarscanner/

# Run a scan against local SonarQube
sonar-scanner \
  -Dsonar.projectKey=world-cup-app \
  -Dsonar.sources=src \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<your-local-token>

# Generate pytest coverage report (required for SonarQube coverage)
pytest --cov=src --cov-report=xml:coverage.xml
```

### Reading SonarQube results

In the SonarCloud UI or local dashboard:

- **Security hotspots** — need human review. Click each one and mark as Safe, Fixed, or Acknowledged.
- **Quality Gate** — passes or fails. Failing gate should block the PR merge.
- **Issues** tab — all findings sorted by severity. Click an issue to see the file and line.

Common Python findings to know:
- `S105` — hardcoded password detected
- `S106` — hardcoded credentials in function call
- `S107` — hardcoded password in function argument
- `S2076` — OS command injection risk
- `S3776` — cognitive complexity too high (function is too complex)

## IaC scanning with Trivy (bonus)

Trivy is a multi-purpose scanner used alongside Snyk. It scans Terraform files, Helm charts, and Kubernetes manifests for misconfigurations.

```bash
# Install Trivy
brew install aquasecurity/trivy/trivy

# Scan Terraform directory
trivy config terraform/

# Scan Helm chart
trivy config helm/world-cup/

# Scan with a specific severity
trivy config --severity HIGH,CRITICAL terraform/

# Output as JSON
trivy config --format json --output trivy-report.json terraform/

# Suppress known false positives via .trivyignore
echo "AVD-AWS-0101" >> .trivyignore  # No NAT Gateway — intentional budget decision
```

In CI, add a step after the Terraform plan in the infra repo pipeline.

## Official docs

- [Snyk CLI reference](https://docs.snyk.io/snyk-cli/cli-reference)
- [Snyk GitHub Actions](https://github.com/snyk/actions)
- [SonarCloud GitHub integration](https://docs.sonarcloud.io/getting-started/github/)
- [SonarQube Python rules](https://rules.sonarsource.com/python/)
- [Trivy config scanning](https://aquasecurity.github.io/trivy/latest/docs/scanner/misconfiguration/)
