# Contributing to DevZero Self-Hosted

Thank you for your interest in contributing to **DevZero Self-Hosted**! 

We welcome contributions of all kinds—whether it's a bug fix, a new feature, documentation improvements, or anything else that can help make the project better. 

By participating in this project, you agree to abide by our [Code of Conduct](.github/CODE_OF_CONDUCT.md).

---

## Table of Contents

- [Reporting Issues](#reporting-issues)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)
- [Component-Specific Guidelines](#component-specific-guidelines)
- [Backporting Changes](#backporting-changes)
- [Questions and Communication](#questions-and-communication)

---

## Reporting Issues

If you discover a bug, have a feature request, or need to provide feedback, please open a GitHub issue. When reporting an issue, try to include the following:
- A clear title and detailed description.
- Steps to reproduce the issue.
- Expected and actual behavior.
- Screenshots or logs, if applicable.
- Any relevant labels to help us categorize the issue.

---

## Pull Request Guidelines

When you're ready to contribute code:
1. **Fork and Clone**  
   Fork the repository and clone it to your local machine.
2. **Create a Branch**  
   Create a feature branch from the appropriate base branch (typically `main`).
3. **Make Changes**  
   Implement your changes, ensuring they adhere to the project's coding standards.
4. **Run Tests**  
   Verify that all tests pass locally. Refer to the testing section below for more details.
5. **Update Documentation**  
   Update or add documentation as needed in the corresponding directories.
6. **Commit and Push**  
   Write clear commit messages that reference the related issue (e.g., "fix: Description of fix").
7. **Open a Pull Request**  
   Submit a pull request (PR) with a detailed description of your changes and link any related issues.

---

## Commit Message Guidelines

- Write clear and descriptive commit messages.
- Reference GitHub issues using the format `fix: Message`.
- Follow conventional commit formats if possible, keeping messages brief yet descriptive.

---

## Testing

Before submitting a PR, ensure that your changes pass all tests:

- **Terraform:**  
  Follow the instructions in `terraform/README.md` to build and test the AMI changes.
- **Kata:**  
  Follow the instructions in `kata/README.md` to build and test the AMI changes.
- **Helm Charts:**  
  Follow the instructions in `charts/README.md` to build and test chart changes.
- **DZ Installer:**  
  Follow the instructions in `dz_installer/README.md` to build and test CLI.

We recommend running tests locally to catch issues before opening a PR.

---

## Documentation

Contributions to documentation are highly valued. If you find any documentation gaps or errors:
- Open a PR with your updates.
- Ensure that documentation is clear and consistent with the project’s style.
- For component-specific documentation, please refer to the corresponding README in each directory (e.g., `terraform/README.md`, `charts/README.md`).

---

## Component-Specific Guidelines

**DevZero Self-Hosted** is composed of several components. Each has its own nuances:

- **Kata:**  
  - Builds custom AMIs optimized for Kubernetes nodes.
  - See [kata/README.md](./kata/README.md) for more details.

- **Terraform:**  
  - Contains IaC scripts to provision cloud infrastructure.
  - Refer to [terraform/README.md](./terraform/README.md) for contributing instructions.

- **Helm Charts:**  
  - Packages and deploys the Control Plane and Data Plane.
  - Detailed guidelines can be found in [charts/README.md](./charts/README.md).

- **DZ Installer:**  
  - A CLI tool for installation and environment validation.
  - Check [dz_installer/README.md](./dz_installer/README.md) for specifics.

If your contribution touches more than one component, please ensure your changes are tested and documented for each area.

---

## Backporting Changes

For changes that need to be applied to previous releases:
- Clearly mention in your PR description which release branches should receive the update.
- Follow any additional guidelines provided by the maintainers for backporting.

---

## Questions and Communication

If you have any questions or need help getting started:
- **Open a GitHub Issue:** Describe your query so we can assist you.
- **Email Us:** Reach out at [support@devzero.com](mailto:support@devzero.com).

For more context about the project, please refer to our [README](./README.md).

---

Thank you for contributing to **DevZero Self-Hosted**! Every contribution, no matter how small, is appreciated. We look forward to collaborating with you.

Happy Contributing!
