# bufferlist.nvim

A simple Neovim plugin that shows your open buffers in a list on the right side of the screen.

## Features

- Right-side vertical window listing buffers
- Shows current buffer (`>`), modified flag (`+`), buffer number, and filename
- Automatically updates on buffer add/delete/enter/write/modified
- Press `<CR>` on a buffer to jump to it
- Press `q` in the list to close it
- Does **not** steal focus when opening the list

## Installation (with `vim.pack.add`)

In your `init.lua` (Neovim 0.10+):

```lua
-- Replace `YOUR_GITHUB_USERNAME` with your GitHub username
vim.pack.add('YOUR_GITHUB_USERNAME/bufferlist.nvim')

require('bufferlist').setup({
  -- optional configuration
  width = 30,
})
```

## Usage

Commands:

- `:BufferListToggle` – toggle the buffer list window
- `:BufferListOpen` – open the buffer list window
- `:BufferListClose` – close the buffer list window

Example keymap:

```lua
vim.keymap.set('n', '<leader>bl', '<cmd>BufferListToggle<CR>', { silent = true })
```

## Configuration

`setup()` accepts an optional table:

```lua
require('bufferlist').setup({
  width = 30,      -- width of the buffer list window
  side = 'right',  -- reserved for future use; currently always opens on the right
})
```

## License

MIT
