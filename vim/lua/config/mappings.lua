-- Mappings
-- Save file with <leader>w
vim.api.nvim_set_keymap('n', '<leader>w', ':w<CR>', { noremap = true, silent = true })

-- Encoding switching
vim.api.nvim_set_keymap('n', '<leader>eg', ':e ++enc=gbk<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>eu', ':e ++enc=utf8<CR>', { noremap = true, silent = true })

-- Hexadecimal conversions
vim.api.nvim_set_keymap('n', '<leader>xd', ':%!xxd<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xr', ':%!xxd -r<CR>', { noremap = true, silent = true })

-- Conceal level toggle
vim.api.nvim_set_keymap('n', '<leader>ll', ':set conceallevel=0<CR>', { noremap = true, silent = true })

-- Open vimrc for editing
vim.api.nvim_set_keymap('n', '<leader>ev', ':tabe $MYVIMRC<CR>', { noremap = true, silent = true })

-- Tab and window control
vim.api.nvim_set_keymap('n', '<leader>t', ':tabe<CR>', { noremap = true, silent = true })  -- Open new tab
vim.api.nvim_set_keymap('n', '<leader>v', ':vnew<CR>', { noremap = true, silent = true })  -- Open vertical split
vim.api.nvim_set_keymap('n', '<leader>tq', ':tabclose<CR>', { noremap = true, silent = true })  -- Close current tab
vim.api.nvim_set_keymap('n', '<leader>tn', ':tabnext<CR>', { noremap = true, silent = true })  -- Switch to next tab

-- Insert space as a newline in visual mode
vim.api.nvim_set_keymap('n', '[<space>', ':<c-u>put! =repeat(nr2char(10), v:count1)<cr>\'<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', ']<space>', ':<c-u>put =repeat(nr2char(10), v:count1)<cr>', { noremap = true, silent = true })

-- Clear search highlighting
vim.api.nvim_set_keymap('n', '<C-L>', ':nohlsearch<C-R>=has(\'diff\')?\'<Bar>diffupdate\':\'\'<CR><CR><C-L>', { noremap = true, silent = true })

-- Move to next/previous visual lines
vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true, silent = true })

-- Spell correction in insert mode
vim.api.nvim_set_keymap('i', '<C-l>', '<c-g>u<Esc>[s1z=`]a<c-g>u', { noremap = true, silent = true })

-- Initialize mappings
vim.cmd([[ echom "mapping activated" ]])

