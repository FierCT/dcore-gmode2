AddCSLuaFile("cl_dcore.lua")

util.AddNetworkString("f_drequest")
util.AddNetworkString("f_drawderma")
util.AddNetworkString("f_dbuttonpress")
util.AddNetworkString("f_dtextentry")
util.AddNetworkString("f_paint")

local Reqs = 0
local ReqsTab = {}
local Player = FindMetaTable("Player")

local Plys = {}

AllDerma = {}

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

      e2.ClkTimeDAccept = CurTime()
      e2.ClkAcceptPly = ply
      e2.ClkTitle = id
      e2:Execute()

    end
  end
end

local function drawFrame(chip, ply, id, x, y, width, height, draggable, title, color)
  if not IsValid(chip) and not chip then return end
  if not id then return end

  if not x then x = 0 end
  if not y then y = 0 end

  if not width then width = 0 end
  if not height then height = 0 end

  if not draggable then draggable = true end
  if not title then title = "Derma Frame" end

  if not color then color = {false} end
  if color[4] then if color[4] < 160 then color[4] = 255 end end

  if isnumber(draggable) then
    if draggable != 0 and draggable != 1 then return end
    if draggable == 0 then draggable = false end
    if draggable == 1 then draggable = true end
  end

  local SendTab = {}
  SendTab["chip"] = chip
  SendTab["type"] = "frame"
  SendTab["id"] = tostring(id)
  SendTab["x"] = x
  SendTab["y"] = y
  SendTab["w"] = width
  SendTab["h"] = height
  SendTab["title"] = title
  SendTab["color"] = color
  SendTab["draggable"] = draggable

  net.Start("f_drawderma")
    net.WriteTable(SendTab)
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

  local SendTab = {}
  SendTab["chip"] = chip
  SendTab["type"] = "text"
  SendTab["id"] = tostring(id)
  SendTab["x"] = x
  SendTab["y"] = y
  SendTab["text"] = tostring(text)
  SendTab["color"] = Color(color[1], color[2], color[3])
  SendTab["parent"] = tostring(parent)

  net.Start("f_drawderma")
    net.WriteTable(SendTab)
  net.Send(ply)
end

local function drawDButton(chip, ply, id, x, y, width, height, text, parent, color)
  if not IsValid(chip) and not chip then return end
  if not id then return end
  if not parent then return end

  if not text then text = "Button" end

  if not x then x = 0 end
  if not y then y = 0 end

  if not width then width = 0 end
  if not height then height = 0 end

  if not color then color = Color(255,255,255) end

  local SendTab = {}
  SendTab["chip"] = chip
  SendTab["type"] = "button"
  SendTab["id"] = tostring(id)
  SendTab["x"] = x
  SendTab["y"] = y
  SendTab["w"] = width
  SendTab["h"] = height
  SendTab["text"] = text
  SendTab["color"] = Color(color[1],color[2],color[3])
  if(table.Count(color)==4) then
    SendTab["color"] = Color(color[1],color[2],color[3],color[4])
  end
  SendTab["parent"] = tostring(parent)

  net.Start("f_drawderma")
    net.WriteTable(SendTab)
  net.Send(ply)
end

local function drawDTextEntry(chip, ply, id, x, y, width, height, text, parent)
  if not IsValid(chip) and not chip then return end
  if not id then return end
  if not parent then return end

  if not text then text = "TextBox" end

  if not x then x = 0 end
  if not y then y = 0 end

  if not width then width = 0 end
  if not height then height = 0 end

  local SendTab = {}
  SendTab["chip"] = chip
  SendTab["type"] = "textentry"
  SendTab["id"] = tostring(id)
  SendTab["x"] = x
  SendTab["y"] = y
  SendTab["w"] = width
  SendTab["h"] = height
  SendTab["text"] = text
  SendTab["parent"] = tostring(parent)

  net.Start("f_drawderma")
    net.WriteTable(SendTab)
  net.Send(ply)
end

local function drawRoundedBox(chip, ply, id, x, y, width, height, color)
  if not chip then return end
  if not id then return end

  if not x then x = 0 end
  if not y then y = 0 end
  if not width then width = 0 end
  if not height then height = 0 end
  if not color then color = Color(255,255,255) end

  if istable(color) then if table.Count(color) < 4 then color = Color(color[1],color[2],color[3]) else color = Color(color[1],color[2],color[3],color[4]) end end

  local SendTab = {}
  SendTab["id"] = tostring(id)
  SendTab["type"] = "roundedbox"
  SendTab["x"] = x
  SendTab["y"] = y
  SendTab["w"] = width
  SendTab["h"] = height
  SendTab["color"] = color

  net.Start("f_paint")
    net.WriteTable(SendTab)
  net.Send(ply)

end

local function canRunDerma(chip, ply)
  if not chip then return 0 end
  if not ply then return 0 end

  if not Plys[ply] then Plys[ply] = {} end
  if not Plys[ply][chip] then Plys[ply][chip] = false end

  if Plys[ply][chip] == true then return 1 end
  if Plys[ply][chip] == false then return 0 end
  if chip.ClkTimeDAccept == CurTime() then return 0 end
  if chip.ClkTimeDButton == CurTime() then return 0 end
  if chip.ClkTimeDTBox == CurTime() then return 0 end
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

