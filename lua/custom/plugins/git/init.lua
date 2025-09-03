local Split = require 'nui.split'
local event = require('nui.utils.autocmd').event
local Job = require 'plenary.job'

local write_text = function(split, data)
  local lines = {}
  for line in data:gmatch '[^\r\n]+' do
    table.insert(lines, line)
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(split.winid))
  vim.api.nvim_buf_set_lines(split.bufnr, row - 1, row - 1, false, lines)
end

local M = {}

M.init = function() end

M.run = function(args)
  local split = Split {
    relative = 'win',
    position = 'bottom',
    size = '20%',
    enter = false,
  }

  Job:new({
    command = 'git',
    args = args,
    cwd = vim.fn.getcwd(),
    on_stdout = vim.schedule_wrap(function(_, data)
      if data then
        write_text(split, data)
      end
    end),
    on_stderr = vim.schedule_wrap(function(e, data)
      if data then
        write_text(split, data)
      end
    end),
    on_exit = function(_, return_val) end,
  }):start() -- or start()

  -- mount/open the component
  split:mount()

  -- unmount component when cursor leaves buffer
  split:on(event.BufLeave, function()
    split:unmount()
  end)
end

M.push = function()
  M.run { 'push' }
end

return M
