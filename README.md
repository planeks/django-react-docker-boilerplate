# Django React Docker Boilerplate by PLANEKS

📌 Insert here the project description. Also, change the caption of
the README.md file with name of the project.

## How to start the project

Follow these steps to start the project via Docker: [Project Creation Guide with Docker](docs/local_setup.md)

Follow these steps to start the project without Docker: [Project Creation Guide no Docker](docs/local_setup_no_docker.md)

## 🏃‍ Running the project in IDEs

Follow these steps to run the project in PyCharm:
[Running in PyCharm Guide](docs/pycharm.md)

Follow these steps to run the project in VSCode:
[Running in VSCode Guide](docs/vscode.md)

## Code quality

Linting, formatting, testing, and dependency scanning are configured for both backend and frontend: [Code quality](docs/code-quality.md)

## AI coding agents

Project rules live in [`AGENTS.md`](AGENTS.md), with nested files for
[`src/`](src/AGENTS.md) (Django) and [`src/frontend/`](src/frontend/AGENTS.md) (React) —
agents read the closest one automatically. [`CLAUDE.md`](CLAUDE.md) imports all three for
Claude Code.

Keep them short: only what an agent can't infer from the code and configs. The full
company-wide PLANEKS standards are vendored in `.claude/` and read on demand.

## Deploying the project to the server

- [Automated provisioning with Ansible](docs/deployment_automated.md)
- [Manual server setup](docs/deployment_manual.md)
- [GitHub Actions setup](docs/github-actions-setup.md)

📌 If this document does not contain some important information, feel free to make a pull request.

Additional project info located in the [docs/index.md](docs/index.md) file.
