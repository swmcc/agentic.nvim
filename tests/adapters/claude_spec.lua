local Claude = require("agentic.adapters.claude")

describe("Claude adapter", function()
  local adapter

  before_each(function()
    adapter = Claude:new({
      cmd = "claude",
      timeout = 5000,
    })
  end)

  describe("is_available", function()
    it("returns true when claude is in PATH", function()
      local original = vim.fn.executable
      vim.fn.executable = function(cmd)
        return cmd == "claude" and 1 or 0
      end

      assert.is_true(adapter:is_available())

      vim.fn.executable = original
    end)

    it("returns false when claude is not in PATH", function()
      local original = vim.fn.executable
      vim.fn.executable = function() return 0 end

      assert.is_false(adapter:is_available())

      vim.fn.executable = original
    end)
  end)

  describe("build_args", function()
    it("includes -p flag for print mode", function()
      local args = adapter:build_args("test prompt", {})
      assert.is_true(vim.tbl_contains(args, "-p"))
    end)

    it("includes the prompt as last argument", function()
      local args = adapter:build_args("test prompt", {})
      assert.equals("test prompt", args[#args])
    end)

    it("prepends context to prompt when provided", function()
      local args = adapter:build_args("test prompt", {
        filename = "/path/to/file.lua",
        filetype = "lua",
      })
      local prompt = args[#args]
      assert.is_truthy(prompt:match("File: /path/to/file.lua"))
      assert.is_truthy(prompt:match("test prompt"))
    end)

    it("includes custom args from opts", function()
      adapter.opts.args = { "--model", "opus" }
      local args = adapter:build_args("test", {})
      assert.is_true(vim.tbl_contains(args, "--model"))
      assert.is_true(vim.tbl_contains(args, "opus"))
    end)
  end)

  describe("parse_output", function()
    it("returns content as-is", function()
      local result = adapter:parse_output("Hello world")
      assert.equals("Hello world", result.content)
    end)

    it("does not extract code blocks (uses streaming JSON)", function()
      local output = [[
Some text here
```lua
local x = 1
```
]]
      local result = adapter:parse_output(output)
      -- Base adapter parse_output doesn't extract code blocks
      assert.is_nil(result.code_blocks)
    end)

    it("includes stream-json output format flag", function()
      local args = adapter:build_args("test", {})
      assert.is_true(vim.tbl_contains(args, "--output-format"))
      assert.is_true(vim.tbl_contains(args, "stream-json"))
    end)
  end)

  describe("parse_error", function()
    it("detects authentication errors", function()
      local patterns = {
        "Error: not logged in",
        "Authentication failed",
        "unauthorized access",
        "Invalid API key",
      }
      for _, msg in ipairs(patterns) do
        local result = adapter:parse_error(msg, 1)
        assert.is_truthy(result:match("Authentication required"))
      end
    end)

    it("detects rate limit errors", function()
      local result = adapter:parse_error("Rate limit exceeded", 1)
      assert.is_truthy(result:match("Rate limited"))
    end)

    it("detects network errors", function()
      local result = adapter:parse_error("Network connection failed", 1)
      assert.is_truthy(result:match("Network error"))
    end)

    it("returns original message for unknown errors", function()
      local result = adapter:parse_error("Something unexpected happened", 1)
      assert.equals("Something unexpected happened", result)
    end)

    it("handles empty error messages", function()
      local result = adapter:parse_error("", 127)
      assert.is_truthy(result:match("exit code 127"))
    end)
  end)

  describe("ask", function()
    it("returns error when CLI not available", function()
      local original = vim.fn.executable
      vim.fn.executable = function() return 0 end

      local result
      adapter:ask("test", {}, function(r) result = r end)

      assert.is_truthy(result.error:match("not found"))

      vim.fn.executable = original
    end)
  end)

  describe("cancel", function()
    it("clears handle reference", function()
      adapter.handle = { kill = function() end }
      adapter:cancel()
      assert.is_nil(adapter.handle)
    end)

    it("clears timeout timer", function()
      adapter.timeout_timer = {}
      adapter:cancel()
      assert.is_nil(adapter.timeout_timer)
    end)
  end)
end)
