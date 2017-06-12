AddCSLuaFile("cl_derma_fier.lua")
util.AddNetworkString("f_drequest")
util.AddNetworkString("f_drawderma")

local Reqs = 0
local ReqsTab = {}
local Player = FindMetaTable("Player")

local Plys = {}

local function requestAccess(chip, ply)
  local user = chip.player
    if not IsValid(ply) then return 0 end
    if not ply:IsPlayer() then return 0 end
    if not IsValid(user) then return 0 end
    if not user:IsPlayer() then return 0 end

    Reqs = Reqs + 1
    local id = Reqs
    ReqsTab[id] = {}
    ReqsTab[id]["e2"] = chip
    ReqsTab[id]["requestor"] = user
    ReqsTab[id]["ply"] = ply

    net.Start("f_drequest")
      net.WriteEntity(user)
      net.WriteEntity(chip)
      net.WriteFloat(Reqs)
    net.Send(ply)

    MsgC(Color(255,190,0), user:Name().." asked "..ply:Name().." for Derma permission.\n")

    return 1
end

local function access(ply, id, accept)
  if not id then return end
  if not ReqsTab[tonumber(math.Round(id))]["requestor"] then return end
  if not ply then return end
  if not ply:IsPlayer() then return end

  local req = ReqsTab[tonumber(math.Round(id))]["requestor"]
  local e2 = ReqsTab[tonumber(math.Round(id))]["e2"]

  if accept then
    if IsValid(e2) then
      req:ChatPrint("You can now create Derma objects on "..ply:Name().."'s screen.")
      ply:ChatPrint(req:Name().." can now create Derma objects on your screen.")

      e2.ClkTimeDAccept = CurTime()
      e2.ClkPlayer = ply
      e2.ClkTitle = id
      e2:Execute()

    end
  end
end

local function drawFrame(chip, ply, id, x, y, width, height, draggable, title)
  if not IsValid(chip) and not chip then return end
  if not id then return end

  if not x then x = 0 end
  if not y then y = 0 end

  if not width then width = 0 end
  if not height then height = 0 end

  if not draggable then draggable = true end
  if not title then title = "Derma Frame" end

  if isnumber(draggable) then
    if draggable != 0 and draggable != 1 then return end
    if draggable == 0 then draggable = false end
    if draggable == 1 then draggable = true end
  end

  net.Start("f_drawderma")
    net.WriteEntity(chip)
    net.WriteString("frame")
    net.WriteString(tostring(id))

    net.WriteFloat(x)
    net.WriteFloat(y)

    net.WriteFloat(width)
    net.WriteFloat(height)

    net.WriteString(title)
    net.WriteBool(draggable)

  net.Send(ply)
end

local function drawDText(chip, ply, id, x, y, text, parent, color)
  if not IsValid(chip) and not chip then return end
  if not id then return end
  if not text then return end
  if not parent then return end

  if not x then x = 0 end
  if not y then y = 0 end

  if not color then color={255,255,255} end

  net.Start("f_drawderma")
    net.WriteEntity(chip)
    net.WriteString("text")
    net.WriteString(tostring(id))

    net.WriteFloat(x)
    net.WriteFloat(y)

    net.WriteFloat(color[1])
    net.WriteFloat(color[2])
    net.WriteFloat(color[3])

    net.WriteString(text)
    net.WriteString(tostring(parent))
  net.Send(ply)
end

local function canRunDerma(chip, ply)
  if not chip then return 0 end
  if not ply then return 0 end

  if not Plys[ply] then Plys[ply] = {} end
  if not Plys[ply][chip] then Plys[ply][chip] = false end

  if Plys[ply][chip] == true then return 1 end
  if Plys[ply][chip] == false then return 0 end
end

--

e2function number dermaRequest(entity ply)
  return requestAccess(self.entity, ply)
end

--

e2function void entity:dermaFrame(string id, vector2 pos, vector2 size, draggable, string title)
  drawFrame(self.entity, this, id, pos[1], pos[2], size[1], size[2], draggable, title)
end

e2function void entity:dermaFrame(string id, vector2 pos, vector2 size, draggable)
  drawFrame(self.entity, this, id, pos[1], pos[2], size[1], size[2], draggable, "Derma Frame")
end

e2function void entity:dermaFrame(string id, vector2 pos, vector2 size, string title)
  drawFrame(self.entity, this, id, pos[1], pos[2], size[1], size[2], 1, title)
end

e2function void entity:dermaFrame(string id, vector2 pos, vector2 size)
  drawFrame(self.entity, this, id, pos[1], pos[2], size[1], size[2], 1, "Derma Frame")
end

--

e2function void entity:dermaText(string id, string text, vector2 pos, string parent)
  drawDText(self.entity, this, id, pos[1], pos[2], text, parent, {255,255,255})
end

e2function void entity:dermaText(string id, string text, vector2 pos, string parent, vector color)
  drawDText(self.entity, this, id, pos[1], pos[2], text, parent, {color[1],color[2],color[3]})
end

--

e2function number entity:canRunDerma()
  return canRunDerma(self.entity, this)
end

--

e2function number dermaAcceptClk()
  if not self.entity.ClkTimeDAccept then return 0 end
  return self.entity.ClkTimeDAccept == CurTime() and 1 or 0
end

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
