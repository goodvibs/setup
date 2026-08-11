# Work-only: UV with GitLab token from Keychain
#
# Add tokens to Keychain:
#   security add-generic-password -a "$USER" -s uv-gitlab-token-gs -w "YOUR_TOKEN"
#   security add-generic-password -a "$USER" -s uv-gitlab-token-2s -w "YOUR_TOKEN"

uv() {
  local which="${UV_GITLAB_TOKEN:-gs}"
  local token

  case "$which" in
    gs)
      token="$(security find-generic-password -a "$USER" -s uv-gitlab-token-gs -w)" || return 1
      ;;
    2s)
      token="$(security find-generic-password -a "$USER" -s uv-gitlab-token-2s -w)" || return 1
      ;;
    *)
      echo "Unknown UV_GITLAB_TOKEN='$which' (use: gs or 2s)" >&2
      return 2
      ;;
  esac

  UV_INDEX_GITLAB_USERNAME="__token__" \
  UV_INDEX_GITLAB_PASSWORD="$token" \
  command uv "$@"
}

uv-token-toggle() {
  if [[ "${UV_GITLAB_TOKEN:-gs}" == "gs" ]]; then
    export UV_GITLAB_TOKEN=2s
  else
    export UV_GITLAB_TOKEN=gs
  fi
  echo "UV will use token: $UV_GITLAB_TOKEN"
}

uv-token-current() { echo "${UV_GITLAB_TOKEN:-gs}"; }

export PATH=$PATH:$HOME/.ssi/bin
