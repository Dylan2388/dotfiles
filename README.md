# dotfiles
This repository manages personal dotfiles using a bare Git repository stored separately from the working tree. The Git metadata lives in ~/.cfg, while the actual config files stay in their normal locations inside $HOME such as ~/.bashrc.

## Initial setup
This section documents the one-time setup already performed on the original machine.

1. Create the bare repository
```
git init --bare "$HOME/.cfg"
This creates a bare Git repository in ~/.cfg. A bare repository stores Git metadata and history, but does not create a normal checked-out working directory of its own.
```

3. Create a helper alias
bash
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
This alias makes Git use ~/.cfg as the Git directory and $HOME as the working tree, so files in the home directory can be tracked without turning the entire home directory into a normal Git repo.

4. Hide untracked files from status
bash
config config --local status.showUntrackedFiles no
This prevents config status from listing every untracked file in the home directory and keeps output focused on files that are intentionally tracked.

5. Persist the alias
bash
echo "alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> "$HOME/.bashrc"
This adds the alias to the shell startup file so the config command is available in future shell sessions.

6. Add and commit selected files
Only explicitly chosen files should be tracked, for example:

bash
config add .bashrc
config add .gitconfig
config add .config/nvim/init.lua
config commit -m "Initial dotfiles commit"
This workflow tracks the real files in their original locations. Nothing is symlinked or copied into ~/.cfg; the bare repo only stores Git history and metadata.

6. Connect to GitHub and push
Create an empty GitHub repository first, then add it as a remote and push:

bash
config remote add origin git@github.com:<username>/<repo>.git
config branch -M main
config push -u origin main
Using an empty remote avoids first-push conflicts, and -u sets the upstream so future config push calls can omit the branch name.

Set up on another computer
Use this section on any new macOS or Ubuntu machine that should receive the same dotfiles.

1. Clone the repository as a bare repo
bash
git clone --bare git@github.com:<username>/<repo>.git "$HOME/.cfg"
This clones the remote dotfiles repository directly into ~/.cfg as a bare repository.

2. Recreate the helper alias
bash
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
This is required before using the config command on the new machine.

3. Persist the alias
For Bash:

bash
echo "alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> "$HOME/.bashrc"
For Zsh:

bash
echo "alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> "$HOME/.zshrc"
The alias should be stored in the startup file used by the shell on that machine.

4. Back up conflicting files if needed
If checkout fails because existing local files would be overwritten, move them out of the way first:

bash
mkdir -p .config-backup
config checkout 2>&1 | egrep "\s+\." | awk '{print $1}' | xargs -I{} mv {} .config-backup/{}
This command creates a backup directory and moves conflicting files there so the tracked versions can be checked out cleanly afterward.

5. Check out the tracked files
bash
config checkout
This writes the tracked files from the bare repository into their real paths under $HOME, such as ~/.bashrc or ~/.config/....

6. Hide untracked files from status
bash
config config --local status.showUntrackedFiles no
This keeps status output readable on the new machine as well.

Daily usage
bash
config status
config add .bashrc
config commit -m "Update bash config"
config push
These commands behave like normal Git commands, but operate on the bare repository in ~/.cfg with $HOME as the working tree.

Pulling updates later
To get the latest changes on another machine:

bash
config pull
To restore or update only one tracked file:

bash
config checkout -- .bashrc
config checkout -- .config/nvim/init.lua
Checking out a specific path updates only that tracked file instead of re-checking out everything in the repository.

Cross-platform notes
A single repository can be used across macOS and Ubuntu as long as the tracked file paths match what each application expects. Shared configs can stay common, while OS-specific behavior is usually handled with conditional logic or separate override files such as .zshrc.mac and .zshrc.linux rather than separate branches.

Files that should not be committed
Do not commit secrets or machine-specific sensitive files such as SSH private keys, cloud credentials, API tokens, or generated state files. Only commit intentional configuration files that are safe to sync across machines.
