if SERVER then
  AddCSLuaFile()
end

local BoxOpen = false
local _DRAllowed = {}
local _DRBlocked = {}

local DermaFrames = {}
local DermaID = {}

local AD = AllDerma

local function requestSh(ply, id, chip)
  if not IsValid(ply) then return end
  if not ply:IsPlayer() then return end

  if not chip then return end
  if not IsValid(chip) then return end

  if BoxOpen then return end

  surface.PlaySound("plats/elevbell1.wav")
  BoxOpen = true

  local w = vgui.Create("DFrame")
  w:SetTitle("Derma request from "..ply:Name())
  w:SetBackgroundBlur(true)

  w:SetSize(300,119)
  w:Center()
  w:ShowCloseButton(false)
  w:MakePopup()

  local a = vgui.Create("AvatarImage",w)
  a:SetPos(7,32)
  a:SetSize(64,64)
  a:SetPlayer(ply,64)

  local t = vgui.Create("DLabel", w)
  t:SetPos(78,32)
  t:SetText(ply:Name().."'s E2 is asking for permission to use Derma\nWould you like to accept?")
  t:SizeToContents()
  t:SetWrap(true)

  local y = vgui.Create("DButton", w)
  y:SetPos(80,64)
  y:SetSize(100,32)
  y:SetText("Accept")
  y.DoClick = function()
    if !y:GetDisabled() then
      RunConsoleCommand("de2_accept", id)
      _DRAllowed[chip] = true
      BoxOpen = false
      w:Remove()
    end
  end

  local n = vgui.Create("DButton", w)
  n:SetPos(190,64)
  n:SetSize(100,32)
  n:SetText("Deny")
  n.DoClick = function()
    if y:GetDisabled() then
      _DRBlocked[ply:SteamID()] = true
    end
      RunConsoleCommand("de2_deny", id)
      _DRAllowed[chip] = false
      BoxOpen = false
      w:Remove()
  end

  local c = vgui.Create("DCheckBoxLabel", w)
  c:SetPos(7, 99)
  c:SetText("Block "..ply:Name().."'s derma requests?")
  c:SetValue(0)
  c:SizeToContents()
  c.OnChange = function(self, value)
    if value then
      y:SetDisabled(true)
    else
      y:SetDisabled(false)
    end
  end
end

net.Receive("f_drequest", function()
  local ply = net.ReadEntity()
  local chip = net.ReadEntity()
  local id = net.ReadFloat()

  if _DRBlocked[ply:SteamID()] then return end

  if not _DRAllowed[chip] then
    requestSh(ply, id, chip)
  end
end)

concommand.Add("de2_blockplayer", function(ply, com, args)
  _DRBlocked[table.concat(args, "", 1, 5)] = true
  print("Added "..table.concat(args, "", 1, 5))
  end, function()
    local ret = {}
    for k, v in pairs(player.GetAll()) do
      table.insert(ret, "de2_blockplayer "..v:SteamID().." ("..v:Name()..")")
    end

    return ret
end)

concommand.Add("de2_unblockplayer", function(ply, com, args)
  _DRBlocked[table.concat(args, "", 1, 5)] = false
  print("Removed "..table.concat(args, "", 1, 5))
  end, function()
    local ret = {}
    for k, v in pairs(player.GetAll()) do
      table.insert(ret, "de2_unblockplayer "..v:SteamID().." ("..v:Name()..")")
    end

    return ret
end)


-- where we're actually drawing derma! :D

local DObjects = {}
DObjects["frame"] = "frame"
DObjects["text"] = "text"
DObjects["button"] = "button"
DObjects["textentry"] = "textentry"

