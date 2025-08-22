#!/usr/bin/env bash

# -------- CONFIG --------
# EDIT YOUR CONFIG IN ~/.config/zff/config.sh. these are just defaults
# 1 byte chars ONLY
oldfilesIcon=''
zoxideIcon='󱐌'
cwdIcon='󰚡'
zoxideDepth=6 # how deep to search in zoxide dirs
zoxideThreshold=0.5 # minimum score to consider a zoxide dir
cwdDepth=8 # how deep to search in cwd
copyCmd='wl-copy' # command to copy to clipboard (eg: wl-copy,pbcopy,xclip,xsel)
bashInsertKey='\C-t' # keybind for inserter in bash

# ignore patterns
fd_ignores=(
  '**/.git/**' '**/node_modules/**' '**/.cache/**' '**/.venv/**' '**/.vscode/**' '**/.pycache__/**' '**/.DS_Store'
  '**/.idea/**' '**/.mypy_cache/**' '**/.pytest_cache/**' '**/.next/**' '**/dist/**' '**/build/**' '**/target/**' '**/.gradle/**'
  '**/.terraform/**' '**/.egg-info/**' '**/.env' '**/.history' '**/.svn/**' '**/.hg/**' '**/.Trash/**' '**/bin/**' '**/.bin/**'
  "**/.local/share/Trash/**" "**/.local/share/nvim/**" "**/pkg/**"
  
  # Build artifacts and temp files
  '**/CMakeCache.txt' '**/CMakeFiles/**' '**/Makefile' '**/*.o' '**/*.obj' '**/*.a' '**/*.so' '**/*.dll' '**/*.dylib'
  '**/*.exe' '**/*.class' '**/*.jar' '**/*.war' '**/*.pyc' '**/*.pyo' '**/*.pyd' '**/__pycache__/**' '**/*.whl'
  '**/coverage/**' '**/.coverage' '**/.nyc_output/**' '**/htmlcov/**' '**/coverage.xml'
  
  # Lock files and package managers
  '**/package-lock.json' '**/yarn.lock' '**/pnpm-lock.yaml' '**/Pipfile.lock' '**/poetry.lock' '**/Cargo.lock'
  '**/composer.lock' '**/Gemfile.lock' '**/go.sum' '**/mix.lock'
  
  # OS and system files
  '**/.DS_Store' '**/Thumbs.db' '**/desktop.ini' '**/*.lnk' '**/System Volume Information/**'
  '**/lost+found/**' '**/.fseventsd/**' '**/.Spotlight-V100/**' '**/.TemporaryItems/**'
  
  # Database files
  '**/*.db' '**/*.sqlite' '**/*.sqlite3' '**/*.mdb' '**/*.accdb'
  
  # Archives
  '**/*.zip' '**/*.rar' '**/*.7z' '**/*.tar' '**/*.tar.gz' '**/*.tar.bz2' '**/*.tar.xz' '**/*.gz' '**/*.bz2' '**/*.xz'
  
  # Font files
  '**/*.ttf' '**/*.otf' '**/*.woff' '**/*.woff2' '**/*.eot'
  
  # Virtual environments and containers
  '**/.venv/**' '**/venv/**' '**/env/**' '**/.virtualenv/**' '**/virtualenv/**'
  '**/Dockerfile.*' '**/.dockerignore'
  
  # Testing and coverage
  '**/.pytest_cache/**' '**/.coverage' '**/coverage/**' '**/.nyc_output/**' '**/junit.xml'
)

# function to open the selected file
openFile() {
  if file --mime-type -b "$1" | grep -E -q 'text/|application/(json|javascript|xml|csv|x-yaml)';then
    ${EDITOR:-nvim} "$1"
  else
    xdg-open "$1" &>/dev/null &
  fi
}

# load user config
configPath="${XDG_CONFIG_HOME:-$HOME/.config}/zff/config.sh"
if [[ -f "$configPath" ]]; then
  source "$configPath"
fi

# ------------------------


# SCRIPT-PATH DETECTION for zff-preview
if [[ -n "$ZSH_VERSION" ]]; then
  SCRIPT_DIR="${0:a:h}"
