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

    it("stops and closes timeout timer", function()
      local stop_called = false
      local close_called = false
      adapter.timeout_timer = {
        stop = function() stop_called = true end,
        close = function() close_called = true end,
      }
      adapter:cancel()
      assert.is_true(stop_called)
      assert.is_true(close_called)
      assert.is_nil(adapter.timeout_timer)
    end)

    it("calls kill on handle when cancelling", function()
      local kill_called = false
      adapter.handle = {
        kill = function()
          kill_called = true
        end,
      }
      adapter:cancel()
      assert.is_true(kill_called)
    end)

    it("handles cancel when no handle exists", function()
      adapter.handle = nil
      assert.has_no.errors(function()
        adapter:cancel()
      end)
    end)

    it("handles cancel when no timeout timer exists", function()
      adapter.timeout_timer = nil
      assert.has_no.errors(function()
        adapter:cancel()
      end)
    end)
  end)

  describe("format_event", function()
    it("formats system init event with model", function()
      local event = {
        type = "system",
        subtype = "init",
        model = "claude-sonnet-4-20250514",
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("Session started"))
      assert.is_truthy(result:match("claude%-sonnet%-4"))
    end)

    it("formats system init event with unknown model", function()
      local event = {
        type = "system",
        subtype = "init",
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("unknown"))
    end)

    it("formats assistant message with text block", function()
      local event = {
        type = "assistant",
        message = {
          content = {
            { type = "text", text = "Here is my response" },
          },
        },
      }
      local result = adapter:format_event(event)
      assert.equals("Here is my response", result)
    end)

    it("formats assistant message with multiple text blocks", function()
      local event = {
        type = "assistant",
        message = {
          content = {
            { type = "text", text = "First part" },
            { type = "text", text = "Second part" },
          },
        },
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("First part"))
      assert.is_truthy(result:match("Second part"))
    end)

    it("formats tool_use block with command input", function()
      local event = {
        type = "assistant",
        message = {
          content = {
            { type = "tool_use", name = "Bash", input = { command = "ls -la" } },
          },
        },
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("%*%*%[Bash%]%*%*"))
      assert.is_truthy(result:match("ls %-la"))
    end)

    it("formats tool_use block with pattern input", function()
      local event = {
        type = "assistant",
        message = {
          content = {
            { type = "tool_use", name = "Glob", input = { pattern = "**/*.lua" } },
          },
        },
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("%*%*%[Glob%]%*%*"))
      assert.is_truthy(result:match("%*%*/%*%.lua"))
    end)

    it("formats tool_use block with file_path input", function()
      local event = {
        type = "assistant",
        message = {
          content = {
            { type = "tool_use", name = "Read", input = { file_path = "/path/to/file.lua" } },
          },
        },
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("%*%*%[Read%]%*%*"))
      assert.is_truthy(result:match("/path/to/file%.lua"))
    end)

    it("truncates long JSON input in tool_use", function()
      local long_input = { data = string.rep("x", 200) }
      local event = {
        type = "assistant",
        message = {
          content = {
            { type = "tool_use", name = "Custom", input = long_input },
          },
        },
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("%.%.%."))
    end)

    it("formats user tool_use_result", function()
      local event = {
        type = "user",
        tool_use_result = "file1.lua\nfile2.lua",
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("```"))
      assert.is_truthy(result:match("file1%.lua"))
    end)

    it("formats user tool_use_result with error", function()
      local event = {
        type = "user",
        tool_use_result = "Error: File not found",
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("> Error:"))
    end)

    it("truncates long tool_use_result", function()
      local event = {
        type = "user",
        tool_use_result = string.rep("x", 600),
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("truncated"))
    end)

    it("formats result event with duration and cost", function()
      local event = {
        type = "result",
        duration_ms = 5500,
        total_cost_usd = 0.0123,
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("5%.5s"))
      assert.is_truthy(result:match("%$0%.0123"))
    end)

    it("formats result event with missing values", function()
      local event = {
        type = "result",
      }
      local result = adapter:format_event(event)
      assert.is_truthy(result:match("0%.0s"))
      assert.is_truthy(result:match("%$0%.0000"))
    end)

    it("returns nil for unhandled event types", function()
      local event = {
        type = "unknown",
        data = {},
      }
      local result = adapter:format_event(event)
      assert.is_nil(result)
    end)

    it("returns nil for assistant message with no content", function()
      local event = {
        type = "assistant",
        message = {},
      }
      local result = adapter:format_event(event)
      assert.is_nil(result)
    end)

    it("returns nil for assistant message with empty content array", function()
      local event = {
        type = "assistant",
        message = {
          content = {},
        },
      }
      local result = adapter:format_event(event)
      assert.is_nil(result)
    end)
  end)

  describe("timeout configuration", function()
    it("uses default timeout of 300000ms", function()
      local default_adapter = Claude:new({})
      assert.equals(300000, default_adapter.opts.timeout)
    end)

    it("accepts custom timeout value", function()
      local custom_adapter = Claude:new({ timeout = 60000 })
      assert.equals(60000, custom_adapter.opts.timeout)
    end)

    it("accepts zero timeout to disable", function()
      local no_timeout_adapter = Claude:new({ timeout = 0 })
      assert.equals(0, no_timeout_adapter.opts.timeout)
    end)
  end)

  describe("timeout behavior", function()
    it("sets timeout_timer when timeout > 0 and process starts", function()
      -- This test verifies the timer is created by mocking the spawn
      local original_executable = vim.fn.executable
      local original_spawn = vim.loop.spawn
      local original_defer = vim.defer_fn
      local defer_called = false
      local defer_timeout = nil

      vim.fn.executable = function() return 1 end
      vim.loop.spawn = function()
        return { kill = function() end, close = function() end }
      end
      vim.defer_fn = function(fn, timeout)
        defer_called = true
        defer_timeout = timeout
        return { stop = function() end, close = function() end }
      end

      local test_adapter = Claude:new({ timeout = 5000 })
      test_adapter:ask("test", {}, function() end)

      assert.is_true(defer_called)
      assert.equals(5000, defer_timeout)

      vim.fn.executable = original_executable
      vim.loop.spawn = original_spawn
      vim.defer_fn = original_defer
    end)

    it("does not set timeout_timer when timeout is 0", function()
      local original_executable = vim.fn.executable
      local original_spawn = vim.loop.spawn
      local original_defer = vim.defer_fn
      local defer_called = false

      vim.fn.executable = function() return 1 end
      vim.loop.spawn = function()
        return { kill = function() end, close = function() end }
      end
      vim.defer_fn = function(fn, timeout)
        defer_called = true
        return { stop = function() end, close = function() end }
      end

      local test_adapter = Claude:new({ timeout = 0 })
      test_adapter:ask("test", {}, function() end)

      assert.is_false(defer_called)

      vim.fn.executable = original_executable
      vim.loop.spawn = original_spawn
      vim.defer_fn = original_defer
    end)

    it("timeout callback includes timed_out flag", function()
      -- Verify the callback structure when timeout occurs
      local original_executable = vim.fn.executable
      local original_spawn = vim.loop.spawn
      local original_defer = vim.defer_fn
      local original_schedule = vim.schedule
      local captured_timeout_fn = nil
      local callback_result = nil

      vim.fn.executable = function() return 1 end
      vim.loop.spawn = function()
        return { kill = function() end, close = function() end }
      end
      vim.defer_fn = function(fn, timeout)
        captured_timeout_fn = fn
        return { stop = function() end, close = function() end }
      end
      vim.schedule = function(fn) fn() end

      local test_adapter = Claude:new({ timeout = 5000 })
      test_adapter:ask("test", {}, function(result) callback_result = result end)

      -- Simulate timeout firing
      if captured_timeout_fn then
        captured_timeout_fn()
      end

      assert.is_truthy(callback_result)
      assert.equals("Request timed out", callback_result.error)
      assert.is_true(callback_result.timed_out)

      vim.fn.executable = original_executable
      vim.loop.spawn = original_spawn
      vim.defer_fn = original_defer
      vim.schedule = original_schedule
    end)
  end)
end)
