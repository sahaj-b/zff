#!/usr/bin/env bash
path="$1"

if [[ ! -f "$path" ]]; then
  echo "File not found: $path"
  return 1
fi

mime_type=$(file --mime-type -b "$path")

show_image() {

  if command -v chafa &>/dev/null; then
    if [[ "$TERM" == "xterm-kitty" ]]; then
      chafa -f kitty -s "${FZF_PREVIEW_COLUMNS}" "$1"
      return
    fi
    chafa -f sixel -s "${FZF_PREVIEW_COLUMNS}" "$1" || chafa -s "${FZF_PREVIEW_COLUMNS}" "$1"
  elif command -v img2sixel &>/dev/null; then
    img2sixel -w "${FZF_PREVIEW_COLUMNS}" "$1"
  else
    echo "[Image]"
    echo "$1"
    echo "install chafa or img2sixel for image preview"
  fi
}

# The grand dispatcher.
case "$mime_type" in
image/*)
  show_image "$path"
  ;;

video/*)
  thumbnail=$(mktemp --suffix=.jpg)
  trap 'rm -f "$thumbnail"' EXIT

  if ffmpegthumbnailer -i "$path" -o "$thumbnail" -s 0 &>/dev/null; then
    show_image "$thumbnail"
  else
    echo "[Video]"
    echo "$path"
    echo "ffmpegthumbnailer not found or failed to create thumbnail"
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
