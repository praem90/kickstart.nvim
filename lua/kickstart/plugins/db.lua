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
    config = function()
      vim.print 'Configuring db-ui'
      vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufEnter' }, {
        pattern = '*.dbout',
        callback = function()
          vim.api.nvim_set_option_value('foldenable', false, {})
          vim.print 'Disabled foldenable for .dbout files'
        end,
      })
    end,
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
}
