return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/neotest-go',
      'olimorris/neotest-phpunit',
      'praem90/neotest-docker-phpunit.nvim',
      'rouge8/neotest-rust',
    },
    requires = {
      'olimorris/neotest-phpunit',
    },
    config = function()
      require('neotest').setup {
        log_level = vim.log.levels.OFF,
        adapters = {
          -- require 'neotest-go',
          -- require 'neotest-rust',
          require 'neotest-phpunit' {
            filter_dirs = { 'vendor' },
          },
          -- require('neotest-docker-phpunit').setup {
          --   phpunit_cmd = '/Users/praem90/personal/neotest-docker-phpunit/target/release/neotest-docker-phpunit',
          --   docker_phpunit = {
          --     ['/Users/praem90/projects/hub/services/lab-api'] = {
          --       container = 'lab-api',
          --       volume = '/Users/praem90/projects/hub/services/lab-api:/hub/services/lab-api',
          --     },
          --   },
          -- },
        },
      }

      vim.keymap.set('n', '<leader>tn', '<cmd>lua require("neotest").run.run()<CR>', { desc = '[T]est [N]earest' })
      vim.keymap.set('n', '<leader>tf', '<cmd>lua require("neotest").run.run(vim.fn.expand("%"))<CR>', { desc = '[T]est [F]ile' })
      vim.keymap.set('n', '<leader>ts', '<cmd>lua require("neotest").summary.toggle()<CR>', { desc = '[T]est [S]ummary' })
      vim.keymap.set('n', '<leader>to', '<cmd>lua require("neotest").output.open()<CR>', { desc = '[T]est [O]utput' })
    end,
  },
}
