# `zff` Smart file finder and inserter

`zff` is a bash script that lets you quickly find and open files using fzf, prioritizing vim oldfiles, zoxide directories, and then your current working directory.

> [!NOTE]
> Only Bash and Zsh shells are supported

-----

## Features
- **Smart Prioritization:** (n)vim oldfiles(with snacks.picker frecency support) > CWD > zoxide dirs
- **Speed:** Uses `fd` with `fzf` for insane speed
- **Preview support:** Preview code with `bat`, and get thumbnails for images and videos.
- **Inserter function:** use `zffi` to insert the path(s) into your current command
- **Customizable**: Extensive config options for icons, depths, ignores, score thresholds and more

-----

## Requirements
  - `fzf`
  - `zoxide` (optional)
  - `fd`
  - `rg`
  - `bat` (optional): For syntax-highlighted code previews.
  - `ffmpegthumbnailer` (optional): For video thumbnails in the preview pane.
  - `chafa` or `img2sixel` (optional): For image previews in the terminal.(`chafa` is recommended as it supports more formats)

-----

## Installation
```bash
git clone https://github.com/sahaj-b/zff.git
```
Add the `source` command to your shell's config file (`.bashrc` or `.zshrc`)
```sh
# in ~/.bashrc or ~/.zshrc
if [[ -f ~/zff/zff.sh ]]; then
  source ~/zff/zff.sh
fi
```
-----

## Usage

### To Open a File

Simply run the `zff`.

The selected file will open in your `$EDITOR` (`nvim` by default) or `xdg-open` if it's not a text file.

### To Insert a File Path

The script provides a function called `zffi`.
  * **Bash:** A keybind is set up for you by default. Just hit **`Ctrl+T`**. Change keybind in Config if you want
  * **Zsh:** You need to bind the `zffi` widget yourself. Add this to your `.zshrc` to map it to `Ctrl+T`:
     ```zsh
     zle -N zffi
     bindkey '^T' zffi # Ctrl + T
     ```

### Custom Zsh Widget Example
For more advanced integration, you can create a custom widget.

This one opens files (`zff`) when the prompt is empty and inserts paths(`zffi`) when typing when you press `Ctrl + o`:
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
bindkey '^o' zff-widget # Ctrl + o
```

-----

## Configuration

Create a file at `XDG_CONFIG_HOME/zff/config.sh` (`~/.config/zff/config.sh`) to customize your `zff` experience.

See [example_config.sh](example_config.sh) for all available options with defaults
