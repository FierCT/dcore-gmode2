if SERVER then
  AddCSLuaFile()
end

local BoxOpen = false
local _DRAllowed = {}
local _DRBlocked = {}

local DermaFrames = {}
local DermaID = {}

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
  local chip = net.ReadEntity()
  local typ = net.ReadString()
  local id = net.ReadString()

  if not _DRAllowed[chip] then return end
  if not DObjects[typ] then return end

  if DermaID[id] then return end

  if typ == "frame" then

    local tab = {}
    tab["x"] = net.ReadFloat()
    tab["y"] = net.ReadFloat()
    tab["width"] = net.ReadFloat()
    tab["height"] = net.ReadFloat()
    tab["title"] = net.ReadString()
    tab["draggable"] = net.ReadBool()

    local frame = vgui.Create("DFrame")
    frame:SetPos(tab["x"], tab["y"])
    frame:SetSize(tab["width"], tab["height"])
    frame:SetTitle(tab["title"])
    frame:SetDraggable(tab["draggable"])
    frame:SetDeleteOnClose(true)
    frame:ShowCloseButton(true)
    frame.OnClose =
    function()
      for k, v in pairs(DermaID) do
        if v == id then
          DermaID[k] = nil
        end
      end
      DermaFrames[id] = nil
    end
    frame:SetSizable(false)
    frame:MakePopup()

    DermaFrames[id] = frame
    DermaID[id] = id

  elseif typ == "text" then
    local tab = {}
    tab["x"] = net.ReadFloat()
    tab["y"] = net.ReadFloat()

    tab["r"] = net.ReadFloat()
    tab["g"] = net.ReadFloat()
    tab["b"] = net.ReadFloat()

    tab["text"] = net.ReadString()
    tab["parent"] = net.ReadString()

    local text = vgui.Create("DLabel", DermaFrames[tab["parent"]])
    text:SetPos(tab["x"], tab["y"])
    text:SetText(tab["text"])
    text:SizeToContents()
    text:SetTextColor(Color(tab["r"],tab["g"],tab["b"]))

    DermaID[id] = tab["parent"]

  elseif typ == "button" then
    local tab = {}
    tab["x"] = net.ReadFloat()
    tab["y"] = net.ReadFloat()

    tab["width"] = net.ReadFloat()
    tab["height"] = net.ReadFloat()

    tab["text"] = net.ReadString()
    tab["parent"] = net.ReadString()

    local button = vgui.Create("DButton", DermaFrames[tab["parent"]])
    button:SetPos(tab["x"], tab["y"])
    button:SetSize(tab["width"], tab["height"])
    button:SetText(tab["text"])
    button.DoClick =
    function()
      net.Start("f_dbuttonpress")
        net.WriteEntity(chip)
        net.WriteString(id)
      net.SendToServer()
    end

    DermaID[id] = tab["parent"]

  elseif typ == "textentry" then
    local tab = {}
    tab["x"] = net.ReadFloat()
    tab["y"] = net.ReadFloat()

    tab["width"] = net.ReadFloat()
    tab["height"] = net.ReadFloat()

    tab["text"] = net.ReadString()
    tab["parent"] = net.ReadString()

    local textbox = vgui.Create("DTextEntry", DermaFrames[tab["parent"]])
    textbox:SetPos(tab["x"], tab["y"])
    textbox:SetSize(tab["width"], tab["height"])
    textbox:SetText(tab["text"])
    textbox.OnEnter =
    function(self)
      net.Start("f_dtextentry")
        net.WriteEntity(chip)
        net.WriteString(id)
        net.WriteString(self:GetValue())
      net.SendToServer()
    end

    DermaID[id] = tab["parent"]

  end

end)

concommand.Add("de2_clear", function(ply,com,args)
  for k, v in pairs(DermaFrames) do
    DermaFrames[k]:Close()
  end
end)

concommand.Add("de2_resetall", function(ply,com,args)
  _DRAllowed = {}
  print("Success! Players no longer have access to create Derma on your screen.")
end)
