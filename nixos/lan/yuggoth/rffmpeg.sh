echo "$SSH_ORIGINAL_COMMAND" >>/tmp/rffmpeg.log

eval "set -- $SSH_ORIGINAL_COMMAND"

cmd="$1"
shift

case $cmd in
  # whitelisted commands.
  ffmpeg)
    #exec ffmpeg "$@"
    ffmpeg "$@" 2>&1 | tee /tmp/ffmpeg-output.log
    ;;
  ffprobe)
    #exec ffprobe "$@"
    ffprobe "$@" 2>&1 | tee /tmp/ffmpeg-output.log
    ;;
  *)
    echo >&2 "this account can only be used to access ffmpeg (not: $cmd)"
    exit 1
    ;;
esac
