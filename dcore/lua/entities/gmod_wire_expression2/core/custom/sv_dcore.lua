AddCSLuaFile("cl_dcore.lua")

util.AddNetworkString("f_drequest")
util.AddNetworkString("f_drawderma")

local Reqcount = 0
local ReqsTab = {}
local Player = FindMetaTable("Player")
local Plys = {}
AllDerma = {}

local function requestAccess(chip, target)
  local requestor = chip.player
    if not IsValid(target) or not target:IsPlayer() then return 0 end
    if not IsValid(requestor) or not requestor:IsPlayer() then return 0 end
  
    Reqcount = Reqcount + 1
  
    local id = Reqcount
    ReqsTab[id] = {}
    ReqsTab[id]["e2"] = chip
    ReqsTab[id]["requestor"] = requestor
    ReqsTab[id]["ply"] = target

    net.Start("f_drequest")
      net.WriteEntity(requestor)
      net.WriteEntity(chip)
      net.WriteFloat(Reqs)
    net.Send(target)

    MsgC(Color(255,190,0), requestor:Name().." asked "..target:Name().." for Derma permission.\n") -- Need to change color for this

    return 1
end

local function access(tar, id, dec)
  if not id then return end
  id = tonumber(math.Round(id))
  if not ReqsTab[id]["requestor"]:IsPlayer() or not IsValid(ReqsTab[id]["requestor"]) then return end
  if not tar:IsPlayer() or not IsValid(tar) then return end

  local req = ReqsTab[id]["requestor"]
  local chip = ReqsTab[id]["e2"]

  if dec then
    if IsValid(chip) then
      req:ChatPrint("You can now draw Derma objects on "..ply:Name().."'s screen.")
    end
  end
end

local function drawDFrame(chip, tar, id, pos, size, draggable, title, color)
  if not IsValid(chip) or not chip then return end
  if not id then return end
  
  if istable(pos) then
    if not pos[1] then pos[1] = 0 end -- x
    if not pos[2] then pos[2] = 0 end -- y
  else
    return end
  end

  if istable(size) then
    if not size[1] then size[1] = 0 end -- w
    if not size[2] then size[2] = 0 end -- h
  end

  if not title then title = "Derma Frame" end
  if not color then color = {false} end
  if color[4] then if color[4] < 160 then color[4] = 255 end end

  if not draggable then draggable = true end
  if isnumber(draggable) then
    if draggable <= 0 then draggable = false end
    if draggable >= 1 then draggable = true end
  end
  
  local send = {}
  send["chip"] = chip
  send["id"] = tostring(id)
  send["pos"] = {pos[1],pos[2]}
  send["size"] = {size[1],size[2]}
  send["title"] = title
  send["color"] = color
  send["draggable"] = draggable

  net.Start("f_drawderma")
    net.WriteString("DFrame")
    net.WriteTable(send)
  net.Send()
  
end

--

e2function number dermaRequest(entity ply)
  return requestAccess(self.entity, ply)
end

--

e2function void entity:dermaFrame(string id, vector2 pos, vector2 size, draggable, string title)
  drawDFrame(self.entity, this, id, pos, size, draggable, title)
end

--

concommand.Add("de2_accept", function(ply, com, arg)
  if not ply then return end
  if not arg[1] then return end

  if ReqsTab[tonumber(arg[1])]["ply"] == ply then
    if arg[1] then
      if not Plys[ply] then Plys[ply] = {} end
      Plys[ply][ReqsTab[tonumber(arg[1])]["e2"]] = 1
      access(ply, arg[1], true)
      return
    end
  end
end)

concommand.Add("de2_deny", function(ply, com, arg)
  if not ply then return end
  if not arg[1] then return end

  if ReqsTab[tonumber(arg[1])]["ply"] == ply then
    if arg[1] then
      access(ply, arg[1], false)
      return
    end
  end
end)
