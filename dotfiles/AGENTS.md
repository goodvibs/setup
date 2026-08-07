# Agent Instructions (Global)

- When writing commit messages, NEVER auto-add your agent name as co-author
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- Always understand project context and conventions before making any changes or running any commands. For example, if a project directory contains a Makefile, prefer running appropriate `make` commands over manually crafted ones.
- Prefer keeping individual commits in a PR/MR green. Fixing up bad commits is almost always better than layering "fix" or "formatting" commits on top.
