FROM node:16-bullseye-slim as cli

WORKDIR /usr/src/app

# Install some useful cli tools.
RUN apt-get update && apt-get install -y \
    gettext-base git libsqlite3-dev python3 cmake g++ git vim curl locales sudo

# Add node user to sudoers.
# Refs: https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user#_creating-a-nonroot-user
RUN echo node ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/node \
    && chmod 0440 /etc/sudoers.d/node

# Configure locale.
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install oh-my-bash and configure locale.
ARG USERNAME=node
RUN su -c bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" $USERNAME && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

# Set custom aliases.
RUN echo "alias dc=docker-compose" >>  /etc/bash.bashrc

# We just need this to avoid to create an empty directory
# as root:root when initialized for the first time.
# See https://serverfault.com/a/984599 - https://docs.docker.com/storage/volumes/
# @TODO - Hardcoded src/backstage path must be a variables.
RUN mkdir -p src/backstage/node_modules \
    && chown -R $USERNAME:$USERNAME src/backstage/node_modules

# Set a custom HISTFILE env to keep history where we want.
ENV HISTFILE /dotfiles/.bash_history

FROM node:16-bullseye-slim as run

ARG USERNAME=node
WORKDIR /usr/src/app

# We just need this to avoid to create an empty directory
# as root:root when initialized for the first time.
# See https://serverfault.com/a/984599 - https://docs.docker.com/storage/volumes/
RUN mkdir -p node_modules \
    && chown -R $USERNAME:$USERNAME node_modules

# Configure the entrypoint script.
COPY build/node/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000 7007

ENTRYPOINT ["/entrypoint.sh"]
CMD ["yarn", "dev"]
