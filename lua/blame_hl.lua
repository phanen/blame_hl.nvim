local api, fn = vim.api, vim.fn
local M = {}

local on_preview = function(preview_win, preview_buf)
  local win = api.nvim_get_current_win()
  win = win == preview_win and fn.win_getid(fn.winnr('#')) or win
  if win == -1 then return end
  if not api.nvim_buf_is_valid(preview_buf) or not api.nvim_win_is_valid(win) then return end
  local srcbuf = api.nvim_win_get_buf(win)
  if not api.nvim_buf_is_loaded(srcbuf) then return end
  local ft = vim.bo[srcbuf].filetype
  local name = api.nvim_buf_get_name(srcbuf) or ('a.' .. ft)
  local lines = api.nvim_buf_get_lines(preview_buf, 0, -1, true)
  local diffs = vim
    .iter(lines)
    :skip(function(line) return not line:find('^Hunk %d+ of %d+') end)
    :skip(1)
    :totable()
  local start_line = #lines - #diffs
  ---@type diffs.Hunk
  local hunk = {
    filename = name,
    ft = ft,
    lang = vim.treesitter.language.get_lang(ft) or ft,
    start_line = start_line,
    prefix_width = 1,
    lines = diffs,
  }
  local pop_ns = api.nvim_create_namespace('gitsigns_popup')
  api.nvim_buf_clear_namespace(preview_buf, pop_ns, start_line, -1)
  local ns = api.nvim_create_namespace('diffs')
  local config = require('blame_hl._').upvfind(
    require('blame_hl._').upvfind(require('diffs').attach, 'init'),
    'config'
  )
  require('diffs.highlight').highlight_hunk(preview_buf, ns, hunk, {
    hide_prefix = config.hide_prefix,
    highlights = config.highlights,
  })
end

M.patch = function()
  local Popup = require('gitsigns.popup')
  Popup.update = (function(orig)
    return function(winid, bufnr, ...)
      orig(winid, bufnr, ...)
      on_preview(winid, bufnr)
    end
  end)(Popup.update)
  Popup.create = (function(orig)
    return function(...)
      local winid, bufnr = orig(...)
      on_preview(winid, bufnr)
      return winid, bufnr
    end
  end)(Popup.create)
end

return M
