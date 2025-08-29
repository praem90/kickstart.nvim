return {
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      { 'tpope/vim-dadbod', lazy = true },
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true }, -- Optional
    },
    cmd = {
      'DBUI',
      'DBUIToggle',
      'DBUIAddConnection',
      'DBUIFindBuffer',
    },
    config = function() end,
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1

      --- Disable folding for .dbout files
      vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufEnter' }, {
        pattern = '*.dbout',
        callback = function()
          vim.api.nvim_set_option_value('foldenable', false, {})
        end,
      })

      -- Create a new tab with DBUI
      vim.keymap.set('n', '<leader>du', function()
        vim.cmd.tabnew()
        vim.cmd.DBUIToggle()
      end, {})

      -- Close the DBUI tab
      vim.keymap.set('n', '<leader>dc', function()
        vim.cmd.tabclose()
        vim.cmd.DBUIToggle()
      end, {})
    end,
  },
}
