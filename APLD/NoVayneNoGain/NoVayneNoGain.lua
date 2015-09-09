--[[

    No Vayne No Gain by Lillgoalie (Condemn based on Vayne's Mighty Assistant by Manciuszz)
	Fixed by KaoKaoNi (Condemn based on dienofail)
    Version: 1.00
    
    Features:
        - Combo Mode:
            - Uses Q in combo
            - Uses R in combo
        - Auto Condemn enemies
        - Auto Condemn gapclosers
        - Auto Condemn only the target enemy
        - Auto-Level Spells
        - Laneclear using Q with settings
        - Uses BOTRK

    
    Instructions on saving the file:
    - Save the file in scripts folder
--]]

if myHero.charName ~= "Vayne" then return end
assert(load(Base64Decode("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"), nil, "bt", _ENV))() ScriptStatus("QDGGDJFFIJF") 
class("ScriptUpdate")
function ScriptUpdate:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
  self.LocalVersion = LocalVersion
  self.Host = Host
  self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
  self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
  self.SavePath = SavePath
  self.CallbackUpdate = CallbackUpdate
  self.CallbackNoUpdate = CallbackNoUpdate
  self.CallbackNewVersion = CallbackNewVersion
  self.CallbackError = CallbackError
  AddDrawCallback(function() self:OnDraw() end)
  self:CreateSocket(self.VersionPath)
  self.DownloadStatus = 'Connect to Server for VersionInfo'
  AddTickCallback(function() self:GetOnlineVersion() end)
end

function ScriptUpdate:print(str)
  print('<font color="#FFFFFF">'..os.clock()..': '..str)
end

function ScriptUpdate:OnDraw()

  if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
	DrawText3D('No Vayne No Gain',myHero.x,myHero.y,myHero.z+70, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
    DrawText3D('Download Status: '..(self.DownloadStatus or 'Unknown'),myHero.x,myHero.y,myHero.z+50, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
  end
  
end

function ScriptUpdate:CreateSocket(url)

  if not self.LuaSocket then
    self.LuaSocket = require("socket")
  else
    self.Socket:close()
    self.Socket = nil
    self.Size = nil
    self.RecvStarted = false
  end
  
  self.LuaSocket = require("socket")
  self.Socket = self.LuaSocket.tcp()
  self.Socket:settimeout(0, 'b')
  self.Socket:settimeout(99999999, 't')
  self.Socket:connect('sx-bol.eu', 80)
  self.Url = url
  self.Started = false
  self.LastPrint = ""
  self.File = ""
end

function ScriptUpdate:Base64Encode(data)

  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  
  return ((data:gsub('.', function(x)
  
    local r,b='',x:byte()
    
    for i=8,1,-1 do
      r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0')
    end
    
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
  
    if (#x < 6) then
      return ''
    end
    
    local c=0
    
    for i=1,6 do
      c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0)
    end
    
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
  
end

function ScriptUpdate:GetOnlineVersion()

  if self.GotScriptVersion then
    return
  end
  
  self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
  
  if self.Status == 'timeout' and not self.Started then
    self.Started = true
    self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
  end
  
  if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
    self.RecvStarted = true
    self.DownloadStatus = 'Downloading VersionInfo (0%)'
  end
  
  self.File = self.File .. (self.Receive or self.Snipped)
  
  if self.File:find('</s'..'ize>') then
  
    if not self.Size then
      self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
    end
    
    if self.File:find('<scr'..'ipt>') then
    
      local _,ScriptFind = self.File:find('<scr'..'ipt>')
      local ScriptEnd = self.File:find('</scr'..'ipt>')
      
      if ScriptEnd then
        ScriptEnd = ScriptEnd-1
      end
      
      local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
      
      self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
    end
    
  end
  
  if self.File:find('</scr'..'ipt>') then
    self.DownloadStatus = 'Downloading VersionInfo (100%)'
    
    local a,b = self.File:find('\r\n\r\n')
    
    self.File = self.File:sub(a,-1)
     self.NewFile = ''
    
    for line,content in ipairs(self.File:split('\n')) do
    
      if content:len() > 5 then
        self.NewFile = self.NewFile .. content
      end
      
    end
    
    local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
    local ContentEnd, _ = self.File:find('</sc'..'ript>')
    
    if not ContentStart or not ContentEnd then
    
      if self.CallbackError and type(self.CallbackError) == 'function' then
        self.CallbackError()
      end
      
    else
      self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart+1,ContentEnd-1)))
      self.OnlineVersion = tonumber(self.OnlineVersion)
      
      if self.OnlineVersion > self.LocalVersion then
      
        if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
          self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
        end
        
        self:CreateSocket(self.ScriptPath)
        self.DownloadStatus = 'Connect to Server for ScriptDownload'
        AddTickCallback(function() self:DownloadUpdate() end)
      else
        
        if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
          self.CallbackNoUpdate(self.LocalVersion)
        end
        
      end
      
    end
    
    self.GotScriptVersion = true
  end
  
end

function ScriptUpdate:DownloadUpdate()

  if self.GotScriptUpdate then
    return
  end
  
  self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
  
  if self.Status == 'timeout' and not self.Started then
    self.Started = true
    self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
  end
  
  if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
    self.RecvStarted = true
    self.DownloadStatus = 'Downloading Script (0%)'
  end
  
  self.File = self.File .. (self.Receive or self.Snipped)
  
  if self.File:find('</si'..'ze>') then
  
    if not self.Size then
      self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
    end
    
    if self.File:find('<scr'..'ipt>') then
    
      local _,ScriptFind = self.File:find('<scr'..'ipt>')
      local ScriptEnd = self.File:find('</scr'..'ipt>')
      
      if ScriptEnd then
        ScriptEnd = ScriptEnd-1
      end
      
      local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
      
      self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
    end
    
  end
  
  if self.File:find('</scr'..'ipt>') then
    self.DownloadStatus = 'Downloading Script (100%)'
    
    local a,b = self.File:find('\r\n\r\n')
    
    self.File = self.File:sub(a,-1)
    self.NewFile = ''
    
    for line,content in ipairs(self.File:split('\n')) do
    
      if content:len() > 5 then
        self.NewFile = self.NewFile .. content
      end
      
    end
    
    local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
    local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
    
    if not ContentStart or not ContentEnd then
      
      if self.CallbackError and type(self.CallbackError) == 'function' then
        self.CallbackError()
      end
      
    else
      
      local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
      local newf = newf:gsub('\r','')
      
      if newf:len() ~= self.Size then
      
        if self.CallbackError and type(self.CallbackError) == 'function' then
          self.CallbackError()
        end
        
        return
      end
      
      local newf = Base64Decode(newf)
      
      if type(load(newf)) ~= 'function' then
      
        if self.CallbackError and type(self.CallbackError) == 'function' then
          self.CallbackError()
        end
        
      else
      
        local f = io.open(self.SavePath,"w+b")
        
        f:write(newf)
        f:close()
        
        if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
          self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
        end
        
      end
      
    end
    
    self.GotScriptUpdate = true
  end
  
end

require 'VPrediction'

local ts
local Menu
local enemyTable = GetEnemyHeroes()
local informationTable = {}
local spellExpired = true
local eRange, eSpeed, eDelay, eRadius = 1000, 2200, 0.25, nil
local VP = VPrediction()
local AllClassMenu = 16
local qOff, wOff, eOff, rOff = 0,0,0,0
local abilitySequence = {1, 2, 3, 1, 1, 4, 1, 2, 1, 2, 4, 2, 2, 3, 3, 4, 3, 3}
local MMALoad, orbload, RebornLoad, RevampedLoaded, SxOLoad = nil, false, nil, nil, nil
local silverTable = {}

ScriptName = "NoVayneNoGain"
VERSION = 1.02
local function _print(msg)
	print("<font color=\"#33CCCC\"><b>[NoVayneNoGain] </b></font> <font color=\"#fff8e7\">"..msg..". </b></font>")
end
function OnOrbLoad()
	if _G.MMA_LOADED then
		_print("MMA LOAD")
		MMALoad = true
		orbload = true
	elseif _G.AutoCarry then
		if _G.AutoCarry.Helper then
			_print("SIDA AUTO CARRY: REBORN LOAD")
			RebornLoad = true
			orbload = true
		else
			_print("SIDA AUTO CARRY: REVAMPED LOAD")
			RevampedLoaded = true
			orbload = true
		end
	elseif _G.Reborn_Loaded then
		SacLoad = true
		DelayAction(OnOrbLoad, 1)
	elseif FileExist(LIB_PATH .. "SxOrbWalk.lua") then
		_print("SxOrbWalk Load")
		require 'SxOrbWalk'
		SxO = SxOrbWalk()
		SxOLoad = true
		orbload = true
	end
end

local function OrbTarget(range)
	local T
	if MMALoad then T = _G.MMA_Target end
	if RebornLoad then T = _G.AutoCarry.Crosshair.Attack_Crosshair.target end
	if RevampedLoaded then T = _G.AutoCarry.Orbwalker.target end
	if SxOLoad then T = SxO:GetTarget() end
	if SOWLoaded then T = SOW:GetTarget() end
	if T == nil then 
		T = STS:GetTarget(range)
	end
	if T and T.type == player.type and ValidTarget(T, range) then
		return T
	end
end


function OnLoad()
	
	ToUpdate = {}
	ToUpdate.Host = "raw.githubusercontent.com"
	ToUpdate.VersionPath = "/kej1191/anonym/master/APLD/NoVayneNoGain/NoVayneNoGain.version"
	ToUpdate.ScriptPath =  "/kej1191/anonym/master/APLD/NoVayneNoGain/NoVayneNoGain.lua"
	ToUpdate.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
	ToUpdate.CallbackUpdate = function(NewVersion, OldVersion) print("<font color=\"#33CCCC\"><b>[NoVayneNoGain] </b></font> <font color=\"#fff8e7\">Updated to "..NewVersion..". </b></font>") end
	ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#33CCCC\"><b>[NoVayneNoGain] </b></font> <font color=\"#fff8e7\">You have lastest version ("..OldVersion..")</b></font>") end
	ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#33CCCC\"><b>[NoVayneNoGain] </b></font> <font color=\"#fff8e7\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
	ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#33CCCC\"><b>[NoVayneNoGain] </b></font> <font color=\"#fff8e7\">Error while Downloading. Please try again.</b></font>") end
	ScriptUpdate(VERSION, true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
	OnOrbLoad()
    ts = TargetSelector(TARGET_NEAR_MOUSE,1000)

    Menu = scriptConfig("No Vayne No Gain", "VayneBL")

    Menu:addSubMenu("["..myHero.charName.." - Orbwalker]", "SOWorb")
    if SxOLoad then
		SxO:LoadToMenu(Menu.SOWorb)
	elseif SacLoad then
		Menu.SOWorb:addParam("", "SAC Detected", SCRIPT_PARAM_INFO, "")
	elseif MMALoad then
		Menu.SOWorb:addParam("", "MMA Detected", SCRIPT_PARAM_INFO, "")
	end
    Menu:addSubMenu("["..myHero.charName.." - Combo]", "VayneCombo")
    Menu.VayneCombo:addParam("combo", "Combo key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    Menu.VayneCombo:addParam("comboQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
    Menu.VayneCombo:addParam("comboR", "Use R in combo", SCRIPT_PARAM_ONOFF, true)
    Menu.VayneCombo:addParam("comboRRange", "Enemies in range for R", SCRIPT_PARAM_SLICE, 2, 0, 5, 0)
    Menu.VayneCombo:addSubMenu("Item usage", "itemUse")
    Menu.VayneCombo.itemUse:addParam("BOTRK", "Use BOTRK in combo", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Harass]", "Harass")
	Menu.Harass:addParam("harass", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	Menu.Harass:addParam("LastE", "3hit with E", SCRIPT_PARAM_ONOFF, true)
	
    Menu:addSubMenu("["..myHero.charName.." - Laneclear]", "LaneC")
    Menu.LaneC:addParam("laneclr", "Laneclear key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
    Menu.LaneC:addParam("clearQ", "Use Q in laneclear", SCRIPT_PARAM_ONOFF, true)
    Menu.LaneC:addParam("laneclearMana", "Min mana % to use Q in laneclear", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)

    Menu:addSubMenu("["..myHero.charName.." - Additionals]", "Ads")
    Menu.Ads:addParam("AutoLevelspells", "Auto-Level Spells", SCRIPT_PARAM_ONOFF, false)

    Menu:addSubMenu("["..myHero.charName.." - Wall Tumble]", "WallT") -- Credits Jire
    Menu.WallT:addParam("midwall", "Mid Wall Key", SCRIPT_PARAM_ONKEYDOWN, false, 56)
    Menu.WallT:addParam("drakewall", "Drake Wall Key", SCRIPT_PARAM_ONKEYDOWN, false, 57)

    Menu:addSubMenu("["..myHero.charName.." - Condemn]", "Condemn")

    Menu.Condemn:addSubMenu("Features & Settings", "settingsSubMenu")
    Menu.Condemn:addSubMenu("Disable Auto-Condemn on", "condemnSubMenu")

    Menu.Condemn:addParam("autoCondemn", "Auto-Condemn Toggle:", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("Z"))
    Menu.Condemn:addParam("switchKey", "hot key mode:", SCRIPT_PARAM_ONOFF, true)
	Menu.Condemn:addParam("Condemn", "Condemn key:", SCRIPT_PARAM_ONKEYDOWN, false, 32)

    Menu.Condemn:addSubMenu("Only Condemn current target", "OnlyCurrentTarget")
    Menu.Condemn.OnlyCurrentTarget:addParam("Condemntarget", "Only condemn current target", SCRIPT_PARAM_ONOFF, false)
    Menu.Condemn.OnlyCurrentTarget:addTS(ts)
    ts.name = "Condemn"

    Menu.Condemn.settingsSubMenu:addParam("PushAwayGapclosers", "Push Gapclosers Away", SCRIPT_PARAM_ONOFF, true)
    Menu.Condemn.settingsSubMenu:addParam("CondemnAssistant", "Condemn Visual Assistant:", SCRIPT_PARAM_ONOFF, true)
    Menu.Condemn.settingsSubMenu:addParam("pushDistance", "Push Distance", SCRIPT_PARAM_SLICE, 440, 0, 450, 0) -- Reducing this value means that the enemy has to be closer to the wall, so you could cast condemn.
    Menu.Condemn.settingsSubMenu:addParam("eyeCandy", "After-Condemn Circle:", SCRIPT_PARAM_ONOFF, true)
	Menu.Condemn.settingsSubMenu:addParam("accuracy", "Accuracy", SCRIPT_PARAM_SLICE, 5, 1, 50, 15)

    Menu.Condemn:permaShow("autoCondemn")
    -- Override in case it's stuck.
--    Menu.Condemn.pushDistance = 300
    Menu.Condemn.autoCondemn = true
    Menu.Condemn.switchKey = false

    for i, enemy in ipairs(enemyTable) do
        Menu.Condemn.condemnSubMenu:addParam("disableCondemn"..i, " >> "..enemy.charName, SCRIPT_PARAM_ONOFF, false)
        Menu.Condemn["disableCondemn"..i] = false -- Override
    end

    Menu:addSubMenu("["..myHero.charName.." - Drawings]", "drawings")
    Menu.drawings:addParam("drawCircleAA", "Draw AA Range", SCRIPT_PARAM_ONOFF, true)

    PrintChat("<font color = \"#33CCCC\">No Vayne No Gain by</font> <font color = \"#fff8e7\">Lillgoalie</font> <font color = \"#33CCCC\"> Fixed by </font> <font color = \"#fff8e7\"> KaoKaoNi </font>")
	
	AddApplyBuffCallback(function(source, unit, buff) OnApplyBuff(source, unit, buff) end)
	AddUpdateBuffCallback(function(unit, buff, stacks) OnUpdateBuff(unit, buff, stacks) end)
	AddRemoveBuffCallback(function(unit, buff) OnRemoveBuff(unit, buff) end)
	
end

function OnApplyBuff(source, unit, buff)
	if unit and buff.name == "vaynesilvereddebuff" then
		_silver = { unit = unit, stack = 1 }
		table.insert(silverTable, _silver)
	end
end

function OnUpdateBuff(unit, buff, stacks)
	if unit and buff.name == "vaynesilvereddebuff" then
		for index , _unit in ipairs(silverTable) do
			if _unit.unit == unit then
				unit.stack = stacks
			end
		end
	end
end

function OnRemoveBuff(unit, buff)
	if unit and buff.name == "vaynesilvereddebuff" then
		for index , _unit in ipairs(silverTable) do
			if _unit.unit == unit then
				table.remove(silverTable, index)
			end
		end
	end
end

function OnTick()
    ts:update()
    if CountEnemyHeroInRange(600) >= Menu.VayneCombo.comboRRange then
        if (Menu.VayneCombo.comboR) then
            if (Menu.VayneCombo.combo) then
                if (myHero:CanUseSpell(_R) == READY) then
                    CastSpell(_R)
                end
            end
        end
    end
    if (Menu.VayneCombo.combo) then
        UseBotrk()
    end
	if Menu.Harass.Harass then
		Harass()
	end
    if Menu.Ads.AutoLevelspells then
        AutoLevel()
    end

    if Menu.WallT.drakewall then
        DrakeWall()
    end

    if Menu.WallT.midwall then
        MidWall()
    end
	
	if GetGame().isOver then
		UpdateWeb(false, ScriptName, id, HWID)
		startUp = false;
	end
	
	if (not Menu.Condemn.switchKey and Menu.Condemn.autoCondemn) or (Menu.Condemn.switchKey and Menu.Condemn.Condemn) then
        if not Menu.Condemn.OnlyCurrentTarget.Condemntarget then
            CondemnAll()
        elseif Menu.Condemn.OnlyCurrentTarget.Condemntarget then
            CondemnNearMouse()
        end
    end
end

function Harass()
	if Menu.Harass.LastE then
		local ETarget = OrbTarget()
		if myHero:CanUseSpell(_E) == READY then
			for index , _unit in ipairs(silverTable) do
				if _unit.unit == ETarget and _unit.stack == 2 then
					CastSpell(_E, _unit.unit)
				end
			end
		end
	end
end

function DrakeWall()
     if Menu.WallT.drakewall and myHero.x < 11540 or myHero.x > 11600 or myHero.z < 4638 or myHero.z > 4712 then
      myHero:MoveTo(11590.95, 4656.26)
    else
      myHero:MoveTo(11590.95, 4656.26)
      CastSpell(_Q, 11334.74, 4517.47)
    end
end

function MidWall()
    if Menu.WallT.midwall and myHero.x < 7204 or myHero.x > 7204 or myHero.z < 8770 or myHero.z > 8770 then
      myHero:MoveTo(7204, 8770)
    else
      myHero:MoveTo(7204, 8770)
      CastSpell(_Q, 6818, 8510)
    end
end

function AutoLevel()
    local qL, wL, eL, rL = player:GetSpellData(_Q).level + qOff, player:GetSpellData(_W).level + wOff, player:GetSpellData(_E).level + eOff, player:GetSpellData(_R).level + rOff
    if qL + wL + eL + rL < player.level then
        local spellSlot = { SPELL_1, SPELL_2, SPELL_3, SPELL_4, }
        local level = { 0, 0, 0, 0 }
        for i = 1, player.level, 1 do
            level[abilitySequence[i]] = level[abilitySequence[i]] + 1
        end
        for i, v in ipairs({ qL, wL, eL, rL }) do
        if v < level[i] then LevelSpell(spellSlot[i]) end
        end
    end
end

function UseBotrk()
    if ts.target ~= nil and Menu.VayneCombo.combo and GetDistance(ts.target) < 450 and not ts.target.dead and ts.target.visible and GetInventorySlotItem(3153) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3153)) == READY then
        if (Menu.VayneCombo.itemUse.BOTRK) then 
            CastSpell(GetInventorySlotItem(3153), ts.target)
        end
    end
end

function OnDraw()
    if myHero.dead then return end

    DrawCircle(6623, 100, 8649, 100, ARGB(0, 102, 0, 0))
    DrawCircle(11590.95, 100, 4656.26, 100, ARGB(0, 102, 0, 0))

    if (Menu.drawings.drawCircleAA) then
        DrawCircle(myHero.x, myHero.y, myHero.z, 655, ARGB(255, 0, 255, 0))
    end
end

function CondemnAll()
        if IsKeyDown(AllClassMenu) then
        Menu.Condemn._param[1].pType = Menu.Condemn.switchKey and 2 or 3
        Menu.Condemn._param[1].text  = Menu.Condemn.switchKey and "Auto-Condemn OnHold:" or "Auto-Condemn Toggle:"
        if Menu.Condemn.switchKey and Menu.Condemn.autoCondemn then
            Menu.Condemn.autoCondemn = false
        end
    end

    if myHero:CanUseSpell(_E) == READY then
        if Menu.Condemn.settingsSubMenu.PushAwayGapclosers then
            if not spellExpired and (GetTickCount() - informationTable.spellCastedTick) <= (informationTable.spellRange/informationTable.spellSpeed)*1000 then
                local spellDirection     = (informationTable.spellEndPos - informationTable.spellStartPos):normalized()
                local spellStartPosition = informationTable.spellStartPos + spellDirection
                local spellEndPosition   = informationTable.spellStartPos + spellDirection * informationTable.spellRange
                local heroPosition = Point(myHero.x, myHero.z)

                local lineSegment = LineSegment(Point(spellStartPosition.x, spellStartPosition.y), Point(spellEndPosition.x, spellEndPosition.y))
                --lineSegment:draw(ARGB(255, 0, 255, 0), 70)

                if lineSegment:distance(heroPosition) <= (not informationTable.spellIsAnExpetion and 65 or 200) then
                    CastSpell(_E, informationTable.spellSource)
                end
            else
                spellExpired = true
                informationTable = {}
            end
        end

        if not Menu.Condemn.OnlyCurrentTarget.Condemntarget and Menu.Condemn.autoCondemn then
            for i, enemyHero in ipairs(enemyTable) do
                if not Menu.Condemn.condemnSubMenu["disableCondemn"..i] then 
                    InsideTheWall = CondemnMethod(enemyHero)
					if InsideTheWall then CastSpell(_E, enemyHero) end
                end
            end
        end
    end
end

function CondemnNearMouse()
        if IsKeyDown(AllClassMenu) then
        Menu.Condemn._param[1].pType = Menu.Condemn.switchKey and 2 or 3
        Menu.Condemn._param[1].text  = Menu.Condemn.switchKey and "Auto-Condemn OnHold:" or "Auto-Condemn Toggle:"
        if Menu.Condemn.switchKey and Menu.Condemn.autoCondemn then
            Menu.Condemn.autoCondemn = false
        end
    end

    if myHero:CanUseSpell(_E) == READY then
        if Menu.Condemn.settingsSubMenu.PushAwayGapclosers then
            if not spellExpired and (GetTickCount() - informationTable.spellCastedTick) <= (informationTable.spellRange/informationTable.spellSpeed)*1000 then
                local spellDirection     = (informationTable.spellEndPos - informationTable.spellStartPos):normalized()
                local spellStartPosition = informationTable.spellStartPos + spellDirection
                local spellEndPosition   = informationTable.spellStartPos + spellDirection * informationTable.spellRange
                local heroPosition = Point(myHero.x, myHero.z)

                local lineSegment = LineSegment(Point(spellStartPosition.x, spellStartPosition.y), Point(spellEndPosition.x, spellEndPosition.y))
                --lineSegment:draw(ARGB(255, 0, 255, 0), 70)

                if lineSegment:distance(heroPosition) <= (not informationTable.spellIsAnExpetion and 65 or 200) then
                    CastSpell(_E, informationTable.spellSource)
                end
            else
                spellExpired = true
                informationTable = {}
            end
        end

        if Menu.Condemn.autoCondemn and Menu.Condemn.OnlyCurrentTarget.Condemntarget then
            for i, enemyHero in ipairs(enemyTable) do
                if not Menu.Condemn.condemnSubMenu["disableCondemn"..i] then 
					InsideTheWall = CondemnMethod(enemyHero)
					if InsideTheWall then CastSpell(_E, enemyHero) end
                end
            end
        end
    end
end

function CondemnMethod(enemyHero)
	ePos = nil
	if enemyHero ~= nil and enemyHero.valid and not enemyHero.dead and enemyHero.visible and GetDistance(enemyHero) <= 800 and GetDistance(enemyHero) > 0 then
		throwaway, Hitchance, troll = VP:GetLineCastPosition(enemyHero, 0.250, 0, 600, 2200, myHero, false)
		if Hitchance >= 1 then
			ePos = troll
		end
	else
		ePos = nil
	end
	maxxPushPosition = Vector(ePos) + (Vector(ePos) - myHero):normalized()*Menu.Condemn.settingsSubMenu.pushDistance
	if ePos ~= nil then
		local checks = math.ceil(Menu.Condemn.settingsSubMenu.accuracy)
		local checkDistance = math.ceil(Menu.Condemn.settingsSubMenu.pushDistance/checks)
		local InsideTheWall = false
		for k=1, checks, 1 do
			local PushPosition = Vector(ePos) + Vector(Vector(ePos) - Vector(myHero)):normalized()*(checkDistance*k)
			if IsWall(D3DXVECTOR3(PushPosition.x, PushPosition.y, PushPosition.z)) then
				return true
			end
		end
	end
	return false
end

function OnProcessSpell(unit, spell)
    if unit.isMe and spell.name:lower():find("attack") and Menu.VayneCombo.combo and Menu.VayneCombo.comboQ then
        SpellTarget = spell.target
        if SpellTarget.type == myHero.type then
            DelayAction(function() CastSpell(_Q, mousePos.x, mousePos.z) end, spell.windUpTime - GetLatency() / 2000)
        end
    end

    if unit.isMe and spell.name:lower():find("attack") and Menu.LaneC.clearQ and Menu.LaneC.laneclr and myHero.mana >= (myHero.maxMana*(Menu.LaneC.laneclearMana*0.01)) and getDmg("AD", unit , myHero) < unit.health then
        SpellTarget = spell.target
            DelayAction(function() CastSpell(_Q, mousePos.x, mousePos.z) end, spell.windUpTime - GetLatency() / 2000)
    end

    if not Menu.Condemn.settingsSubMenu.PushAwayGapclosers then return end

    local jarvanAddition = unit.charName == "JarvanIV" and unit:CanUseSpell(_Q) ~= READY and _R or _Q -- Did not want to break the table below.
    local isAGapcloserUnit = {
--        ['Ahri']        = {true, spell = _R, range = 450,   projSpeed = 2200},
        ['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
        ['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, }, -- Targeted ability
        ['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
        ['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, }, -- Targeted ability
        ['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
        ['Graves']      = {true, spell = _E,                  range = 425,   projSpeed = 2000, exeption = true },
        ['Hecarim']     = {true, spell = _R,                  range = 1000,  projSpeed = 1200, },
        ['Irelia']      = {true, spell = _Q,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
        ['JarvanIV']    = {true, spell = jarvanAddition,      range = 770,   projSpeed = 2000, }, -- Skillshot/Targeted ability
        ['Jax']         = {true, spell = _Q,                  range = 700,   projSpeed = 2000, }, -- Targeted ability
        ['Jayce']       = {true, spell = 'JayceToTheSkies',   range = 600,   projSpeed = 2000, }, -- Targeted ability
        ['Khazix']      = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
        ['Leblanc']     = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
        ['LeeSin']      = {true, spell = 'blindmonkqtwo',     range = 1300,  projSpeed = 1800, },
        ['Leona']       = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
        ['Malphite']    = {true, spell = _R,                  range = 1000,  projSpeed = 1500 + unit.ms},
        ['Maokai']      = {true, spell = _Q,                  range = 600,   projSpeed = 1200, }, -- Targeted ability
        ['MonkeyKing']  = {true, spell = _E,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
        ['Pantheon']    = {true, spell = _W,                  range = 600,   projSpeed = 2000, }, -- Targeted ability
        ['Poppy']       = {true, spell = _E,                  range = 525,   projSpeed = 2000, }, -- Targeted ability
        --['Quinn']       = {true, spell = _E,                  range = 725,   projSpeed = 2000, }, -- Targeted ability
        ['Renekton']    = {true, spell = _E,                  range = 450,   projSpeed = 2000, },
        ['Sejuani']     = {true, spell = _Q,                  range = 650,   projSpeed = 2000, },
        ['Shen']        = {true, spell = _E,                  range = 575,   projSpeed = 2000, },
        ['Tristana']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
        ['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
        ['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
		['Ekko'] 		= {true, spell = _E,				  range = 360,	 projSpeed = 2000, },
    }
    if unit.type == 'obj_AI_Hero' and unit.team == TEAM_ENEMY and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
        if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) then
            if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
--                print('Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
                CastSpell(_E, unit)
            else
                spellExpired = false
                informationTable = {
                    spellSource = unit,
                    spellCastedTick = GetTickCount(),
                    spellStartPos = Point(spell.startPos.x, spell.startPos.z),
                    spellEndPos = Point(spell.endPos.x, spell.endPos.z),
                    spellRange = isAGapcloserUnit[unit.charName].range,
                    spellSpeed = isAGapcloserUnit[unit.charName].projSpeed,
                    spellIsAnExpetion = isAGapcloserUnit[unit.charName].exeption or false,
                }
            end
        end
    end
end