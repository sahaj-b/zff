#!/usr/bin/env bash
trap '{ printf "\033_Ga=d,d=A\033\\" > /dev/tty 2>/dev/null; } 2>/dev/null; exit 0' EXIT TERM INT HUP

printf '\033[2J\033[H'

path="$(echo "$1" | sed 's/^[^ ]* //;s|^~|'"$HOME"'|')"

if [[ ! -f "$path" ]]; then
  echo "File not found: $path"
  exit 1
fi

mime_type=$(file --mime-type -b "$path")

# ---------------------------------------------------------------------------
# Detect graphics protocol — mirrors Yazi's Emulator::detect()
# ---------------------------------------------------------------------------
detect_graphics() {
  case "${TERM:-}" in
  xterm-kitty)
    PROTOCOL=kgp
    return
    ;;
  foot | foot-extra)
    PROTOCOL=sixel
    return
    ;;
  xterm-ghostty)
    PROTOCOL=kgp
    return
    ;;
  rio)
    PROTOCOL=kgp
    return
    ;;
  rxvt-unicode-256color)
    PROTOCOL=sixel
    return
    ;;
  esac
  case "${TERM_PROGRAM:-}" in
  WezTerm | ghostty | WarpTerminal | rio)
    PROTOCOL=kgp
    return
    ;;
  esac
  [[ -n "$KITTY_WINDOW_ID" ]] && {
    PROTOCOL=kgp
    return
  }
  [[ -n "$WEZTERM_EXECUTABLE" ]] && {
    PROTOCOL=kgp
    return
  }
  [[ -n "$GHOSTTY_RESOURCES_DIR" ]] && {
    PROTOCOL=kgp
    return
  }
  [[ -n "$KONSOLE_VERSION" ]] && {
    PROTOCOL=sixel
    return
  }

  # Phase 2: CSI probe — KGP query + DA1, parse combined response
  local _oldstty _resp="" _char
  _oldstty="$(stty -g 2>/dev/null)" || {
    _fallback
    return
  }
  stty raw -echo min 0 time 2 2>/dev/null
  printf '\033_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\033\\\033[0c' >&2
  while IFS= read -r -N1 -t 0.1 _char 2>/dev/null; do
    _resp+="${_char}"
    [[ "$_char" == "c" && "$_resp" == *$'\033['\?* ]] && break
  done
  stty "$_oldstty" 2>/dev/null

  [[ "$_resp" == *$'\033'_G*i=31*OK* ]] && {
    PROTOCOL=kgp
    return
  }
  [[ "$_resp" =~ (\?4[;c]\|;4[;c]) ]] && {
    PROTOCOL=sixel
    return
  }
  [[ "$_resp" == *"kitty"* || "$_resp" == *"ghostty"* || "$_resp" == *"WezTerm"* ]] && {
    PROTOCOL=kgp
    return
  }
  _fallback
}

_fallback() {
  if command -v chafa &>/dev/null || command -v img2sixel &>/dev/null; then
    PROTOCOL=sixel
  else
    PROTOCOL=none
  fi
}

