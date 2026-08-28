vim.filetype.add({
	extension = {
		tmpl = "gotmpl",
		mdx = "markdown.mdx",
		gql = "graphql",
		graphql = "graphql",
	},

	filename = {
		["docker-compose.yml"] = "yaml.docker-compose",
		["docker-compose.yaml"] = "yaml.docker-compose",
		["compose.yml"] = "yaml.docker-compose",
		["compose.yaml"] = "yaml.docker-compose",
		[".gitlab-ci.yml"] = "yaml.gitlab",
		[".gitlab-ci.yaml"] = "yaml.gitlab",
	},

	pattern = {
		[".*/values%.ya?ml"] = "yaml.helm-values",
	},
})
