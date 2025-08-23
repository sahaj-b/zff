# `zff` - Smart file finder and inserter

`zff` is a bash script that lets you quickly find and open files using fzf, prioritizing vim oldfiles, zoxide directories, and then your current working directory.

> [!NOTE]
> Only **Bash** and **Zsh** shells are supported

-----

## Features
- **Smart Prioritization:** (n)vim oldfiles(with snacks.picker frecency support) > CWD > zoxide dirs
- **Speed:** Uses `fd` and `rg` with `fzf` for insane speed
- **Preview support:** Supports thumbnails for images and videos.
- **Inserter function:** use `zffi` to insert the path(s) into your current command
- **Customizable**: Extensive config options for icons, depths, ignores, score thresholds and more

-----

## Requirements
  - `fzf`: For interactive fuzzy finding and UI
  - `fd`: For file searching (Zoxide and CWD)
  - `rg`: For filtering oldfiles
  - `zoxide` **(optional)**: For zoxide directories support
  - `bat` **(optional)**: For syntax-highlighted code previews.
  - `ffmpegthumbnailer` **(optional)**: For video thumbnails in the preview pane.
  - `chafa` or `img2sixel` **(optional)**: For image previews in the terminal.(`chafa` is recommended as it supports more formats)

-----

## Installation
```bash
git clone https://github.com/sahaj-b/zff.git
```
Add the `source` command to your shell's config file (`.bashrc` or `.zshrc`)
```sh
# assuming you cloned zff to ~/zff
if [[ -f ~/zff/zff.sh ]]; then
  source ~/zff/zff.sh
fi
```
-----

## Usage and Setup

### To Open a File
Just run `zff`
The selected file will open in your `$EDITOR` (`nvim` by default) or `xdg-open` if it's not a text file.  
You can bind it to a keybind if you want. (see Zsh widget example below)

### To Insert a File Path
The script provides a function called `zffi`.
  * **Bash:** A keybind is set up for you by default. Just hit **`Ctrl+T`**. Change keybind in Config if you want
  * **Zsh:** You need to bind the `zffi` widget yourself. Add this to your `.zshrc` to map it to `Ctrl+T`:
     ```zsh
     zle -N zffi
     bindkey '^T' zffi # Ctrl + T
     ```

### Opener Zsh Widget
You can also create a widget to run `zff` on a keybind.
- For `zsh`
  ```zsh
  zff-widget() {
    zff
    zle reset-prompt
  }
  bindkey '^O' zff # Ctrl + O
  ```
- For `bash
  ```bash
  bind '"\C-o":"zff\n"'
  ```

### Next-level Zsh Widget Example
When you press `Ctrl + space`, this one opens files (`zff`) when the prompt is empty, and inserts paths (`zffi`) if its not 
```zsh
zff-widget() {
  if [[ -n "$BUFFER" ]]; then
    # Insert path if typed something
    zffi
  else
    # Empty prompt: open file
    zff
    zle reset-prompt
  fi
}
zle -N zff-widget
bindkey '^@' zff-widget # Ctrl + space
```

> [!TIP]
> - `Ctrl + c` to copy selected path to clipboard (change your copy command in config if needed)
> - `Ctrl + u` / `Ctrl + d` to go half page up/down in the list
> - You can change these behavior by editing the fzf command in main file
> - Use `tab` / `shift + tab` to select/unselect multiple files to insert

-----

## Configuration

- Create a file at `XDG_CONFIG_HOME/zff/config.sh` (`~/.config/zff/config.sh`) to customize your `zff` experience.
- This script supports a wide range of configuration options, from setting custom icons to defining search depths and ignore patterns.
- See [example_config.sh](example_config.sh) for all available options with defaults

## Lagging?
Low end systems *may* experience some lag due to large number of files. You can
- Reduce search depths (recommended) and score threshold
- Add more ignore patterns in the config file to improve performance.
- Disable preview in config
