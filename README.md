# dotfiles
This repository manages personal dotfiles using a bare Git repository stored separately from the working tree. The Git metadata lives in ~/.cfg, while the actual config files stay in their normal locations inside $HOME such as ~/.bashrc.

## Initial setup
This section documents the one-time setup already performed on the original machine.

Create the bare repository
```bash
git init --bare "$HOME/.cfg"
```
This creates a bare Git repository in ~/.cfg. A bare repository stores Git metadata and history, but does not create a normal checked-out working directory of its own.

Create a helper alias
```bash
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
```
This alias makes Git use ~/.cfg as the Git directory and $HOME as the working tree, so files in the home directory can be tracked without turning the entire home directory into a normal Git repo.

Hide untracked files from status
```bash
config config --local status.showUntrackedFiles no
```
This prevents config status from listing every untracked file in the home directory and keeps output focused on files that are intentionally tracked.

Persist the alias
```bash
echo "alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> "$HOME/.bashrc"
```
This adds the alias to the shell startup file so the config command is available in future shell sessions.

Add and commit selected files
Only explicitly chosen files should be tracked, for example:
```bash
config add .bashrc
config add .gitconfig
config add .config/nvim/init.lua
config commit -m "Initial dotfiles commit"
```
This workflow tracks the real files in their original locations. Nothing is symlinked or copied into ~/.cfg; the bare repo only stores Git history and metadata.

## Installing your dotfiles onto a new system (or migrate to this setup)
If you already store your configuration/dotfiles in a Git repository, on a new system you can migrate to this setup with the following steps:

Prior to the installation make sure you have committed the alias to your .bashrc or .zsh:
```bash
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
```

And that your source repository ignores the folder where you'll clone it, so that you don't create weird recursion problems:
```bash
echo ".cfg" >> .gitignore
```

Now clone your dotfiles into a bare repository in a "dot" folder of your $HOME:
```bash
git clone --bare <git-repo-url> $HOME/.cfg
```

Define the alias in the current shell scope:
```bash
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
```

Checkout the actual content from the bare repository to your $HOME:
```bash
config checkout
```

The step above might fail with a message like:
```bash
error: The following untracked working tree files would be overwritten by checkout:
    .bashrc
    .gitignore
Please move or remove them before you can switch branches.
Aborting
```

This is because your $HOME folder might already have some stock configuration files which would be overwritten by Git. The solution is simple: back up the files if you care about them, remove them if you don't care. I provide you with a possible rough shortcut to move all the offending files automatically to a backup folder:

```bash
mkdir -p .config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}
```

Re-run the check out if you had problems:
```bash
config checkout
```

Set the flag showUntrackedFiles to no on this specific (local) repository:
```bash
config config --local status.showUntrackedFiles no
```

You're done, from now on you can now type config commands to add and update your dotfiles:
```bash
config status
config add .vimrc
config commit -m "Add vimrc"
config add .bashrc
config commit -m "Add bashrc"
config push
```

## Cross-platform notes
A single repository can be used across macOS and Ubuntu as long as the tracked file paths match what each application expects. We can create new branch for different OS.

