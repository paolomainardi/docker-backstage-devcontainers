# Dockerized Backstage.io with Devcontainers

This is a PoC repository to run Backstage.io with Docker and Devcontainers.

The main goal here is to demonstrate how to use Development Containers in a
real-world scenario but leaving open the door to use a standard dockerized workflow.
Another advantage of this approach is **performance**; Docker on macOS suffers of
filesystem performance issues, to fix that:

1. Code `src/backstage` is bind mounted to `/usr/src/app`
1. **OPTIONAL**: Node modules are mounted with a named volume on `src/backstage/node\_modules`

## How is implemented

Let's start by commenting `devcontainer.json`:

```json
{
  "name": "Backstage",

  // When running inside devcontainers we want to use named volumes for node_modules.
  "dockerComposeFile": [
    "../docker-compose.yml",
    "../docker-compose-volumes.yml"
  ],

  // Which docker-compose service to use for the devcontainer instance.
  "service": "cli",

  // https://containers.dev/implementors/json_reference/#variables-in-devcontainerjson
  "workspaceFolder": "${localWorkspaceFolder}",
  "shutdownAction": "stopCompose",
  "userEnvProbe": "loginInteractiveShell",

  // Run it as a non-root user.
  "remoteUser": "node",

  // Just run the cli container, devcontainer does not respect COMPOSE_PROFILES
  "runServices": ["cli"],

  // Add some vscode extensions.
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "ms-vsliveshare.vsliveshare",
        "eamodio.gitlens"
      ]
    }
  },

  // This is useful to have docker and docker-compose working inside the container
  // Ref: https://github.com/devcontainers/features/tree/main/src/docker-from-docker
  "features": {
    "ghcr.io/devcontainers/features/docker-from-docker:1": {
      "dockerDashComposeVersion": "v2"
    }
  }
}
```

And now the docker compose files:

```yaml
# docker-compose.yml

version: "3"
services:
  # This is the development container, can be used
  # with and without devcontainers.
  cli:
    build:
      context: .
      dockerfile: build/node/Dockerfile
      target: cli
    # We use another profile for the cli, to exclude it from running,
    # with a docker-compose up
    profiles: ["cli"]
    env_file:
      - app.env
    volumes:
      # This is used to have the same local path, inside the container.
      - $PWD:$PWD

      # The following volumes are here to keep npm/yarn caching and
      # bash history.
      - ./.cache/yarn:/usr/local/share/.cache/yarn
      - ./.cache/npm:/root/.npm
      - ./.cache/dotfiles:/dotfiles
    # Non root.
    user: node
    hostname: cli

    # Start in the same local root.
    working_dir: $PWD

    # Keep it always running, this is needed by devcontainers.
    command: /bin/sh -c "while sleep 1000; do :; done"

  # This is the container to just run backstage.
  app:
    build:
      context: .
      dockerfile: build/node/Dockerfile
      target: run
    env_file:
      - app.env
    volumes:
      - ./src/backstage/:/usr/src/app
      - ./.cache/yarn:/usr/local/share/.cache/yarn
      - ./.cache/npm:/root/.npm

    # This is the app profile, used to spin up the services with
    # a docker-compose up
    profiles: ["app"]
    ports:
      - 3000:3000
      - 7007:7007
    user: node
    depends_on:
      - db

  db:
    image: postgres:13.3
    volumes:
      - ./database:/usr/src/app
    profiles: ["app"]
    env_file:
      - app.env

---
# docker-compose-volumes.yml

version: "3"
services:
  cli:
    # Adding the named volume on top of the bind mount.
    # NOTE: The volume here must be mounted under the full path of the
    # backstage source code.
    volumes:
      # @TODO - Hardcoded src/backstage path must be a variables.
      - node_modules:$PWD/src/backstage/node_modules
  app:
    # Adding the named volume on top of the bind mount.
    volumes:
      - node_modules:/usr/src/app/node_modules
# Node modules volume.
volumes:
  node_modules:
```

Using or not the named volume must be controlled with `.env` variables:

```shell
# Uncomment this to use a docker volumes for node_modules.
# IT IS REQUIRED when working with devcontainers.

# COMPOSE_FILE=docker-compose.yml:docker-compose-volumes.yml
COMPOSE_PROFILES=app
```
