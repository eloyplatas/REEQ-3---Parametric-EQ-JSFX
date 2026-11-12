-- @description ReEQ3: upgrade ReEQ and ReEQ2 to ReEQ3
-- @author Eloy Platas, after Justin Johnson's ReEQ upgrade script
-- @version 1.0.0
-- @about
--   Moves every ReEQ2 (and ReEQ) in the project (track, master and take FX) over to ReEQ3, keeping all
--   its settings: ReEQ3 reads their states, and its sliders 1-233 are ReEQ2's. Bells, shelves and tilt
--   shelves keep their 12 dB/oct. If any tracks are selected you can upgrade just those. One undo point.

local OLD = "ReJJ[/\\]ReEQ2?[/\\]ReEQ2?%.jsfx"

-- ReEQ3 must be installed where REAPER will look for it
local function reeq3_installed()
  local base = reaper.GetResourcePath() .. "/Effects/ReJJ/ReEQ3/ReEQ3.jsfx"
  return reaper.file_exists(base)
end

-- Swap the path on JS lines only (quoted or not), keeping the separators REAPER wrote
local function upgrade_chunk(chunk)
  local n2, n1
  chunk, n2 = chunk:gsub("(<JS%s+\"?)ReJJ([/\\])ReEQ2([/\\])ReEQ2%.jsfx", "%1ReJJ%2ReEQ3%3ReEQ3.jsfx")
  chunk, n1 = chunk:gsub("(<JS%s+\"?)ReJJ([/\\])ReEQ([/\\])ReEQ%.jsfx", "%1ReJJ%2ReEQ3%3ReEQ3.jsfx")
  return chunk, n1 + n2
end

local function upgrade_track(track)
  local ok, chunk = reaper.GetTrackStateChunk(track, "", false)
  if not ok or not chunk:find(OLD) then return 0 end
  local new, n = upgrade_chunk(chunk)
  if n > 0 then reaper.SetTrackStateChunk(track, new, false) end
  return n
end

local function main()
  if not reeq3_installed() then
    reaper.ShowMessageBox("ReEQ3 isn't installed (Effects/ReJJ/ReEQ3/ReEQ3.jsfx).\n\nInstall it first, then run this again.",
      "ReEQ3: upgrade", 0)
    return
  end

  local tracks = {}
  local nsel = reaper.CountSelectedTracks(0)
  if nsel > 0 then
    local r = reaper.ShowMessageBox(string.format(
      "Upgrade ReEQ2 only on the %d selected track%s?\n\nYes: selected tracks only\nNo: the whole project",
      nsel, nsel == 1 and "" or "s"), "ReEQ3: upgrade", 3)
    if r == 2 then return end
    if r == 6 then
      for i = 0, nsel - 1 do tracks[#tracks + 1] = reaper.GetSelectedTrack(0, i) end
    end
  end
  if #tracks == 0 then
    tracks[1] = reaper.GetMasterTrack(0)
    for i = 0, reaper.CountTracks(0) - 1 do tracks[#tracks + 1] = reaper.GetTrack(0, i) end
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local count, ntracks = 0, 0
  for _, track in ipairs(tracks) do
    local n = upgrade_track(track)
    if n > 0 then count = count + n; ntracks = ntracks + 1 end
  end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("ReEQ3: upgrade ReEQ2 to ReEQ3", -1)

  reaper.ShowMessageBox(count == 0 and "No ReEQ2 or ReEQ found." or
    string.format("Upgraded %d EQ%s on %d track%s to ReEQ3.", count, count == 1 and "" or "s",
      ntracks, ntracks == 1 and "" or "s"), "ReEQ3: upgrade", 0)
end

main()
