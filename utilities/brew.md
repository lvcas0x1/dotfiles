# wezterm

- https://wezterm.org/index.html

# oh-my-zsh

- https://ohmyz.sh/

# powerlevel10k

- https://github.com/romkatv/powerlevel10k

# xcode

- app store
- xcode-select --install
- accept license agreement
- xcrun --find lldb-dap
- xcrun --find sourcekit-lsp
- sourcekit-lsp --version

# hammerspoon

- https://www.hammerspoon.org/

# karabiner

- https://karabiner-elements.pqrs.org/

# homebrew

- https://brew.sh/

# zsh

- brew install zsh

# git

- brew install git

# copy dotfile to local

# or create a new repository

```
ls -al ~/.ssh

ssh-keygen -t ed25519 -C "azaria@sample.com"

cat ~/.ssh/id_ed25519.pub

# copy pub-key to github
# check connection
ssh -T git@github.com

# create a new repository on the command line
git init
git add .
git commit -m "-"
git branch -M main
git remote add origin https://github.com/azariar/dotfiles.git
git push -u origin main
```

# installation

- brew install awscli
- brew install azure-cli
- brew install --cask gcloud-cli
- brew install kubernetes-cli

- brew tap oven-sh/bun
  - brew install bun
- brew install node@24
- brew install rustup
- brew install vite

- brew install python@3.14
- brew install go
- brew install dotnet
- brew install openjdk@25
- brew tap hashicorp/tap
  - brew install hashicorp/tap/terraform

- brew install pyenv
- brew install maven

- brew install lazygit
- brew install git-delta
- brew install certbot
- brew install wget
- brew install tree
- brew install yazi
- brew install neovim

- brew install --cask font-maple-mono-nf-cn

- brew install ripgrep
- brew install fd

- brew install tree-sitter-cli

- brew install cmake

# telescope-fzf-native may report error

```
clang --version
make --version

cd ~/.local/share/nvim/site/pack/core/opt/telescope-fzf-native.nvim
make clean
make

# build/libfzf.so
```

# rustup may report error

```
rustup toolchain uninstall stable
rustup toolchain install stable

rustup default stable

rustup component add rustfmt
```

# bicep

```
brew tap azure/bicep
brew install bicep

brew trust azure/bicep
```

# swift

```
brew install swift-format
```

# im-select

```
brew tap laishulu/homebrew
brew install macism

brew trust laishulu/homebrew

which macism
macism
# macism com.apple.keylayout.US
```

# tdf

```
cargo install --git https://github.com/itsjunetime/tdf.git
tdf --help

echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

# wezterm

```
echo 'export PATH="/Applications/WezTerm.app/Contents/MacOS:$PATH"' >> ~/.zshrc
source ~/.zshrc

wezterm --version
wezterm cli list
```

# yazi

```
# preview pdf

brew install poppler

# install catppuccin flavors

mkdir -p ~/.config/yazi/flavors
cd ~/.config/yazi/flavors
git clone https://github.com/yazi-rs/flavors.git /tmp/yazi-flavors
cp -R /tmp/yazi-flavors/catppuccin-mocha.yazi ~/.config/yazi/flavors/
cp -R /tmp/yazi-flavors/catppuccin-latte.yazi ~/.config/yazi/flavors/

rm -rf /tmp/yazi-flavors
```

# lazygit

```
mkdir -p ~/.config/lazygit
mkdir -p ~/.config/lazygit/themes

curl -Lo ~/.config/lazygit/themes/catppuccin-latte-blue.yml \
https://raw.githubusercontent.com/catppuccin/lazygit/main/themes/latte/blue.yml

# XDG config
export XDG_CONFIG_HOME="$HOME/.config"

# LG confg
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/themes/catppuccin-latte-blue.yml"

source ~/.zshrc
```
