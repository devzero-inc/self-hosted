# Helm Chart Versioning Strategy

This document defines the versioning approach for Helm charts in the **self-hosted** repository. It ensures consistency and automation in chart updates and releases.

## 📌 Versioning Approach

We follow **Semantic Versioning (MAJOR.MINOR.PATCH)** for Helm charts:

- **MAJOR (X.0.0)** – Breaking changes that are incompatible with previous versions.
- **MINOR (0.X.0)** – Backward-compatible feature additions or improvements.
- **PATCH (0.0.X)** – Bug fixes, documentation updates, or minor changes.

## 📌 Versioning Rules for Chart Changes

| Change Type            | Version Increment|     Example     |
|------------------------|------------------|-----------------|
| **Breaking change**    | **MAJOR**        | `1.0.0 → 2.0.0` |
| **New feature**        | **MINOR**        | `1.1.0 → 1.2.0` |
| **Bug fix / small update** | **PATCH**    | `1.1.1 → 1.1.2` |

## 📌 Updating `Chart.yaml` Versions

Each Helm chart has a `Chart.yaml` file that contains the **chart version** and the **application version**. When making changes:

1. **Determine the required version bump** (MAJOR, MINOR, or PATCH).
2. **Update `Chart.yaml`** for the relevant Helm chart:

   ```yaml
   version: 1.2.3   # New chart version
   appVersion: "v1.2.3"  # Corresponding app version
   ```

3. **Update the `CHANGELOG.md`** with details of the change.
4. **Commit the changes and push them to the repository.**

## 📌 Automated Versioning via GitHub Actions

To automate versioning, the pipeline follows these rules:

- **`feat:`** → Increases **MINOR** version.
- **`fix:`** → Increases **PATCH** version.
- **`major:`** → Increases **MAJOR** version.

### 🔹 How the Pipeline Works:
1. Extract the latest Git tag to determine the current version.
2. Increment the version based on commit messages.
3. Update `Chart.yaml` with the new version.
4. Commit and tag the new version.
5. Package and publish the Helm chart to **Docker Hub** or a Helm repository.

## 📌 Example Commit Messages and Version Updates

| Commit Message                           |   Version Bump  |
|------------------------------------------|-----------------|
| `feat: Add TLS support`                  | `0.1.6 → 0.2.0` |
| `fix: Resolve ingress issue`             | `0.1.6 → 0.1.7` |
| `major: Change API structure`            | `1.3.2 → 2.0.0` |

## 📌 Maintaining Release Notes

All version changes must be documented in `CHANGELOG.md`. The changelog will be automatically updated by the CI/CD pipeline based on commit messages and version increments. Example:

```markdown
## [1.2.3] - 2025-02-03
### Added
- Support for custom TLS certificates.
```

## 📌 Rolling Back to a Previous Version

If you need to roll back to a previous Helm chart version, follow these steps:

1. **Identify** the previous chart version from the Git tags or `CHANGELOG.md`.
2. **Install** the previous version using the Helm command:

   ```bash
   helm install <release-name> <chart-name> --version <previous-version>
   ```