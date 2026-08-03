{ pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    package = pkgs.unstable.opencode;
  };

  programs.claude-code = {
    enable = true;
  };
}
