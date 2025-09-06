local Split = require 'nui.split'
local Job = require 'plenary.job'
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local open_picker = function(records, opts)
  opts = opts or {}
  local picker_opts = require('telescope.themes').get_dropdown(opts.picker or {})

  pickers
    .new(picker_opts, {
      prompt_title = opts.title or 'Databases',
      finder = finders.new_table {
        results = records,
        entry_maker = opts.entry_maker or nil,
      },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          if opts.callback then
            opts.callback(action_state.get_selected_entry())
          end
        end)
        return true
      end,
      sorter = conf.generic_sorter(opts),
    })
    :find()
end

local M = {}

M.connId = nil

M.databases = nil

M.active_connections = {}

M.get_connections = function()
  return {
    { name = 'Local', host = '127.0.0.1', port = 3306, user = 'root', password = 'hunter2', database = 'quartzy_development' },
  }
end

M.execute = function(opts, cb, onerr)
  local args = { '-h', M.active_connections[M.connId].host, '--protocol', 'tcp', '--binary-as-hex', '-e', opts.sql }
  if M.active_connections[M.connId].database ~= nil then
    table.insert(args, '--database')
    table.insert(args, M.active_connections[M.connId].database)
  end

  if M.active_connections[M.connId].password ~= nil then
    table.insert(args, '-p' .. M.active_connections[M.connId].password)
  end

  if M.active_connections[M.connId].user ~= nil then
    table.insert(args, '-u' .. M.active_connections[M.connId].user)
  end

  if opts.table == nil or opts.table == true then
    table.insert(args, '--table')
  end

  if opts.columns ~= nil and opts.columns == false then
    table.insert(args, '--skip-column-names')
  end

  Job:new({
    command = 'mysql',
    args = args,
    cwd = vim.fn.getcwd(),
    on_exit = function(j, return_val)
      if return_val == 0 then
        cb(j:result())
      else
        onerr(j:stderr_result())
      end
    end,
  }):start()
end

M.open = function(opts)
  opts = opts or {}
  local pickers_opts = require('telescope.themes').get_dropdown(opts.picker or {})
  M.parent_win = vim.api.nvim_get_current_win()

  open_picker(M.get_connections(), {
    title = 'Connections',
    entry_maker = function(entry)
      return {
        value = entry,
        display = entry.name,
        ordinal = entry.name,
      }
    end,
    callback = function(selection)
      M.active_connections[selection.value.name] = selection.value
      M.connId = selection.value.name

      if selection.value.database ~= nil then
        M.create_buffers()
      else
        M.pick_database()
      end
    end,
  })
end

M.pick_database = function(opts)
  local callback = function(entry)
    M.active_connections[M.connId].database = entry[1]
    M.create_buffers()
  end

  if M.active_connections[M.connId].databases ~= nil then
    open_picker(M.active_connections[M.connId].databases, { callback = callback })
    return
  end

  M.execute(
    { sql = 'show databases;', columns = false, table = false },
    vim.schedule_wrap(function(databases)
      M.active_connections[M.connId].databases = databases
      open_picker(databases, { callback = callback })
    end)
  )
end

M.open_tables = function()
  if #M.active_connections == 0 or M.connId == nil or M.active_connections[M.connId].database == nil then
    vim.notify 'Please connect to a server and a database'
    return
  end

  M.execute(
    { sql = 'show tables', columns = false, table = false },
    vim.schedule_wrap(function(tables)
      M.active_connections[M.connId].tables = tables
    end)
  )
end

M.open_active_connections = function()
  local count = 0
  local connections = {}
  for _, conn in pairs(M.active_connections) do
    count = count + 1
    if conn.name == M.connId then
      conn.name = conn.name .. ' (active)'
    end
    table.insert(connections, conn.name)
  end
  if count == 0 then
    vim.notify 'There are no active connections'
    return
  end

  open_picker(connections, {
    callback = function(entry)
      M.connId = entry[1]
    end,
  })
end

M.create_buffers = function()
  if M.query_split == nil then
    M.query_split = {
      bufnr = vim.api.nvim_create_buf(false, true),
      win = M.parent_win,
    }
    vim.api.nvim_set_option_value('filetype', 'mysql', { buf = M.query_split.bufnr })
    vim.api.nvim_win_set_buf(M.query_split.win, M.query_split.bufnr)
  end

  if M.output_split == nil then
    M.output_split = Split {
      relative = 'editor',
      position = 'bottom',
      size = '20%',
      win_options = {
        wrap = false,
      },
    }
  end

  vim.keymap.set('n', '<CR>', function()
    local lines = vim.api.nvim_buf_get_lines(M.query_split.bufnr, 0, -1, false)
    M.output_split:mount()
    M.execute(
      { sql = table.concat(lines, '\n') },
      vim.schedule_wrap(function(output)
        if type(output) == 'string' then
          local lines = {}
          for line in output:gmatch '[^\r\n]+' do
            table.insert(lines, line)
          end
        else
          lines = output
        end

        vim.api.nvim_buf_set_lines(M.output_split.bufnr, 0, -1, false, lines)
        vim.api.nvim_set_option_value('modified', false, { buf = M.output_split.bufnr })
      end),
      vim.schedule_wrap(function(err)
        vim.print(vim.inspect(err))
      end)
    )
  end)
end

return M
