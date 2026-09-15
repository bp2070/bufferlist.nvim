# bufferlist.nvim

A simple Neovim plugin that shows your open buffers in a floating list.

## Features

- Centered floating window listing buffers
- Shows current buffer (`>`), modified flag (`+`), buffer number, and filename
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
  height = 20,
})
```

## Usage

Commands:

- `:BufferListToggle` – toggle the floating buffer list
- `:BufferListOpen` – open the floating buffer list
- `:BufferListClose` – close the floating buffer list

Example keymap:

```lua
vim.keymap.set('n', '<leader>bl', '<cmd>BufferListToggle<CR>', { silent = true })
```

## Configuration

`setup()` accepts an optional table:

```lua
require('bufferlist').setup({
  width = 30,   -- width of the floating window
  height = 20,  -- height of the floating window
})
```

## License

MIT
