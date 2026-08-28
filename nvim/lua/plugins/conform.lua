local conform = require("conform")

conform.setup({
	default_format_opts = {
		timeout_ms = 3000,
		lsp_format = "fallback",
	},

	format_on_save = {
		timeout_ms = 3000,
		lsp_format = "fallback",
	},

	formatters_by_ft = {
		bash = { "shfmt" },
		bicep = { "bicep" },
		c = { "clang_format" },
		c_sharp = { "csharpier" },
		cpp = { "clang_format" },
		css = { "prettierd", "prettier", stop_after_first = true },
		cuda = { "clang_format" },
		dockerfile = { lsp_format = "fallback" },
		go = { "goimports", "gofmt" },
		gomod = { lsp_format = "fallback" },
		gosum = { lsp_format = "fallback" },
		gotmpl = { lsp_format = "fallback" },
		gowork = { lsp_format = "fallback" },
		graphql = { "prettierd", "prettier", stop_after_first = true },
		hcl = { "terraform_fmt" },
		html = { "prettierd", "prettier", stop_after_first = true },
		java = { lsp_format = "fallback" },
		javadoc = { lsp_format = "fallback" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		jsdoc = { lsp_format = "fallback" },
		json = { "prettierd", "prettier", stop_after_first = true },
		lua = { "stylua" },
		markdown = { "prettierd", "prettier", stop_after_first = true },
		markdown_inline = { lsp_format = "fallback" },
		mermaid = { lsp_format = "fallback" },
		nginx = { "nginxfmt" },
		powershell = { lsp_format = "fallback" },
		prisma = { lsp_format = "fallback" },
		python = { "isort", "black" },
		regex = { lsp_format = "fallback" },
		requirements = { lsp_format = "fallback" },
		rust = { "rustfmt", lsp_format = "fallback" },
		sql = { "sqlfluff" },
		swift = { "swift_format" },
		terraform = { "terraform_fmt" },
		toml = { "taplo" },
		tsx = { "prettierd", "prettier", stop_after_first = true },
		typescript = { "prettierd", "prettier", stop_after_first = true },
		vim = { lsp_format = "fallback" },
		vimdoc = { lsp_format = "fallback" },
		yaml = { "prettierd", "prettier", stop_after_first = true },
	},

	formatters = {
		sqlfluff = {
			args = { "fix", "--dialect", "ansi", "-" },
			require_cwd = false,
		},
		swift_format = {
			command = "xcrun",
			args = { "swift-format", "format", "--in-place", "$FILENAME" },
			stdin = false,
		},
	},
})

vim.o.formatexpr = 'v:lua.require("conform").formatexpr()'
