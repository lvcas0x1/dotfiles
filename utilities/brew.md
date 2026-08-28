# Wezterm

- https://wezterm.org/index.html

# Homebrew

- https://brew.sh/

# ZSH

- brew install zsh

# Oh-My-Zsh

- https://ohmyz.sh/

# Powerlevel10k

- https://github.com/romkatv/powerlevel10k

# Hammerspoon

- https://www.hammerspoon.org/

# Karabiner

- https://karabiner-elements.pqrs.org/

# Git

- brew install git

# Copy dotfile to local

```
ls -al ~/.ssh

ssh-keygen -t ed25519 -C "lvcas0x1@outlook.com"

cat ~/.ssh/id_ed25519.pub

# copy pub-key to github
# check connection
ssh -T git@github.com
```

# Installation

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
  - brew trust hashicorp/tap

- brew tap azure/bicep
  - brew install bicep
  - brew trust azure/bicep

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

- brew install swift-format

- brew tap laishulu/homebrew
  - brew install macism
  - brew trust laishulu/homebrew

# Nvim SetUp

## xcode

- Download from AppStore
- xcode-select --install
- sudo xcodebuild -license accept

- xcrun --find lldb-dap
- xcrun --find sourcekit-lsp
- sourcekit-lsp --version

- clang --version
- make --version
- xcrun swift --version

## telescope-fzf-native may report error

```
clang --versions
make --version

cd ~/.local/share/nvim/site/pack/core/opt/telescope-fzf-native.nvim
make clean
make

# build/libfzf.so
```

## rustup may report error

```
rustup toolchain uninstall stable
rustup toolchain install stable

rustup default stable

rustup component add rustfmt
```

## im-select

```
which macism
macism
# macism com.apple.keylayout.US
```

## tdf

```
cargo install --git https://github.com/itsjunetime/tdf.git
tdf --help

echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## wezterm

```
echo 'export PATH="/Applications/WezTerm.app/Contents/MacOS:$PATH"' >> ~/.zshrc
source ~/.zshrc

wezterm --version
wezterm cli list
```

## yazi

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

## lazygit

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

## mason
```
Installed
  ✓ bash-language-server bashls
  ✓ bicep-lsp bicep
  ✓ black
  ✓ clang-format
  ✓ clangd
  ✓ codelldb
  ✓ csharpier
  ✓ css-lsp cssls
  ✓ debugpy
  ✓ delve
  ✓ dockerfile-language-server dockerls
  ✓ goimports
  ✓ gopls
  ✓ graphql-language-service-cli graphql
  ✓ html-lsp html
  ✓ isort
  ✓ js-debug-adapter
  ✓ json-lsp jsonls
  ✓ lua-language-server lua_ls
  ✓ marksman
  ✓ nginx-config-formatter
  ✓ omnisharp
  ✓ powershell-editor-services powershell_es
  ✓ prettier
  ✓ prettierd
  ✓ prisma-language-server prismals
  ✓ pyright
  ✓ rust-analyzer rust_analyzer
  ✓ shfmt
  ✓ sqlfluff
  ✓ sqlls
  ✓ stylua
  ✓ taplo
  ✓ terraform-ls terraformls
  ✓ vim-language-server vimls
  ✓ yaml-language-server yamlls

```

## vimpack
```

Installed (33)

  ✓ LuaSnip                          ok        0abc8f39 -> latest
  ✓ catppuccin                       ok        0303a720 -> latest
  ✓ conform.nvim                     ok        619363c3 -> latest
  ✓ diffview.nvim                    ok        4516612f -> latest
  ✓ friendly-snippets                ok        6cd7280a -> latest
  ✓ gitsigns.nvim                    ok        25050e4e -> latest
  ✓ im-select.nvim                   ok        963a4e9d -> latest
  ✓ lualine.nvim                     ok        221ce6b2 -> latest
  ✓ mason-lspconfig.nvim             ok        0a695750 -> latest
  ✓ mason.nvim                       ok        16ba83bf -> latest
  ✓ neo-tree.nvim                    ok        1b4c4005 -> latest
  ✓ neogen                           ok        23e7e9f8 -> latest
  ✓ nui.nvim                         ok        de740991 -> latest
  ✓ nvim-autopairs                   ok        7b9923ab -> latest
  ✓ nvim-dap                         ok        53177153 -> latest
  ✓ nvim-dap-python                  ok        1808458e -> latest
  ✓ nvim-dap-view                    ok        91a2b0ea -> latest
  ✓ nvim-java                        ok        bb120763 -> latest
  ✓ nvim-lspconfig                   ok        ed19590a -> latest
  ✓ nvim-treesitter                  ok        4916d659 -> latest
  ✓ nvim-ts-autotag                  ok        88c1453d -> latest
  ✓ nvim-web-devicons                ok        dfbfaa96 -> latest
  ✓ nvim-window-picker               ok        6382540b -> latest
  ✓ plenary.nvim                     ok        74b06c6c -> latest
  ✓ render-markdown.nvim             ok        5adf0895 -> latest
  ✓ spring-boot.nvim                 ok        218c0c26 -> latest
  ✓ telescope-fzf-native.nvim        ok        b25b749b -> latest
  ✓ telescope.nvim                   ok        7d324792 -> latest
  ✓ todo-comments.nvim               ok        31e3c38c -> latest
  ✓ toggleterm.nvim                  ok        9a88eae8 -> latest
  ✓ trouble.nvim                     ok        bd67efe4 -> latest
  ✓ ts-comments.nvim                 ok        123a9fb1 -> latest
  ✓ which-key.nvim                   ok        3aab2147 -> latest

```
