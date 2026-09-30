# Pipeline Boss

A small Flask web app used as a hands-on learning ground for building a **production-grade CI/CD pipeline** — not just deploying an app, but practicing the operational patterns, environment separation, and safety gates that real engineering teams rely on to ship reliably.

This project is intentionally more elaborate than the app itself needs, on purpose: the goal is to *practice* production-grade pipeline design, not to ship a minimal app.

## What this project is really about

The Flask app itself is simple. The actual learning goals are:

- Structuring a pipeline around **multiple environments** (dev, qa, staging, prod) with increasing levels of confidence required at each stage
- Authenticating CI to cloud infrastructure **without ever storing long-lived credentials**
- Using **security scanning** as an automated gate, not an afterthought
- Keeping **production behind a human approval step**, backed by real evidence (an E2E test report), not just "tests passed"
- Practicing **trunk-based development** instead of long-lived per-environment branches
- Understanding *why* each of these practices exists, not just copying them

## Tech stack

- **App:** Flask (Python)
- **Containerization:** Docker
- **Registry:** AWS ECR
- **Compute:** AWS ECS (Fargate)
- **CI/CD:** GitHub Actions
- **Authentication:** AWS IAM + OIDC (no stored AWS keys, anywhere)
- **Security scanning:** Trivy
- **E2E testing:** Playwright (Python / pytest)

## Environments

All four environments run as separate **ECS services** inside a single shared ECS cluster (not four separate clusters) — a lighter-weight setup than a real company might use, while still preserving the promotion pattern.

| Environment | Purpose |
|---|---|
| **dev** | First deploy target after a merge to `main`. Fast feedback. |
| **qa** | Functional test suite runs here. |
| **staging** | Mirrors production config. Playwright E2E suite runs against this environment before prod is even considered. |
| **prod** | Only reachable after staging passes *and* a human reviewer approves. |

## Branching strategy

This project deliberately avoids a `dev`/`qa`/`staging`/`prod` branch-per-environment model. Long-lived branches per environment tend to drift out of sync with each other over time, and merging between them changes the commit SHA at every step, making it hard to guarantee that what reached production is *exactly* what was tested earlier.

Instead:

- **`main` is the only long-lived branch.**
- All work happens on short-lived feature branches, merged into `main` via **Pull Request**.
- `main` is a **protected branch** — no direct pushes; a PR (with passing checks) is required to merge.
- The **same Docker image**, built once and tagged with its commit SHA, is promoted through every environment — never rebuilt. This guarantees dev, qa, staging, and prod are all running an identical artifact by the time it reaches production.

## Pipeline structure

Three GitHub Actions workflows, chained together explicitly (via `workflow_call`) rather than coordinating through branch pushes:

```
Pull Request → main
    │
    ▼
Testing Pipeline
 ├─ pr-checks        (on PR: unit tests, build sanity check)
 └─ build-and-scan   (on merge to main: build image → push to ECR → Trivy scan)
         │
         ▼
    Deployment
     deploy-dev → deploy-qa → deploy-staging
                                    │
                                    ▼
                          Promote to Prod
                           ├─ e2e-tests    (Playwright against staging,
                           │                report uploaded as an artifact)
                           └─ deploy-prod  (paused — requires reviewer
                                            approval via GitHub Environments)
```

If the Trivy scan fails, the pipeline stops — nothing gets promoted anywhere. If staging's E2E suite fails, prod is never reached. Even if everything passes, **prod deploys only after a human explicitly approves it**, having reviewed the Playwright report.

## Authentication: no stored credentials, anywhere

Rather than storing a static AWS access key in GitHub Secrets, this pipeline uses **OIDC federation**:

- GitHub Actions presents a short-lived, signed identity token to AWS.
- AWS verifies it against an IAM trust policy scoped specifically to this repository.
- AWS hands back **temporary credentials** (roughly an hour's validity) — nothing permanent to leak, nothing to rotate manually.
- The only AWS-related value stored in GitHub Secrets is a **Role ARN** — an identifier, not a credential.

## Local development

```bash
# Run the app locally
pip install -r requirements.txt
python app.py

# Run the Playwright/pytest suite
pip install -r requirements-dev.txt
python -m playwright install --with-deps
python -m pytest tests/ -v
```

## Notes

This is a learning project. Some choices reflect that directly — e.g., a shared ECS cluster instead of four fully isolated ones, and Playwright running only at the staging→prod gate rather than at every stage — made deliberately to balance realistic practice against AWS cost and setup complexity for a solo project.