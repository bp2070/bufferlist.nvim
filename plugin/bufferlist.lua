if vim.g.loaded_bufferlist then
  return
end
vim.g.loaded_bufferlist = true

-- Plugin is initialized by calling require('bufferlist').setup() from user config.
-- We don't auto-call setup() here so users can configure the plugin.
