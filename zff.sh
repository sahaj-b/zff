#!/usr/bin/env bash

# -------- CONFIG --------
# EDIT YOUR CONFIG IN ~/.config/zff/config.sh. these are just defaults
oldfilesIcon=''
zoxideIcon='󱐌'
cwdIcon='󰚡'
zoxideDepth=3 # how deep to search in zoxide dirs
zoxideThreshold=0.4 # minimum score to consider a zoxide dir
cwdDepth=6 # how deep to search in cwd
copyCmd='wl-copy' # command to copy to clipboard (eg: wl-copy,pbcopy,xclip,xsel)
bashInsertKey='\C-t' # keybind for inserter in bash
useSnacks=0 # use snacks.nvim frecency ordering for oldfiles
oldfilesIgnore='^/tmp/.*.(zsh|sh|bash)$|^oil.*' # regex to ignore certain oldfiles
enablePreview=1 # enable preview in fzf

# ignore patterns
zff_fd_ignores=(
  # VCS, project folders, misc
  '**/.git/**' '**/node_modules/**' '**/.cache/**' '**/.venv/**' '**/.vscode/**' '**/.pycache__/**' '**/.DS_Store' '**/.idea/**' '**/.mypy_cache/**' '**/.pytest_cache/**' '**/.next/**' '**/dist/**' '**/build/**' '**/target/**' '**/.gradle/**' '**/.terraform/**' '**/.egg-info/**' '**/.env' '**/.history' '**/.svn/**' '**/.hg/**' '**/.Trash/**' '**/bin/**' '**/.bin/**' "**/.local/share/Trash/**" "**/.local/share/nvim/**" "**/pkg/**" "oil:*"

  # Build artifacts and temp files
  '**/CMakeCache.txt' '**/CMakeFiles/**' '**/Makefile' '**/*.o' '**/*.obj' '**/*.a' '**/*.so' '**/*.dll' '**/*.dylib' '**/*.exe' '**/*.class' '**/*.jar' '**/*.war' '**/*.pyc' '**/*.pyo' '**/*.pyd' '**/__pycache__/**' '**/*.whl' '**/coverage/**' '**/.coverage' '**/.nyc_output/**' '**/htmlcov/**' '**/coverage.xml'

  # Lock files and package managers
  '**/package-lock.json' '**/yarn.lock' '**/pnpm-lock.yaml' '**/Pipfile.lock' '**/poetry.lock' '**/Cargo.lock' '**/composer.lock' '**/Gemfile.lock' '**/go.sum' '**/mix.lock'

  # OS and system files
  '**/.DS_Store' '**/Thumbs.db' '**/desktop.ini' '**/*.lnk' '**/System Volume Information/**' '**/lost+found/**' '**/.fseventsd/**' '**/.Spotlight-V100/**' '**/.TemporaryItems/**'

  # Database files
  '**/*.db' '**/*.sqlite' '**/*.sqlite3' '**/*.mdb' '**/*.accdb'

  # Archives
  '**/*.zip' '**/*.rar' '**/*.7z' '**/*.tar' '**/*.tar.gz' '**/*.tar.bz2' '**/*.tar.xz' '**/*.gz' '**/*.bz2' '**/*.xz'

  # Font files
  '**/*.ttf' '**/*.otf' '**/*.woff' '**/*.woff2' '**/*.eot'

  # Virtual environments and containers
  '**/.venv/**' '**/venv/**' '**/env/**' '**/.virtualenv/**' '**/virtualenv/**' '**/Dockerfile.*' '**/.dockerignore'

  # Testing and coverage
  '**/.pytest_cache/**' '**/.coverage' '**/coverage/**' '**/.nyc_output/**' '**/junit.xml'
)


# function to open the selected file
openFile() {
  if file --mime-type -b "$1" | grep -E -q 'text/|application/(json|javascript|xml|csv|x-yaml)|inode/x-empty';then
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

# cache command availability at startup to avoid repeated command -v calls
HAS_ZOXIDE=$(command -v zoxide &>/dev/null && echo 1 || echo 0)
HAS_NVIM=$(command -v nvim &>/dev/null && echo 1 || echo 0)

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

zff_fd_excludes=()
for pat in "${zff_fd_ignores[@]}"; do
  zff_fd_excludes+=(--exclude "$pat")
done

printf -- "- %s\n" "${zff_fd_excludes[@]}" >> /tmp/zff_array_debug.log

previewCmd="$SCRIPT_DIR/zff-preview.sh {}"

if [[ $enablePreview -eq 1 ]]; then
  previewFlag=(--preview "$previewCmd")
else
  previewFlag=()
fi

_zff_selector() {
  {
    # Priority 0: (n)vim oldfiles
    get_oldfiles

    # Priority 1: CWD
    fd -t f -H -d "$cwdDepth" "${zff_fd_excludes[@]}" . "$PWD" 2>/dev/null | sed "s/^/$cwdIcon /"

    # Priority 2: Zoxide dirs
    if [[ $HAS_ZOXIDE -eq 1 ]]; then
      get_zoxide_files
    fi

   } |
     sed -E "s|^(.[^ ]* )$HOME|\1~|" |
     fzf --height 50% --layout reverse --info=inline \
       --scheme=path --tiebreak=index \
       --cycle --preview-window "$(if [[ $enablePreview -eq 1 && $(tput cols) -lt 120 ]]; then echo 'down:40%'; else echo 'right:40%'; fi)" \
       --bind="ctrl-c:execute-silent(echo {} | sed -e 's/^[^ ]* //' | tr -d '\n' | $copyCmd)+abort" \
       --bind="ctrl-d:half-page-down,ctrl-u:half-page-up" \
       --multi "${previewFlag[@]}" |
      sed -e "s/^[^ ]* //;s|^~|$HOME|"

}

get_oldfiles() {
  snacks_db="$HOME/.local/share/nvim/snacks/picker-frecency.sqlite3"
    if [[ $useSnacks -eq 1 && -f "$snacks_db" ]]; then
      # using both snacks and nvim oldfiles
      (
      sqlite3 "$snacks_db" "SELECT key FROM data ORDER BY value DESC;" 2>/dev/null

      # fastest way to get nvim oldfiles using --headless
      get_nvim_oldfiles
      ) | awk '!seen[$0]++' | sed "s/^/$oldfilesIcon /"
    else
      get_nvim_oldfiles | sed "s/^/$oldfilesIcon /"
    fi

}

get_nvim_oldfiles() {
  (
    if [[ $HAS_NVIM -eq 1 ]]; then
    nvim -n -u NONE --noplugin --headless \
      -c "lua for _,f in ipairs(vim.v.oldfiles) do print(f) end" \
      -c "qa" 2>&1 | tr -d '\r'
  else
    # Fallback to vim oldfiles
    sed -n 's/^> //p' "$HOME/.viminfo" 2>/dev/null
  fi
  ) | rg --invert-match $oldfilesIgnore
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
  fd -H -d "$zoxideDepth" "${zff_fd_excludes[@]}" . "${filtered_dirs[@]}" 2>/dev/null |
    awk '!seen[$0]++' | sed "s/^/$zoxideIcon /"
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
