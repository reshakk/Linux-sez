#/usr/bin/env bash

function install_docker {
  if ! which docker >/dev/null 2>&1; then
    curl -fsSL -m 5 https://get.docker.com | bash
    systemctl enable --now docker
    docker_cmd="docker compose"
    return 0
  fi
  if docker compose >/dev/null 2>&1; then
    docker_cmd="docker compose"
    return 0
  fi
  if which docker-compose >/dev/null 2>&1; then
    docker_cmd="docker-compose"
    return 0
  fi
  curl -fsSL -m 30 https://github.com/docker/compose/releases/download/v2.28.0/docker-compose-linux-$(uname -m) -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  docker_cmd="docker-compose"
  return 0
}

