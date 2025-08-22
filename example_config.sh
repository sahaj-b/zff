# THESE ARE NOT DEFAULTS, just an example config

# PLEAAAASE use 1 byte chars for icons, so no emojies (script too dumb to handle that shi)
oldfilesIcon='O'
zoxideIcon='Z'
cwdIcon=' '

zoxideDepth=5       # how deep to search in zoxide dirs
zoxideThreshold=0.8 # minimum score to consider a zoxide dir
cwdDepth=6          # how deep to search in cwd
copyCmd='pbcopy'    # command to copy to clipboard (eg: wl-copy,pbcopy,xclip,xsel)

bashInsertKey='Ctrl-t' # keybind for inserter in bash

# ignore patterns
fd_ignores+=('**/my_ignore_folder/**' '**/*.log')
# fd_ignores=('**/only_this_folder/**') # use '=' instead of '+=' to override defaults

# function to open the selected file
openFile() {
  xdg-open "$1" &>/dev/null &
}
