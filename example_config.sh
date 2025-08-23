oldfilesIcon=''
zoxideIcon='󱐌'
cwdIcon='󰚡'

# you can set the depths to zero to disable a source
zoxideDepth=3       # how deep to search in zoxide dirs
zoxideThreshold=0.4 # minimum score to consider a zoxide dir
cwdDepth=6          # how deep to search in cwd
copyCmd='wl-copy'   # command to copy to clipboard (eg: wl-copy,pbcopy,xclip,xsel)

# 0 = no, 1 = yes
useSnacks=0     # use snacks.nvim frecency ordering for oldfiles
enablePreview=1 # enable preview in fzf

bashInsertKey='\C-t' # keybind for inserter in bash (in zsh, use widget instead)

oldfilesIgnore='^/tmp/.*.(zsh|sh|bash)$|^oil.*' # regex to ignore certain oldfiles

# ignore patterns for zoxide and CWD (see zff.sh for defaults)
fd_ignores+=('**/my_ignore_folder/**' '**/*.log') # adds to defaults
# use '=' instead of '+=' to override defaults

# function to open the selected file
openFile() {
  if file --mime-type -b "$1" | grep -E -q 'text/|application/(json|javascript|xml|csv|x-yaml)|inode/x-empty'; then
    ${EDITOR:-nvim} "$1"
  else
    xdg-open "$1" &>/dev/null &
  fi
}
