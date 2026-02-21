local M = {}

---@param func function
---@param tname string
---@return any, integer?
M.upvfind = function(func, tname)
  local i = 1
  while true do
    local name, value = debug.getupvalue(func, i)
    if not name then break end
    if name == tname then return value, i end
    i = i + 1
  end
  return nil
end

return M
