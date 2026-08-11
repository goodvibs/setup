# Agent Instructions (Global)

- When making technical decisions, do not give any credence to development cost/time. Instead, always shoot for the best possible design.
- Always understand project context and conventions before making any changes or running any commands. For example, if a project directory contains a Makefile, prefer running appropriate `make` commands over manually crafted ones.
- When working on a PR/MR, follow these practices:
  - Ensure that linting checks are green on every commit. It is bad practice to layer style fixing or formatting fixing commits on top of offending commits.
  - Separate commits by logic/semantics instead of some superficial or arbitrary grouping.
  - Ensure that every commit is part of one cohesive story. It is unacceptable for one commit to contain changes that are undone or overhauled by a later commit.
  - When doing complex changes, keep commits simple and easy to understand, but do not compromise on design. For example, if refactoring a file involves extracting some code into a different file and making changes to the logic, keep the code extraction in one commit and the logic changes in the next commit.
