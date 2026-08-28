require('neo-tree').setup({

  -- close neotree window if it is the last window left
  close_if_last_window = true,

  -- ''
  popup_border_style = '',

  -- share clipboard for all neovim instances
  clipboard = { sync = 'universal'},

  -- show git status
  enable_git_status = true,

  -- show lsp errors
  enable_diagnostics = true,

  -- 
  open_files_do_not_replace_types = { 'terminal', 'trouble', 'qf' },

  -- 
  open_files_using_relative_paths = false,

  -- sort files
  sort_case_insensitive = true,

  default_component_configs = {
    container = {
      enable_character_fade = true,
    },
    indent = {
      indent_size = 2,
      padding = 1,
    },
    file_size = {
      enabled = true,
      width = 15,
      required_width = 40,
    },
    type = {
      enabled = false,
    },
    last_modified = {
      enabled = true,
      width = 20,
      required_width = 120,
    },
    created = {
      enabled = true,
      width = 20,
      required_width = 120,
    },
    symlink_target = {
      enabled = true,
    },
  },

  window = {
    position = 'left',
    width = 40,
  },
  
  filesystem = {
    -- hidden files
    filtered_items = {
      visible = true,
      hide_dotfiles = false,
      hide_gitignored = false,
      hide_ignored = false,
      always_show = {},
      always_show_by_pattern = {},
      never_show = {
        '.DS_Store',
      },
      never_show_by_pattern = {},
    },

    -- find and focus the file in the active buffer
    -- change the directory without prompting
    follow_current_file = {
      enable = true,
      leave_dirs_open = true,
    },

    -- auto refresh file system status
    use_libuv_file_watcher = true,
  },
})
