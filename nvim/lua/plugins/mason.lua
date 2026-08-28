local mason = require("mason")

mason.setup({
  PATH = "prepend",
  ui = {
    border = "rounded",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

local packages = {
  -- Formatter
  "black",
  "isort",
  "stylua",
  "prettierd",
  "prettier",
  "shfmt",
  "clang-format",
  "sqlfluff",
  "goimports",
  "gofumpt",
  "csharpier",
  "nginx-config-formatter",

  -- DAP
  "debugpy",
  "delve",
  "js-debug-adapter",
  "codelldb",
}

vim.api.nvim_create_user_command("MasonInstallRequired", function()
  local registry = require("mason-registry")

  registry.refresh(function()
    for _, name in ipairs(packages) do
      local ok, pkg = pcall(registry.get_package, name)

      if not ok then
        vim.notify("Mason package not found: " .. name, vim.log.levels.WARN)
      elseif not pkg:is_installed() then
        vim.notify("Mason installing: " .. name)
        pkg:install()
      end
    end
  end)
end, {})
