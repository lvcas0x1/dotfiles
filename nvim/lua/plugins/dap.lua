local dap = require("dap")

local mason = vim.fn.stdpath("data") .. "/mason"

local function mason_bin(name)
  return mason .. "/bin/" .. name
end

local function mason_package(path)
  return mason .. "/packages/" .. path
end

local function executable_or_nil(path)
  if path and path ~= "" and vim.fn.executable(path) == 1 then
    return path
  end
  return nil
end

-- DAP signs
vim.fn.sign_define("DapBreakpoint", {
  text = "●",
  texthl = "DiagnosticError",
})

vim.fn.sign_define("DapBreakpointCondition", {
  text = "◆",
  texthl = "DiagnosticWarn",
})

vim.fn.sign_define("DapLogPoint", {
  text = "◆",
  texthl = "DiagnosticInfo",
})

vim.fn.sign_define("DapStopped", {
  text = "▶",
  texthl = "DiagnosticOk",
  linehl = "Visual",
})

dap.defaults.fallback.terminal_win_cmd = "botright 15split new"

-- dap-view
local ok_dap_view, dap_view = pcall(require, "dap-view")

if ok_dap_view then
  dap_view.setup()

  dap.listeners.after.event_initialized["dap-view"] = function()
    dap_view.open()
  end

  dap.listeners.before.event_terminated["dap-view"] = function()
    dap_view.close()
  end

  dap.listeners.before.event_exited["dap-view"] = function()
    dap_view.close()
  end
end

-- Python: Mason debugpy + project python
local ok_dap_python, dap_python = pcall(require, "dap-python")

if ok_dap_python then
  local mason_debugpy_python = mason_package("debugpy/venv/bin/python")
  local debugpy_python = executable_or_nil(mason_debugpy_python) or vim.fn.exepath("python3")

  if debugpy_python ~= "" then
    dap_python.setup(debugpy_python)

    local function project_python()
      local cwd = vim.fn.getcwd()

      local candidates = {
        cwd .. "/.venv/bin/python",
        cwd .. "/venv/bin/python",
        vim.fn.exepath("python3"),
        vim.fn.exepath("python"),
      }

      for _, python in ipairs(candidates) do
        if executable_or_nil(python) then
          return python
        end
      end

      return "python3"
    end

    for _, config in ipairs(dap.configurations.python or {}) do
      config.pythonPath = project_python
    end
  end
end

-- Go: Mason delve
local dlv = mason_bin("dlv")

if executable_or_nil(dlv) then
  dap.adapters.go = {
    type = "server",
    port = "${port}",
    executable = {
      command = dlv,
      args = { "dap", "-l", "127.0.0.1:${port}" },
    },
  }

  dap.configurations.go = {
    {
      type = "go",
      name = "Go: Debug file",
      request = "launch",
      program = "${file}",
    },
    {
      type = "go",
      name = "Go: Debug package",
      request = "launch",
      program = "${fileDirname}",
    },
  }
end

-- JavaScript / TypeScript: Mason js-debug-adapter
local node = vim.fn.exepath("node")
local js_debug_server = mason_package("js-debug-adapter/js-debug/src/dapDebugServer.js")

if node ~= "" and vim.fn.filereadable(js_debug_server) == 1 then
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = {
      command = node,
      args = {
        js_debug_server,
        "${port}",
        "127.0.0.1",
      },
    },
  }

  for _, language in ipairs({
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
  }) do
    dap.configurations[language] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Node: Launch current file",
        program = "${file}",
        cwd = "${workspaceFolder}",
        runtimeExecutable = "node",
        sourceMaps = true,
        stopOnEntry = true,
        console = "integratedTerminal",
        skipFiles = {
          "<node_internals>/**",
          "${workspaceFolder}/node_modules/**",
        },
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Node: Attach to process",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        skipFiles = {
          "<node_internals>/**",
          "${workspaceFolder}/node_modules/**",
        },
      },
    }
  end
end

-- C / C++ / Rust: Mason codelldb
local codelldb = mason_package("codelldb/extension/adapter/codelldb")

if executable_or_nil(codelldb) then
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = codelldb,
      args = { "--port", "${port}" },
    },
  }

  dap.configurations.c = {
    {
      type = "codelldb",
      name = "C: Launch executable",
      request = "launch",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
  }

  dap.configurations.cpp = dap.configurations.c

  dap.configurations.rust = {
    {
      type = "codelldb",
      name = "Rust: Launch executable",
      request = "launch",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
  }
end

-- Swift: Xcode lldb-dap. Not Mason
local xcrun = vim.fn.exepath("xcrun")

if xcrun ~= "" then
  local lldb_dap = vim.fn.trim(vim.fn.system({ "xcrun", "--find", "lldb-dap" }))

  if executable_or_nil(lldb_dap) then
    dap.adapters.lldb_dap = {
      type = "executable",
      command = lldb_dap,
      name = "lldb-dap",
    }

    dap.configurations.swift = {
      {
        type = "lldb_dap",
        name = "Swift: Launch executable",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/.build/debug/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
      },
    }
  end
end
