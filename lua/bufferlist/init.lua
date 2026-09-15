local M = {}

local config = {
  width = 30,
  height = 20,
  row = 1,
  open_on_startup = false,
}

local state = {
  win = nil,
  buf = nil,
  open = false,
  last_win = nil,
  session_was_open = false,
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
      and (vim.api.nvim_buf_get_name(bufnr) ~= '' or vim.bo[bufnr].modified)
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
  if current == state.buf and is_valid_win(state.last_win) then
    current = vim.api.nvim_win_get_buf(state.last_win)
  end
  local current_line = 1

  for index, bufnr in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == '' then
      name = '[No Name]'
    else
      name = vim.fn.fnamemodify(name, ':t')
    end
    local modified = vim.bo[bufnr].modified and '+' or ' '
    local curflag = (bufnr == current) and '>' or ' '
    if bufnr == current then
      current_line = index
    end
    table.insert(lines, string.format('%s%s%d %s', curflag, modified, index, name))
  end

  if #lines == 0 then
    lines = { '[no buffers]' }
  end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  local available_height = vim.o.lines - config.row - 2
  local height = math.max(1, math.min(#lines, config.height, available_height))
  vim.api.nvim_win_set_height(state.win, height)
  vim.api.nvim_win_set_cursor(state.win, { current_line, 0 })
end

local function select_buffer(index)
  local bufnr = get_buffers()[index]
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if is_valid_win(state.win) and vim.api.nvim_get_current_win() == state.win and is_valid_win(state.last_win) then
    vim.api.nvim_set_current_win(state.last_win)
  end
  vim.api.nvim_set_current_buf(bufnr)
end

local function open_window()
  if state.open and is_valid_win(state.win) and is_valid_buf(state.buf) then
    return
  end

  state.last_win = vim.api.nvim_get_current_win()

  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.max(1, math.min(config.width, vim.o.columns - 2))
  local available_height = vim.o.lines - config.row - 2
  local height = math.max(1, math.min(math.max(1, #get_buffers()), config.height, available_height))
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    anchor = 'NW',
    width = width,
    height = height,
    row = config.row,
    col = math.max(0, vim.o.columns - width - 2),
    style = 'minimal',
    border = 'rounded',
  })

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
    select_buffer(vim.api.nvim_win_get_cursor(0)[1])
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

function M.select(index)
  select_buffer(index)
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

  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'BufWipeout', 'BufEnter', 'BufWritePost', 'BufModifiedSet' }, {
    group = group,
    callback = function()
      if state.open then
        vim.schedule(render)
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

  if config.open_on_startup then
    vim.api.nvim_create_autocmd('VimEnter', {
      group = group,
      once = true,
      callback = M.open,
    })
  end

  local function remember_session_state()
    state.session_was_open = state.session_was_open or (state.open and is_valid_win(state.win))
  end

  local function restore_session_state()
    if state.session_was_open then
      state.session_was_open = false
      vim.schedule(M.open)
    end
  end

  vim.api.nvim_create_autocmd('SessionLoadPre', {
    group = group,
    callback = remember_session_state,
  })

  vim.api.nvim_create_autocmd('SessionLoadPost', {
    group = group,
    callback = restore_session_state,
  })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'PersistenceLoadPre',
    callback = remember_session_state,
  })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'PersistenceLoadPost',
    callback = restore_session_state,
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

  vim.api.nvim_create_user_command('BufferListSelect', function(args)
    M.select(tonumber(args.args))
  end, { nargs = 1 })
end

return M
