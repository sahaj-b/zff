# `zff` - The Ultimate File Finder 🚀

`zff` is a bash script that lets you quickly find and open files using fzf, prioritizing vim oldfiles, zoxide directories, and then your current working directory.

> [!NOTE]
> Only Bash and Zsh shells are supported

-----

## Features
- **Smart Prioritization:** (n)vim oldfiles(with snacks.picker frecency support) > files inside zoxide directories > Current working dir
- **Speed:** Uses `fd` with `fzf` for insane speed
- **Preview support:** Preview code with `bat`, and get thumbnails for images and videos.
- **Inserter function:** use `zffi` to insert the path(s) into your current command
- **Customizable**: Extensive config options for icons, depths, ignores, score thresholds and more

-----

## Requirements
  - `fzf`
  - `zoxide` (optional)
  - `fd`
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
  * **Bash:** A keybind is set up for you by default. Just hit **`Ctrl+T`**.
  * **Zsh:** You need to bind the `zffi` widget yourself. Add this to your `.zshrc`.
     ```zsh
     zle -N zffi
     bindkey '^T' zffi # Ctrl + T
     ```

### Custom Zsh Widget Example

For more advanced integration, you can create a custom widget that opens files when the prompt is empty and inserts paths when typing, using a single keybind. Add this to your `.zshrc`:

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

### Another Example: Using Different Keybinding

If you prefer a different key, say `Ctrl+F`, you can bind it like this:

```zsh
zle -N zffi
bindkey '^F' zffi
```

-----

## Configuration

Don't edit the main script.

Instead, create a file at `~/.config/zff/config.sh` and override the variables you want.

See [example_config.sh](example_config.sh) 