elif [[ -n "$BASH_VERSION" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
else
  # less reliable
  SCRIPT_DIR=$(dirname "$(readlink -f "$0" || echo "$0")")
fi

_zff_selector() {
  local previewCmd="$SCRIPT_DIR/zff-preview.sh "'$(echo {} | sed "s|^~|'"$HOME"'|")'

  local fd_excludes=()
  for pat in "${fd_ignores[@]}"; do
    fd_excludes+=(--exclude "$pat")
  done

  {
    # Priority 0: (n)vim oldfiles
    get_oldfiles

    # Priority 1: CWD
    fd -t f -H -d "$cwdDepth" "${fd_excludes[@]}" . "$PWD" 2>/dev/null | sed "s/^/$cwdIcon /"

    # Priority 2: Zoxide dirs
    if command -v zoxide &>/dev/null; then
      get_zoxide_files
    fi

   } |
     sed -E "s|^(.[^ ]* )$HOME|\1~|" |
     fzf --height 50% --layout reverse --info=inline \
       --scheme=path --tiebreak=index \
       --cycle --ansi --preview-window 'right:40%' \
       --bind="ctrl-c:execute-silent(echo {} | sed 's|^~|$HOME|' | $copyCmd)+abort" \
       --query "'" --multi --preview "$previewCmd" |
     sed 's/^..//' | # remove prefix
     sed "s|^~|$HOME|" # expand tilde

}


get_oldfiles() {
  local snacks_db="$HOME/.local/share/nvim/snacks/picker-frecency.sqlite3"
  if command -v sqlite3 &>/dev/null && [[ -f "$snacks_db" ]]; then
    sqlite3 "$snacks_db" "SELECT key,value FROM data ORDER BY value DESC;" | \
    awk -v icon="$oldfilesIcon" 'BEGIN{FS="|"} {printf "%s %s\n", icon, $1}'
  else
    # fallback to neovim oldfiles
    if command -v nvim >/dev/null 2>&1; then
      nvim --headless -c 'redir! >/dev/stdout | silent oldfiles | quit!' | \
      sed 's/^[ 0-9:]*//' | \
      awk -v icon="$oldfilesIcon" '{printf "%s %s\n", icon, $0}'
      return 0
    else
      # Fallback to vim oldfiles
      sed -n 's/^> //p' "$HOME/.viminfo" 2>/dev/null | \
      awk -v icon="$oldfilesIcon" '{printf "%s %s\n", icon, $0}'
    fi
  fi

}


get_zoxide_files() {
  local zoxide_dirs
  zoxide_dirs=$(zoxide query --list --score 2>/dev/null)
  local filtered_dirs=()
  while IFS= read -r line; do
    filtered_dirs+=("$line")
  done < <(echo "$zoxide_dirs" | awk -v threshold="$zoxideThreshold" '
    {
      if ($1 >= threshold) {
        path = substr($0, index($0,$2))
        printf "%s\n", path
      }
    }')
  if [[ ${#filtered_dirs[@]} -eq 0 ]]; then
    return 0
  fi
  fd -H -d "$zoxideDepth" "${fd_excludes[@]}" . "${filtered_dirs[@]}" 2>/dev/null | \
    sed "s/^/$zoxideIcon /"
}


# main function (opener)
zff() {
  local target_file
  target_file=$(_zff_selector)
  if [[ -n "$target_file" ]]; then
    openFile "$target_file"
  fi

}


# --- setup for the INSERTER ---
# ZSH
if [[ -n "$ZSH_VERSION" ]]; then
  zffi() {
    local selected_files
    selected_files=$(_zff_selector)
    if [[ -n "$selected_files" ]]; then
      while IFS= read -r target_file; do
        if [[ -n "$target_file" ]]; then
          # If path contains a space, use full, quoted path.
          if [[ "$target_file" =~ \  ]]; then
            # shellcheck disable=SC2296
            LBUFFER+="${(q)target_file} "
          else
            # use tilde if no spaces coz its cool
            if [[ "$target_file" == "$HOME"* ]]; then
              target_file="~${target_file#$HOME}"
            fi
            LBUFFER+="$target_file "
        fi
      fi
    done <<< "$selected_files"
    zle redisplay
  fi
}

# BASH setup
elif [[ -n "$BASH_VERSION" && $- == *i* ]]; then
  _zffi_bash_inserter() {
    local selected_files
    selected_files=$(_zff_selector < /dev/tty)

    if [[ -n "$selected_files" ]]; then
      while IFS= read -r selected; do
        if [[ -n "$selected" ]]; then
          local final_path

          # If path contains a space, use full, quoted path.
          if [[ "$selected" =~ \  ]]; then
            final_path=$(printf %q "$selected")
          else
            # use tilde if no spaces coz its cool
            if [[ "$selected" == "$HOME"* ]]; then
              final_path="~${selected#$HOME}"
            else
              final_path="$selected"
            fi
          fi

          READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}${final_path} ${READLINE_LINE:$READLINE_POINT:}"
          ((READLINE_POINT += ${#final_path} + 1))
        fi
      done <<< "$selected_files"
    fi
  }

  # Comment this line to disable the keybind, or change it to another key
  bind -x "\"$bashInsertKey\": _zffi_bash_inserter"
fi
