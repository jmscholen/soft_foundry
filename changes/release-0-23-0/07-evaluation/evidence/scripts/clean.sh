# Strips the bundler/session environment the runner leaks; mimics a CI runner's
# absence of provider keys and of a global git identity.
clean() {
  env -i PATH="/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    HOME="${SF_HOME:-$HOME}" TMPDIR="${TMPDIR:-/tmp}" LANG=en_US.UTF-8 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
    "${@}"
}
