--[[
  ReEQ3 Save Tonal Target
  Saves the tonal target of the ReEQ3 whose Tonal Balance panel was open last into the target library
  (REAPER/Data/ReEQ3/Targets), where every ReEQ3 lists it under Library in its target menu.
  MIT License, (c) 2026 Eloy Platas.
]]

local GM_REG, GM_SLOTS, GM_SLOT, RM_SLOT = 4096, 64, 320, 512
local GM_RMT = GM_REG + GM_SLOTS * GM_SLOT
local GM_TBX = GM_RMT + GM_SLOTS * RM_SLOT
local TSIZE = 525

reaper.gmem_attach("ReEQ3")
local t = reaper.gmem_read(GM_TBX)
if t == 0 or reaper.gmem_read(GM_TBX + 100 + 522) ~= 1 then
  reaper.ShowMessageBox("Open the Balance panel of the ReEQ3 whose target you want to save, then run this action again.", "ReEQ3", 0)
  return
end

local n = math.floor(reaper.gmem_read(GM_TBX + 2))
local chars = {}
for i = 0, n - 1 do chars[#chars + 1] = string.char(math.floor(reaper.gmem_read(GM_TBX + 3 + i)) % 256) end
local name = table.concat(chars)

local ok, input = reaper.GetUserInputs("Save tonal target", 1, "Name:,extrawidth=160", name)
if not ok then return end
input = input:gsub('[\\/:%*%?"<>|,]', "_"):gsub("^%s+", ""):gsub("%s+$", "")
if input == "" then return end

local dir = reaper.GetResourcePath() .. "/Data/ReEQ3/Targets"
reaper.RecursiveCreateDirectory(dir, 0)
local path = dir .. "/" .. input .. ".txt"

local names, seen = {}, false
local fi = io.open(dir .. "/index.txt", "r")
if fi then
  for l in fi:lines() do
    l = l:gsub("%s+$", "")
    if l ~= "" then names[#names + 1] = l; if l == input then seen = true end end
  end
  fi:close()
end
if seen and reaper.ShowMessageBox('"' .. input .. '" is already in the library. Replace it?', "ReEQ3", 1) ~= 1 then return end

local f = io.open(path, "w")
if not f then reaper.ShowMessageBox("Couldn't write " .. path, "ReEQ3", 0) return end
f:write("ReEQ3 tonal target 1\n", input, "\n")
for i = 0, TSIZE - 1 do f:write(string.format("%.6f\n", reaper.gmem_read(GM_TBX + 100 + i))) end
f:close()

if not seen then names[#names + 1] = input end
local fo = io.open(dir .. "/index.txt", "w")
for _, l in ipairs(names) do fo:write(l, "\n") end
fo:close()

reaper.ShowMessageBox('Saved "' .. input .. '" to the target library.\nIt is in every ReEQ3\'s target menu, under Library.', "ReEQ3", 0)
