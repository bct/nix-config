{ pkgs, lib, ... }:

# original:
# https://github.com/SmarakNayak/nixos-config/blob/14a10aaf707f9160b0f19633a93b9ee93b64c881/packages/claude-sandbox.nix#L26
#
# Sandboxed Claude Code using bubblewrap
#
# --unshare-all        isolates all namespaces (pid, ipc, uts, mount, user, cgroup)
# --share-net          re-enables network so Claude can reach the Anthropic API
# --uid/--gid          preserves real uid/gid inside the user namespace (default would be root)
# --proc/--dev         minimal proc and dev filesystems required for programs to run
# --tmpfs /tmp         fresh tmp to avoid leaks from other processes
# --ro-bind /nix       actual binaries live here
# --symlink /bin/sh    claude spawns statusline/hooks via posix_spawn('/bin/sh');
#                      target is already inside the sandbox, this just names it
# --ro-bind /etc       ssl certs, dns, tls etc (--tmpfs /etc/ssh to remove SSH config with readonly perms)
# --ro-bind /run/current-system  symlinks to /nix/store binaries (needed for PATH)
# --tmpfs $HOME        blank home - hides ssh keys, dotfiles, shell history, credentials
# --bind ~/.claude(s)     punch through claude state and config for persistence
# --ro-bind ~/.config/git/config  git needs user identity
# --ro-bind ~/.config/git/ignore  global gitignore (e.g. .claude/settings.local.json)
# --ro-bind ~/.ssh/known_hosts    host key verification for SSH git remotes
# --bind $SSH_AUTH_SOCK                ssh agent socket (set by UWSM) for git push/pull over ssh urls
# --bind $PWD          read-write access to the project directory
# xdg-dbus-proxy       proxies the real D-Bus session bus through a filtered
#                      socket that only allows org.freedesktop.Notifications,
#                      so hooks can call dunstify without granting the sandbox
#                      full session bus access (which could talk to any app)
# --ro-bind .../bus    bind-mount the *filtered* proxy socket (not the real
#                      bus) into the sandbox at the expected bus path
let
  claude-sandbox = pkgs.writeShellScriptBin "claude-sandbox" ''
    mkdir -p "$HOME/.claude"
    touch "$HOME/.claude.json"

    # https://github.com/containers/bubblewrap/issues/555
    # --new-session is important for security. we don't need it as long as
    # LEGACY_TIOCSTI is disabled.
    if [ "$(sysctl -n dev.tty.legacy_tiocsti)" -ne 0 ]; then
      echo "refusing to start when LEGACY_TIOCSTI  is enabled"
      exit
    fi

    proxy_dir=$(mktemp -d)
    trap 'kill "$proxy_pid" 2>/dev/null; rm -rf "$proxy_dir"' EXIT

    ${lib.getExe pkgs.xdg-dbus-proxy} \
      "$DBUS_SESSION_BUS_ADDRESS" "$proxy_dir/bus" \
      --filter --talk=org.freedesktop.Notifications &
    proxy_pid=$!

    until [ -S "$proxy_dir/bus" ]; do sleep 0.05; done

    ${lib.getExe pkgs.bubblewrap} \
      --unshare-all --share-net \
      --uid "$(id -u)" --gid "$(id -g)" \
      --proc /proc --dev /dev --tmpfs /tmp \
      --ro-bind /nix /nix \
      --symlink /run/current-system/sw/bin/sh /bin/sh \
      --symlink /run/current-system/sw/bin/env /usr/bin/env \
      --ro-bind /etc /etc --tmpfs /etc/ssh \
      --ro-bind-try /run/current-system /run/current-system \
      --tmpfs "$HOME" \
      --ro-bind "$HOME/.nix-profile" "$HOME/.nix-profile" \
      --bind "$HOME/.claude" "$HOME/.claude" --bind "$HOME/.claude.json" "$HOME/.claude.json" \
      --bind "$PWD" "$PWD" --chdir "$PWD" \
      --ro-bind "$proxy_dir/bus" "/run/user/$(id -u)/bus" \
      --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=/run/user/$(id -u)/bus" \
      -- ${lib.getExe pkgs.unstable.claude-code} "$@"
    exit $?

      #--ro-bind-try "$HOME/.config/git/config" "$HOME/.config/git/config" \
      #--ro-bind-try "$HOME/.config/git/ignore" "$HOME/.config/git/ignore" \
      #--ro-bind-try "$HOME/.ssh/known_hosts" "$HOME/.ssh/known_hosts" \
      #--bind-try "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK" \
  '';
in

{
  programs.opencode = {
    enable = true;
    package = pkgs.unstable.opencode;
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.unstable.claude-code;

    settings = {
      syntaxHighlightingDisabled = false;
      effortLevel = "medium";
      theme = "dark";
      hooks = {
        Stop = [
          {
            hooks = [
              {
                # this doesn't work because DBUS isn't available?
                type = "command";
                command = "dunstify 'Claude Code' 'Task completed!'";
              }
            ];
          }
        ];
        Notification = [
          {
            hooks = [
              {
                # this doesn't work because DBUS isn't available?
                type = "command";
                command = "dunstify 'Claude Code' 'Awaiting your input!'";
              }
            ];
          }
        ];
      };
    };
  };

  services.podman = {
    enable = true;
  };

  home.packages = [
    claude-sandbox
  ];
}