# ---------------------------------------------------------------------------
# KGP via kitten icat
# ---------------------------------------------------------------------------
_show_image_kgp() {
  local file="$1"
  local cols="${FZF_PREVIEW_COLUMNS:-80}"
  local rows="${FZF_PREVIEW_LINES:-24}"
  ((cols < 1 || rows < 1)) && return

  local total_cols total_rows
  total_cols=$(tput cols 2>/dev/null || echo 80)
  total_rows=$(stty size </dev/tty 2>/dev/null | awk '{print $1}' || echo 24)

  local left top
  if [[ -n "$FZF_PREVIEW_LEFT" ]]; then
    left="$FZF_PREVIEW_LEFT"
  elif ((cols < total_cols)); then
    left=$((total_cols - cols))
  else
    left=0
  fi

  if [[ -n "$FZF_PREVIEW_TOP" ]]; then
    top="$FZF_PREVIEW_TOP"
  elif ((rows < total_rows)); then
    top=$((total_rows - rows))
  else
    top=0
  fi

  kitten icat \
    --clear \
    --transfer-mode=memory \
    --stdin=no \
    --place="${cols}x${rows}@${left}x${top}" \
    "$file" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Raw KGP escape sequences
# Uses native kitty scaling via c/r keys, streams PNG via base64 chunks
# ---------------------------------------------------------------------------
_show_image_kgp_raw() {
  local file="$1"
  local cols="${FZF_PREVIEW_COLUMNS:-80}"
  local rows="${FZF_PREVIEW_LINES:-24}"
  ((cols < 1 || rows < 1)) && return

  # 1) Delete all previous placements
  printf '\033_Ga=d,d=A\033\\'

  # 2) Base64-encode the PNG into 4096-byte chunks (always multiples of 4)
  local -a chunks
  mapfile -t chunks < <(base64 -w 4096 "$file" 2>/dev/null || base64 -b 4096 "$file" 2>/dev/null)
  local n=${#chunks[@]}
  ((n == 0)) && return

  # 3) Stream chunks via KGP APC sequences
  #    a=T  → transmit + display
  #    f=100 → PNG format
  #    c/r  → native kitty scaling to cell area
  #    C=1  → no cursor movement
  #    q=2  → suppress terminal responses
  local meta="a=T,f=100,c=${cols},r=${rows},C=1,q=2"
  for ((i = 0; i < n; i++)); do
    local m=$((i == n - 1 ? 0 : 1))
    if ((i == 0)); then
      printf '\033_G%s,m=%d;%s\033\\' "$meta" "$m" "${chunks[$i]}"
    else
      printf '\033_Gm=%d;%s\033\\' "$m" "${chunks[$i]}"
    fi
  done

  # 4) Move cursor past the image so fzf doesn't overlap text
  printf '\033[%dB' "$rows"
}

# ---------------------------------------------------------------------------
# Sixel fallback
# ---------------------------------------------------------------------------
_show_image_sixel() {
  local file="$1"
  local dim="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}"
  if command -v chafa &>/dev/null; then
    chafa -f sixel -s "$dim" "$file" 2>/dev/null || chafa -s "$dim" "$file"
    echo
  elif command -v img2sixel &>/dev/null; then
    img2sixel -w "${dim%%x*}" "$file"
  else
    echo "[Image] $file"
    echo "Install chafa or img2sixel for image preview"
  fi
}

# ---------------------------------------------------------------------------
# Dispatch: show image/video with the best available protocol
# ---------------------------------------------------------------------------
_show_preview() {
  local file="$1"

  case "$PROTOCOL" in
  kgp)
    if command -v kitten &>/dev/null; then
      _show_image_kgp "$file"
    else
      _show_image_kgp_raw "$file"
    fi
    ;;
  sixel)
    _show_image_sixel "$file"
    ;;
  *)
    echo "[Image] $file"
    ;;
  esac
}

# ---------------------------------------------------------------------------
# Main dispatcher
# ---------------------------------------------------------------------------
detect_graphics

case "$mime_type" in
image/*)
  _show_preview "$path"
  ;;

video/*)
  thumbnail=$(mktemp --suffix=.jpg)
  trap 'rm -f "$thumbnail"' EXIT
  if ffmpegthumbnailer -i "$path" -o "$thumbnail" -s 0 &>/dev/null; then
    _show_preview "$thumbnail"
  else
    echo "[Video]"
    echo "$path"
    echo "ffmpegthumbnailer not found or failed"
  fi
  ;;

application/pdf | application/epub+zip)
  echo "[Document]"
  echo "$path"
  ;;

*)
  if command -v bat &>/dev/null; then
    bat --color=always --plain "$path"
  else
    cat "$path"
  fi
  ;;
esac
