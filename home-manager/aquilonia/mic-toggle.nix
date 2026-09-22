{ pkgs, ... }:
let
  sourceDesc = "Ryzen HD Audio Controller Analog Stereo";
  headsetPortDesc = "Headset Microphone";

  toggle-mic = pkgs.writeShellApplication {
    name = "toggle-mic";
    runtimeInputs = [
      pkgs.pulseaudio # pactl
      pkgs.jq
      pkgs.dunst
    ];
    text = ''
      SOURCE_DESC="${sourceDesc}"
      HEADSET_PORT_DESC="${headsetPortDesc}"

      # "Ryzen HD Audio Controller Analog Stereo" is one PipeWire source with
      # multiple ports (visible as "Port" in pavucontrol) - toggle between
      # whichever port is active and the headset mic port.
      source=$(pactl -f json list sources | jq -c --arg desc "$SOURCE_DESC" '.[] | select(.description == $desc)')

      if [ -z "$source" ]; then
        dunstify "Mic toggle" "Couldn't find source \"$SOURCE_DESC\""
        exit 1
      fi

      source_name=$(jq -r '.name' <<<"$source")
      active_port=$(jq -r '.active_port' <<<"$source")
      active_port_desc=$(jq -r --arg p "$active_port" '.ports[] | select(.name == $p) | .description' <<<"$source")

      if [ "$active_port_desc" = "$HEADSET_PORT_DESC" ]; then
        target_port=$(jq -r --arg p "$active_port" '.ports[] | select(.name != $p) | .name' <<<"$source" | head -1)
        target_desc=$(jq -r --arg p "$active_port" '.ports[] | select(.name != $p) | .description' <<<"$source" | head -1)
      else
        target_port=$(jq -r --arg desc "$HEADSET_PORT_DESC" '.ports[] | select(.description == $desc) | .name' <<<"$source")
        target_desc="$HEADSET_PORT_DESC"
      fi

      if [ -z "$target_port" ]; then
        dunstify "Mic toggle" "Couldn't find the port to switch to"
        exit 1
      fi

      pactl set-source-port "$source_name" "$target_port"
      dunstify "Mic toggle" "$target_desc"
    '';
  };
in
{
  home.packages = [ toggle-mic ];
}