e2function void entity:dermaButton(string id, string text, vector2 pos, vector2 size, string parent, vector color)
  drawDButton(self.entity, this, id, pos[1], pos[2], size[1], size[2], text, parent, color)
end

e2function void entity:dermaButton(string id, vector2 pos, vector2 size, string parent, vector color)
  drawDButton(self.entity, this, id, pos[1], pos[2], size[1], size[2], "Button", parent, color)
end

e2function void entity:dermaButton(string id, string text, vector2 pos, vector2 size, string parent)
  drawDButton(self.entity, this, id, pos[1], pos[2], size[1], size[2], text, parent, {255,255,255})
end

e2function void entity:dermaButton(string id, vector2 pos, vector2 size, string parent)
  drawDButton(self.entity, this, id, pos[1], pos[2], size[1], size[2], "Button", parent, {255,255,255})
end

--

e2function void entity:dermaTextBox(string id, string text, vector2 pos, vector2 size, string parent)
  drawDTextEntry(self.entity, this, id, pos[1], pos[2], size[1], size[2], text, parent)
end

e2function void entity:dermaTextBox(string id, vector2 pos, vector2 size, string parent)
  drawDTextEntry(self.entity, this, id, pos[1], pos[2], size[1], size[2], "TextBox", parent)
end

--

e2function number entity:canRunDerma()
  return canRunDerma(self.entity, this)
end

--

e2function void entity:dermaDrawRoundedBox(string id, vector2 pos, vector2 size, vector color)
  drawRoundedBox(self.entity, this, id, pos[1], pos[2], size[1], size[2], color)
end

e2function void entity:dermaDrawRoundedBox(string id, vector2 pos, vector2 size, vector4 color)
  drawRoundedBox(self.entity, this, id, pos[1], pos[2], size[1], size[2], color)
end

--

e2function number dermaAcceptClk()
  if not self.entity.ClkTimeDAccept then return 0 end
  return self.entity.ClkTimeDAccept == CurTime() and 1 or 0
end

e2function entity dermaAcceptClkPly()
  if not self.entity.ClkAcceptPly then return nil end
  if not self.entity.ClkAcceptPly:IsPlayer() then return nil end

  return self.entity.ClkAcceptPly
end

e2function number dermaButtonClk()
  if not self.entity.ClkTimeDButton then return 0 end
  return self.entity.ClkTimeDButton == CurTime() and 1 or 0
end

e2function number dermaButtonClk(string id)
  if not self.entity.ClkTimeDButton then return 0 end
  if not self.entity.ClkButtonTitle then return 0 end
  return (self.entity.ClkButtonTitle == id and self.entity.ClkTimeDButton == CurTime()) and 1 or 0
end

e2function string dermaButtonClkID()
  if not self.entity.ClkButtonTitle then return nil end
  return self.entity.ClkButtonTitle
end

e2function entity dermaButtonClkPly()
  if not self.entity.ClkButtonPly then return nil end
  if not self.entity.ClkButtonPly:IsPlayer() then return nil end

  return self.entity.ClkButtonPly
end

e2function number dermaTextBoxClk()
  if not self.entity.ClkTimeDTBox then return 0 end
  return self.entity.ClkTimeDTBox == CurTime() and 1 or 0
end

e2function number dermaTextBoxClk(string id)
  if not self.entity.ClkTimeDTBox then return 0 end
  if not self.entity.ClkDTBoxTitle then return 0 end
  return (self.entity.ClkDTBoxTitle == id and self.entity.ClkTimeDTBox == CurTime()) and 1 or 0
end

e2function entity dermaTextBoxClkPly()
  if not self.entity.ClkDTBoxPly then return nil end
  if not self.entity.ClkDTBoxPly:IsPlayer() then return nil end

  return self.entity.ClkDTBoxPly
end

e2function string dermaTextBoxClkID()
  if not self.entity.ClkDTBoxTitle then return nil end
  return self.entity.ClkDTBoxTitle
end

e2function string dermaTextBoxClkValue()
  if not self.entity.ClkDTBoxValue then return nil end
  return self.entity.ClkDTBoxValue
end

--

net.Receive("f_dbuttonpress", function(len, ply)
  local chip = net.ReadEntity()
  local id = net.ReadString()

  chip.ClkTimeDButton = CurTime()
  chip.ClkButtonPly = ply
  chip.ClkButtonTitle = id
  chip:Execute()

end)

net.Receive("f_dtextentry", function(len, ply)
  local chip = net.ReadEntity()
  local id = net.ReadString()
  local text = net.ReadString()

  chip.ClkTimeDTBox = CurTime()
  chip.ClkDTBoxPly = ply
  chip.ClkDTBoxTitle = id
  chip.ClkDTBoxValue = text
  chip:Execute()
end)

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
