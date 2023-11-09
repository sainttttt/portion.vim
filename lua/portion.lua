-- main module file
local module = require("portion.module")

local lastWinId = -1
local curWinId = -1
local disableTrack = false

local function isFloating(winid)
  return vim.api.nvim_win_get_config(winid).relative ~= ''
end

local function getCurWinId()
  return vim.fn.win_getid(vim.fn.winnr())
end

---@class Config
---@field opt string Your config option
local config = {
  -- opt = "Hello!",
}

---@class MyModule
local M = {}

---@type Config
M.config = config

M.portion = function()
  local maxWinNum = vim.fn.winnr('$')

  visibleWinIds = {}
  for i=1,maxWinNum do
    -- print(i)
    if vim.fn.winwidth(vim.fn.win_getid(i)) ~= -1
      and not isFloating(vim.fn.win_getid(i)) then
      table.insert(visibleWinIds, vim.fn.win_getid(i))
    end

  end
  -- print(dump(visibleWinIds))
  -- print(curWinId)
  -- print(lastWinId)

  if #visibleWinIds < 3 then
    return
  end

  local width = vim.o.columns
  local numVisWins = #visibleWinIds
  local lastWinMult = 0.1 * numVisWins * numVisWins * 0.1
  local curWinMult = 0.3 * numVisWins * numVisWins * 0.1
  -- print (numVisWins)
  local loss = 1
  if numVisWins > 2 then
    loss = (100 - (curWinMult + lastWinMult) / (numVisWins - 2) * 100) / 100
  end


  local regWidth = (1 / numVisWins)
  local adjustedWidth = regWidth * loss
  local curWinWidth = regWidth * (1 + curWinMult)
  local lastWinWidth = regWidth * (1 + lastWinMult)

  -- print(adjustedWidth, curWinWidth, lastWinWidth)
  local total = (adjustedWidth * (numVisWins - 2) + regWidth * (1+curWinMult) + regWidth * (1+lastWinMult))
  -- print(total)

  disableTrack = true
  for i,v in ipairs(visibleWinIds) do
    -- print(v)
    vim.fn.win_gotoid(v)
    if v == curWinId then
      vim.cmd(" vertical resize " .. width * curWinWidth)
    elseif v == lastWinId then
      vim.cmd(" vertical resize " .. width * lastWinWidth)
    else
      vim.cmd(" vertical resize " .. width * adjustedWidth)
    end
  end
  vim.fn.win_gotoid(curWinId)
  disableTrack = false
end


M.portionSetup() = function()
  vim.api.nvim_create_autocmd('WinEnter', {
    desc = 'tracking portion',

    group = vim.api.nvim_create_augroup('portion_track_last_win', { clear = true }),
    callback = function (opts)
      if disableTrack then
        return
      end
      if vim.bo.filetype == 'NvimTree' then
        return
      end

      if isFloating(getCurWinId()) then
        return
      end

      if curWinId ~= getCurWinId() then
        lastWinId = curWinId
        curWinId = getCurWinId()
      end

      portion()
    end,
  })
end

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  M.portionSetup()
end

return M