net.Receive("f_drawderma", function()
  local tab = net.ReadTable()
  local chip = tab["chip"]
  local id = tab["id"]
  local typ = tab["type"]

  if not _DRAllowed[chip] then return end
  if not DObjects[typ] then return end

  if typ == "frame" then

    if DermaID[id] then return end

    local x, y, w, h = tab["x"], tab["y"], tab["w"], tab["h"]
    local title = tab["title"]
    local drag = tab["draggable"]
    local color = tab["color"]

    local frame = vgui.Create("DFrame")
    if x > ScrW() or x < 0 then x = ScrW()/2-w/2 end
    if y > ScrH() or y < 0 then y = ScrH()/2-h/2 end
    frame:SetPos(x, y)
    if w > ScrW() then w = ScrW() end
    if h > ScrH() then h = ScrH() end
    if w < 200 then w = 200 end
    if h < 75 then h = 75 end
    frame:SetSize(w, h)
    frame:SetTitle(title)
    frame:SetDraggable(drag)
    frame:SetDeleteOnClose(true)
    frame:ShowCloseButton(true)

    frame.OnClose =
    function()
      for k, v in pairs(DermaID) do
        if DermaID[k]["parent"] == id then
          DermaID[k] = nil
        end
      end
      DermaFrames[id] = nil
    end

    frame:SetSizable(false)
    frame:MakePopup()

    DermaFrames[id] = frame
    DermaID[id] = {}
    DermaID[id]["parent"] = id
    DermaID[id]["obj"] = frame

  elseif typ == "text" then

    if DermaID[id] then return end

    local x, y = tab["x"], tab["y"]
    local text2 = tab["text"]
    local parent = tab["parent"]
    local color = tab["color"]

    local text = vgui.Create("DLabel", DermaFrames[parent])
    text:SetPos(x,y)
    text:SetText(text2)
    text:SizeToContents()
    text:SetTextColor(Color(color[1],color[2],color[3]))

    DermaID[id] = {}
    DermaID[id]["parent"] = parent
    DermaID[id]["obj"] = text

  elseif typ == "button" then
    local x, y, w, h = tab["x"], tab["y"], tab["w"], tab["h"]
    local text = tab["text"]
    local parent = tab["parent"]
    local color = tab["color"]

    local button = vgui.Create("DButton", DermaFrames[tab["parent"]])
    button:SetPos(x,y)
    button:SetSize(w,h)
    button:SetText(text)
    button:SetTextColor(color)
    button.DoClick =
    function()
      net.Start("f_dbuttonpress")
        net.WriteEntity(chip)
        net.WriteString(id)
      net.SendToServer()
    end

    DermaID[id] = {}
    DermaID[id]["parent"] = parent
    DermaID[id]["obj"] = button

  elseif typ == "textentry" then

    if DermaID[id] then return end

    local x, y, w, h = tab["x"], tab["y"], tab["w"], tab["h"]
    local text = tab["text"]
    local parent = tab["parent"]

    local textbox = vgui.Create("DTextEntry", DermaFrames[parent])
    textbox:SetPos(x,y)
    textbox:SetSize(w,h)
    textbox:SetText(text)
    textbox.OnEnter =
    function(self)
      net.Start("f_dtextentry")
        net.WriteEntity(chip)
        net.WriteString(id)
        net.WriteString(self:GetValue())
      net.SendToServer()
    end

    DermaID[id] = {}
    DermaID[id]["parent"] = parent
    DermaID[id]["obj"] = textbox

  end

concommand.Add("de2_clear", function(ply,com,args)
  for k, v in pairs(DermaID) do
    if k == DermaID[k]["parent"] then
      DermaID[k]["obj"]:Close()
    end
  end
end)

end)

net.Receive("f_paint", function()
  local tab = net.ReadTable()
  local x, y, w, h = tab["x"], tab["y"], tab["w"], tab["h"]
  local id, typ = tab["id"], tab["type"]
  local color = tab["color"]

  if not DermaID[id] then return end

  if not DermaID[id]["paint"] then DermaID[id]["paint"] = {} end
  local drawid = table.Count(DermaID[id]["paint"])+1


  local tab = {}
  tab["x"] = x
  tab["y"] = y
  tab["w"] = w
  tab["h"] = h
  tab["typ"] = typ
  tab["color"] = color
  DermaID[id]["paint"][drawid] = tab

  local obj = DermaID[id]["obj"]
  obj.Paint =
  function()
    for k, v in pairs(DermaID[id]["paint"]) do
      if v["typ"] == "roundedbox" then
        draw.RoundedBox(0, v["x"], v["y"], v["w"], v["h"], v["color"])
      end
    end
  end

end)

concommand.Add("de2_resetall", function(ply,com,args)
  _DRAllowed = {}
  print("Success! Players no longer have access to create Derma on your screen.")
end)
