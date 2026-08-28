require("java").setup({
	jdk = {
		auto_install = false,
	},
})

vim.lsp.config("jdtls", {
	settings = {
		java = {
			configuration = {
				runtimes = {
					{
						name = "JavaSE-25",
						path = "/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home",
						default = true,
					},
				},
			},
		},
	},
})

vim.lsp.enable("jdtls")
