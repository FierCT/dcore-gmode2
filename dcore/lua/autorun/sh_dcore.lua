if SERVER then
  AddCSLuaFile()
end

local _DermaCore = {}
_DermaCore["requests"] = {}
_DermaCore["requests"]["isOpen"] = false
_DermaCore["requests"]["instances"] = {}
-- _DermaCore["requests"]["instances"][entity ???] <= 0 or >= 1
-- 0 is denied
-- 1 is allowed
_DermaCore["derma"] = {}

net.Receive("f_drequest", function()
  local sender = net.ReadEntity()
  local chip = net.ReadEntity()
  local id = net.ReadFloat()

  if _DermaCore["requests"]["instances"][sender:SteamID()] <= 0 then return end
  if not IsValid(sender) or not sender:IsPlayer() then return end
  if not IsValid(chip) or not chip then return end
  
  if _DermaCore["requests"]["isOpen"] then return end
  
  --surface.PlaySound("plats/elevbell1.wav")
  local f = vgui.Create("DFrame")
  f:SetBackgroundBlur(true)
  f:SetSize(ScrW()/3, ScrH()/8) -- 1920/3 = 640, 1080/8 = 135...size for most players: 640, 135
  f:Center()
  f:ShowCloseButton(false)
  f:MakePopup()
  
  local a = vgui.Create("AvatarImage", f)
  a:SetPos(6, 32)
  a:SetSize(64, 64)
  a:SetPlayer(sender, 64)
  
  local t = vgui.Create("DLabel", f)
  t:SetPos(76, 32)
  t:SetText(sender:Name().."'s Expression 2 Chip is asking for permission to draw Derma.\nWould you like to accept?")
  t:SizeToContents()
  t:SetWrap(true)
  
  local yes = vgui.Create("DButton", f)
  yes:SetPos(80, 64)
  yes:SetSize(100, 32)
  yes:SetText("Accept")
  yes.DoClick = function()
    if not yes:GetDisabled() then
      RunConsoleCommand("de2_accept", id)
      _DermaCore["requests"]["instances"][chip] = 1
      _DermaCore["requests"]["isOpen"] = false
      f:Remove()
    end
  end
  
  local no = vgui.Create("DButton", f)
  no:SetPos(190, 64)
  no:SetSize(100, 32)
  no:SetText("Deny")
  no.DoClick = function()
    if yes:GetDisabled() then
      _DermaCore["requests"]["instances"][sender:SteamID()] = -1
    end
    RunConsoleCommand("de2_deny", id)
    _DermaCore["requests"]["isOpen"] = false
    f:Remove()
  end
  
  local block = vgui.Create("DCheckBoxLabel", f)
  block:SetPos(7, 99)
  block:SetText("Block "..sender:Name().."'s Derma requests")
  block:SetValue(0)
  block:SizeToContents()
  block.OnChange = function(self, value)
    if value then
      y:SetDisabled(true)
    else
      y:SetDisabled(false)
    end
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

local DermaObj = {}
DermaObj["DFrame"] = true


net.Receive("f_drawderma", function()
  local dtype = net.ReadString()
  local dsent = net.ReadTable()
  
  local inst = dsent["chip"] -- inst == chip
  local id = dsent["id"] -- id of the object, is string, could be number
  
  if not dtype or DermaObj[dtype] then return end
  if not _DermaCore["requests"]["instances"][inst] or _DermaCore["requests"]["instances"][inst] <= 0 then return end
  
  if dtype == "DFrame" then
    if _DermaCore["derma"][id] then return end
    
    local pos = dsent["pos"]
    local size = dsent["size"]
    local canDrag = dsent["draggable"]
    local color = dsent["color"]
    local title = dsent["title"]
    
    size[1] = math.Clamp(size[1], 800, ScrW())
    size[2] = math.Clamp(size[2], 600, ScrH())
    
    pos[1] = math.Clamp(pos[1], 0, ScrW()-size[1])
    pos[2] = math.Clamp(pos[2], 0, ScrH()-size[2])
    
    local f = vgui.Create("DFrame")
    f:SetPos(pos[1], pos[2])
    f:SetSize(size[1], size[2])
    f:SetTitle(title)
    f:SetDraggable(canDrag)
    f:SetDeleteOnClose(true)
    f:ShowCloseButton(true)
    
    f.OnClose = function()
      for k, v in pairs(_DermaCore["derma"]) do
        if _DermaCore["derma"][k]["parent"] == id then
          _DermaCore["derma"][k] = nil
        end
      end
      _DermaCore["derma"][id] = nil
    end
    
    f:SetSizable(false)
    f:MakePopup()
    
    _DermaCore["derma"][id] = {}
    _DermaCore["derma"][id]["parent"] = id
    _DermaCore["derma"][id]["obj"] = f
    
  elseif dtype == "DText" then
    if _DermaCore["derma"][id] then return end
    
    local pos = dsent["pos"]
    local text = dsent["text"]
    local parent = dsent["parent"]
    local color = tab["color"]
    
    local t = vgui.Create("DLabel", _DermaCore["derma"][parent]["obj"])
    t:SetPos(pos[1] ,pos[2])
    t:SetText(text)
    t:SizeToContents()
    t:SetTextColor(Color(color[1], color[2], color[3]))
    
    _DermaCore["derma"][id] = {}
    _DermaCore["derma"][id]["parent"] = parent
    _DermaCore["derma"][id]["obj"] = t
      
    -- TODO: Add in DButton, DTextEntry, and more
    
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
  -- TODO: Remake Paint... again
end)

concommand.Add("de2_resetall", function(ply, com, args)
  _DermaCore["requests"]["instances"] = {}
  print("Success! Players no longer have access to create Derma on your screen.")
end)
