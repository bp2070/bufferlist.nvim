local M = {}

local config = {
  width = 30,
  side = 'right', -- currently only 'right' is used
}

local state = {
  win = nil,
  buf = nil,
  open = false,
  last_win = nil,
}

local function is_valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function get_buffers()
  local bufs = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    -- show every *listed* buffer (even if not yet loaded) except the bufferlist itself
    if vim.api.nvim_buf_is_valid(bufnr)
      and vim.bo[bufnr].buflisted
      and bufnr ~= state.buf
    then
      table.insert(bufs, bufnr)
    end
  end
  table.sort(bufs)
  return bufs
end

local function render()
  if not (is_valid_buf(state.buf) and is_valid_win(state.win)) then
    return
  end

  local bufs = get_buffers()
  local lines = {}

  local current = vim.api.nvim_get_current_buf()

  for _, bufnr in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == '' then
      name = '[No Name]'
    else
      name = vim.fn.fnamemodify(name, ':t')
    end
    local modified = vim.bo[bufnr].modified and '+' or ' '
    local curflag = (bufnr == current) and '>' or ' '
    table.insert(lines, string.format('%s%s %3d %s', curflag, modified, bufnr, name))
  end

  if #lines == 0 then
    lines = { '[no buffers]' }
  end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
end

local function open_window()
  if state.open and is_valid_win(state.win) and is_valid_buf(state.buf) then
    return
  end

  state.last_win = vim.api.nvim_get_current_win()

  -- create a vertical split on the right
  vim.cmd('vsplit')
  vim.cmd('wincmd L')
  vim.cmd('vertical resize ' .. config.width)

  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_win_set_buf(win, buf)

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'bufferlist'
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  -- keymaps inside the buffer list
  vim.keymap.set('n', '<CR>', function()
    local line = vim.api.nvim_get_current_line()
    local bufnr = tonumber(line:match('%s(%d+)%s')) or tonumber(line:match('(%d+)'))
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    -- go back to last window if it is valid
    if is_valid_win(state.last_win) then
      vim.api.nvim_set_current_win(state.last_win)
    else
      vim.cmd('wincmd p')
    end
    vim.api.nvim_set_current_buf(bufnr)
  end, { buffer = buf, nowait = true, silent = true })

  vim.keymap.set('n', 'q', function()
    M.close()
  end, { buffer = buf, nowait = true, silent = true })

  state.win = win
  state.buf = buf
  state.open = true

  render()

  -- return focus to the window that was active before opening the list
  if is_valid_win(state.last_win) then
    vim.api.nvim_set_current_win(state.last_win)
  end
end

function M.open()
  open_window()
end

function M.close()
  if state.open and is_valid_win(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
  state.open = false
end

function M.toggle()
  if state.open and is_valid_win(state.win) then
    M.close()
  else
    M.open()
  end
end

local function setup_autocmds()
  local group = vim.api.nvim_create_augroup('BufferList', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'BufEnter', 'BufWritePost', 'BufModifiedSet' }, {
    group = group,
    callback = function()
      if state.open then
        render()
      end
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function(args)
      local closed = tonumber(args.match)
      if state.open and state.win == closed then
        state.open = false
        state.win = nil
        state.buf = nil
      end
    end,
  })
end

function M.setup(opts)
  if opts then
    config = vim.tbl_extend('force', config, opts)
  end

  setup_autocmds()

  vim.api.nvim_create_user_command('BufferListToggle', function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command('BufferListOpen', function()
    M.open()
  end, {})

  vim.api.nvim_create_user_command('BufferListClose', function()
    M.close()
  end, {})
end

return M
