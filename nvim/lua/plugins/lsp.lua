-- Diagnostics
vim.diagnostic.config({
	virtual_text = true,
})

-- Native completion UI
vim.opt.completeopt = {
	"menu",
	"menuone",
	"noinsert",
	"popup",
}

vim.opt.pumheight = 20

-- Native LSP completion
local lsp_attach_completion_group = vim.api.nvim_create_augroup("lsp_attach_completion", {
	clear = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = lsp_attach_completion_group,
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)

		if not client then
			return
		end

		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		if client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, ev.buf, {
				autotrigger = true,
			})
		end
	end,
})

-- Completion float UI
local function set_completion_highlights()
	vim.api.nvim_set_hl(0, "Pmenu", {
		bg = "NONE",
	})

	vim.api.nvim_set_hl(0, "PmenuSel", {
		bg = "#e2e5ea",
		fg = "#ff0000",
		bold = true,
	})

	vim.api.nvim_set_hl(0, "PmenuSbar", {
		bg = "NONE",
	})

	vim.api.nvim_set_hl(0, "PmenuThumb", {
		bg = "#e2e5ea",
	})

	vim.api.nvim_set_hl(0, "NormalFloat", {
		bg = "NONE",
	})
end

set_completion_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = set_completion_highlights,
})

local lsp_servers = {
	"bashls",
	"bicep",
	"clangd",
	"omnisharp",
	"cssls",
	"dockerls",
	"gopls",
	"graphql",
	"terraformls",
	"html",
	-- "ts_ls", -- disable for ts 5.9 to use typescript 7
	"jsonls",
	"lua_ls",
	"marksman",
	-- "nginx_language_server",
	"powershell_es",
	"prismals",
	"pyright",
	"rust_analyzer",
	"sqlls",
	"taplo",
	"vimls",
	"yamlls",
}

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				checkThirdParty = false,
			},
		},
	},
})

--[[
vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      validate = true,
      schemas = {
        ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.32.0-standalone/all.json"] = {
          "*.k8s.yaml",
          "*.k8s.yml",
          "k8s/*.yaml",
          "k8s/*.yml",
          "kubernetes/*.yaml",
          "kubernetes/*.yml",
        },
      },
    },
  },
})
--]]
--
vim.lsp.config("yamlls", {
	settings = {
		yaml = {
			validate = true,
			schemaStore = {
				enable = true,
			},
		},
	},
})

vim.lsp.config("jsonls", {
	settings = {
		json = {
			validate = {
				enable = true,
			},
		},
	},
})

vim.lsp.config("sourcekit", {
	cmd = { "xcrun", "sourcekit-lsp" },
	filetypes = { "swift" },
	root_markers = {
		"Package.swift",
		".git",
	},
})

vim.lsp.enable("sourcekit")

vim.lsp.config("graphql", {
	filetypes = {
		"graphql",
	},
})

vim.lsp.config("tsgo", {
	cmd = {
		vim.fn.exepath("tsc"),
		"--lsp",
		"--stdio",
	},
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	root_markers = {
		"tsconfig.json",
		"jsconfig.json",
		"package.json",
		".git",
	},
})

vim.lsp.enable("tsgo")

require("mason-lspconfig").setup({
	ensure_installed = lsp_servers,
	automatic_enable = true,
})
