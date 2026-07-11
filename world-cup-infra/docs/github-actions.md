# GitHub Actions

## What it does

GitHub Actions is a CI/CD platform built into GitHub. Workflows run in response to events (push, pull request, schedule) in hosted virtual machines. For this project it handles linting, testing, security scanning, building the Docker image, pushing to ECR, and opening the PR on the infra repo that triggers ArgoCD.

## Key concepts

**Workflow** — a YAML file in `.github/workflows/`. Triggered by events. Contains one or more jobs.

**Job** — a group of steps that run on the same runner (virtual machine). Jobs run in parallel by default; use `needs:` to chain them sequentially.

**Step** — a single command or Action within a job. Either a `run:` shell command or `uses:` to reference a pre-built Action.

**Action** — a reusable unit of CI logic published to the GitHub Marketplace. Examples: `actions/checkout`, `aws-actions/configure-aws-credentials`, `docker/build-push-action`.

**Runner** — the virtual machine that executes a job. GitHub-hosted runners are `ubuntu-latest` by default. Self-hosted runners are possible but not used here.

**Secrets** — encrypted values stored in the GitHub repo settings (Settings → Secrets and variables → Actions). Referenced in workflows as `${{ secrets.SECRET_NAME }}`. Never logged.

**OIDC for AWS** — instead of storing an AWS access key as a GitHub secret (a credential that never expires and must be rotated manually), you configure GitHub Actions as an OIDC identity provider in AWS IAM. The workflow requests a short-lived token from GitHub's OIDC endpoint, exchanges it for temporary AWS credentials via STS, and those credentials expire when the job ends. No long-lived secrets.

**Matrix** — run a job multiple times with different inputs (e.g. test across Python 3.11 and 3.12). Not used here but worth knowing.

**`needs:`** — declares that a job requires another to complete first. Creates a dependency graph across jobs.

**`if:`** — conditional execution. Run a job only on `main`, only when tests pass, only when a file changed.

**Service containers** — Docker containers that run alongside a job and are accessible by the steps. Used in the `test` job to spin up a Postgres instance without any external infrastructure.

## Workflow structure for this project

Two workflow files:

**`ci.yml`** — runs on every push and every PR:
- `lint` — ruff
- `test` — pytest with postgres service container
- `sast` — Snyk code scan, SonarQube
- `build` — docker build (does not push on PRs)
- `scan` — Snyk container scan

**`deploy.yml`** — runs only on push to `main` after `ci.yml` passes:
- `push` — push image to ECR tagged with `${{ github.sha }}`
- `update-infra` — open a PR on world-cup-infra updating `values.yaml`

## Required GitHub secrets

| Secret | Value |
|---|---|
| `AWS_ACCOUNT_ID` | Your AWS account ID |
| `AWS_REGION` | e.g. `us-east-1` |
| `ECR_REPOSITORY` | e.g. `world-cup` |
| `SNYK_TOKEN` | From snyk.io account settings |
| `SONAR_TOKEN` | From SonarCloud account settings |
| `SONAR_ORGANIZATION` | Your SonarCloud org slug |
| `INFRA_REPO_TOKEN` | GitHub PAT with `repo` scope, for opening PRs on world-cup-infra |

The `AWS_*` secrets are only needed if you are NOT using OIDC. With OIDC, you do not store AWS credentials at all — only `AWS_ACCOUNT_ID` and `AWS_REGION` are needed (these are not sensitive).

## OIDC setup for keyless AWS auth

1. In AWS IAM, create an OIDC identity provider: `https://token.actions.githubusercontent.com`
2. Create an IAM role with a trust policy allowing GitHub Actions from your specific repo to assume it:

```json
{
  "Condition": {
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:Eniadebisi/world-cup-app:*"
    }
  }
}
```

3. Attach policies to this role: `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`

4. In the workflow, configure credentials:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::<account-id>:role/world-cup-github-actions
    aws-region: us-east-1
```

No access key ever stored in GitHub. Credentials expire when the job ends.

## CLI commands — GitHub CLI

```bash
# Install gh CLI (macOS)
brew install gh

# Authenticate
gh auth login

# View workflow runs for the current repo
gh run list

# View a specific run in detail
gh run view <run-id>

# Watch a run live
gh run watch <run-id>

# Re-run a failed workflow
gh run rerun <run-id>

# View workflow run logs
gh run view <run-id> --log

# List secrets (names only — values are not shown)
gh secret list

# Set a secret
gh secret set SNYK_TOKEN

# Open a PR from the CLI (used in the update-infra job)
gh pr create \
  --title "chore: update world-cup image to <sha>" \
  --body "Automated image tag update from app pipeline" \
  --base main \
  --head chore/update-image-<sha>

# View PRs
gh pr list

# Merge a PR
gh pr merge <pr-number> --squash --delete-branch
```

## The infra repo update step

After pushing the image to ECR, the `update-infra` job:

1. Clones `world-cup-infra`
2. Creates a branch: `chore/update-image-<sha>`
3. Updates `helm/world-cup/values.yaml`: sets `image.tag` to `${{ github.sha }}`
4. Commits and pushes
5. Opens a PR targeting `main`

When you merge the PR, ArgoCD detects the change and syncs the cluster.

This is intentional — the PR gives you a review step before the deploy lands in the cluster. You can auto-merge this PR if you want fully automated deploys, but manual merge is safer while learning.

## Service container for Postgres in tests

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: world-cup
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    env:
      DB_HOST: localhost
      DB_PORT: 5432
      DB_NAME: world-cup
      DB_USER: postgres
      DB_PASSWORD: postgres
    steps:
      - uses: actions/checkout@v4
      - run: pip install -e ".[dev]"
      - run: pytest
```

The service container is accessible at `localhost:5432` from the job steps. The `options` health check ensures Postgres is ready before tests run.

## Common issues

**`Error: Cannot connect to the Docker daemon`** — you are using `docker` commands inside a step without the runner having Docker available. GitHub-hosted `ubuntu-latest` runners have Docker pre-installed. Self-hosted runners may not.

**`AccessDenied` on ECR push** — the IAM role assumed by the workflow does not have the ECR permissions. Check the role's attached policies and the trust policy allows the correct repo.

**`gh: not found`** — the `gh` CLI is not installed in the runner. Add `actions/setup-go` or use `actions/github-script` to open PRs via the GitHub API instead.

**Workflow runs on PRs from forks do not have access to secrets** — this is a GitHub security feature. Snyk and SonarQube steps will fail on external contributor PRs. Use `pull_request_target` for fork PR workflows (carefully — this has security implications).

## Official docs

- [GitHub Actions overview](https://docs.github.com/en/actions)
- [Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Configuring OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Service containers](https://docs.github.com/en/actions/using-containerized-services/about-service-containers)
- [Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)
