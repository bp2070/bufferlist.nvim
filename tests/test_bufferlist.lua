local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local function get(code)
  child.lua('_G.test_result = (function()\n' .. code .. '\nend)()')
  return child.lua_get('_G.test_result')
end

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ '-u', 'scripts/minimal_init.lua' })
      child.lua([=[M = require('bufferlist')]=])
    end,
    post_once = child.stop,
  },
})

T['floating window'] = new_set()

T['floating window']['uses the configured row, fits its entries, and highlights the active buffer'] = function()
  child.lua([=[
    local first = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(first, 'first.lua')
    local active = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(active, 'active.lua')
    vim.api.nvim_set_current_buf(active)

    M.setup({ width = 30, height = 20, row = 3 })
    M.open()
  ]=])

  local actual = get([=[
    local win
    for _, candidate in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(candidate).relative == 'editor' then
        win = candidate
        break
      end
    end

    local list_buf = vim.api.nvim_win_get_buf(win)
    local buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted
        and buf ~= list_buf
        and (vim.api.nvim_buf_get_name(buf) ~= '' or vim.bo[buf].modified)
      then
        table.insert(buffers, buf)
      end
    end
    table.sort(buffers)

    return {
      row = vim.api.nvim_win_get_config(win).row,
      height = vim.api.nvim_win_get_height(win),
      highlighted = buffers[vim.api.nvim_win_get_cursor(win)[1]],
      active = vim.api.nvim_get_current_buf(),
      entries = #buffers,
    }
  ]=])

  eq(actual.row, 3)
  eq(actual.height, actual.entries)
  eq(actual.highlighted, actual.active)
end

T['selection'] = new_set()

T['selection']['selects buffers by their list position'] = function()
  child.lua([=[
    local first = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(first, 'first.lua')
    local second = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(second, 'second.lua')
    vim.api.nvim_set_current_buf(second)

    M.setup()
    M.open()
    M.select(1)
  ]=])

  local actual = get([=[
    local buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted
        and (vim.api.nvim_buf_get_name(buf) ~= '' or vim.bo[buf].modified)
      then
        table.insert(buffers, buf)
      end
    end
    table.sort(buffers)
    return { current = vim.api.nvim_get_current_buf(), first = buffers[1] }
  ]=])

  eq(actual.current, actual.first)
end

T['empty list'] = function()
  child.lua([=[
    local buffer = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buffer, 'only-buffer.lua')
    vim.api.nvim_set_current_buf(buffer)

    M.setup()
    M.open()

    local list_buf
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative == 'editor' then
        list_buf = vim.api.nvim_win_get_buf(win)
        break
      end
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= list_buf and vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= '' then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    vim.wait(50)
  ]=])

  eq(get([=[
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative == 'editor' then
        local list_buf = vim.api.nvim_win_get_buf(win)
        return vim.api.nvim_buf_get_lines(list_buf, 0, -1, false)
      end
    end
  ]=]), { '[no buffers]' })
end

T['session restore'] = function()
  child.lua([=[
    M.setup({ open_on_startup = false })
    M.open()
    vim.cmd('doautocmd User PersistenceLoadPre')
    M.close()
    vim.cmd('doautocmd User PersistenceLoadPost')
    vim.wait(50)
  ]=])

  eq(get([=[
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative == 'editor' then
        return true
      end
    end
    return false
  ]=]), true)
end

return T
