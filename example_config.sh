oldfilesIcon=''
zoxideIcon='󱐌'
cwdIcon='󰚡'

zoxideDepth=6       # how deep to search in zoxide dirs
zoxideThreshold=0.4 # minimum score to consider a zoxide dir
cwdDepth=8          # how deep to search in cwd
copyCmd='pbcopy'    # command to copy to clipboard (eg: wl-copy,pbcopy,xclip,xsel)

useSnacks=0 # use snacks.nvim frecency ordering for oldfiles

bashInsertKey='\C-t' # keybind for inserter in bash (use widget instead in zsh)

# ignore patterns (see zff.sh for defaults)
fd_ignores+=('**/my_ignore_folder/**' '**/*.log') # adds to defaults
# use '=' instead of '+=' to override defaults

# function to open the selected file
openFile() {
  if file --mime-type -b "$1" | grep -E -q 'text/|application/(json|javascript|xml|csv|x-yaml)'; then
    ${EDITOR:-nvim} "$1"
  else
    xdg-open "$1" &>/dev/null &
  fi
}
