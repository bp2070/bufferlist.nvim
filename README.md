# bufferlist.nvim

A simple Neovim plugin that shows your open buffers in a floating list.

## Features

- Top-right floating window listing buffers
- Preserves its current open/closed state when restoring a session
- Shows current buffer (`>`), modified flag (`+`), list position, and filename
- Shows `[no buffers]` when no named or modified buffers remain
- Automatically updates on buffer add/delete/enter/write/modified
- Press `<CR>` on a buffer to jump to it
- Press `q` in the list to close it
- Does **not** steal focus when opening the list

## Installation (with `vim.pack.add`)

In your `init.lua` (Neovim 0.10+):

```lua
vim.pack.add('https://github.com/bp2070/bufferlist.nvim')

require('bufferlist').setup({
  -- optional configuration
  width = 30,
  height = 20, -- maximum height; shrinks to fit the buffer list
  row = 1,
  open_on_startup = true,
})
```

## Usage

Commands:

- `:BufferListToggle` – toggle the floating buffer list
- `:BufferListOpen` – open the floating buffer list
- `:BufferListClose` – close the floating buffer list
- `:BufferListSelect {position}` – switch to a buffer by its list position

Example keymap:

```lua
vim.keymap.set('n', '<leader>bl', '<cmd>BufferListToggle<CR>', { silent = true })
vim.keymap.set('n', '<leader>b1', '<cmd>BufferListSelect 1<CR>', { silent = true })
vim.keymap.set('n', '<leader>b2', '<cmd>BufferListSelect 2<CR>', { silent = true })
```

## Configuration

`setup()` accepts an optional table:

```lua
require('bufferlist').setup({
  width = 30,   -- width of the floating window
  height = 20,           -- maximum height; window shrinks to fit the list
  row = 1,                -- number of rows from the top
  open_on_startup = false, -- open automatically when Neovim starts
})
```

## License

MIT
