local champions = {
    ["Xerath"]          = true,
	["Karthus"]			= true,
	["MissFortune"]		= true,
	--["Varus"]			= true,
}
if champions[myHero.charName] == nil then return end

local function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>MidKing:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end

local VERSION = 1.19

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
    DrawText3D('MidKing',myHero.x,myHero.y,myHero.z+70, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
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

local SCRIPT_LIBS = {
	["HPrediction"] = "https://raw.githubusercontent.com/BolHTTF/BoL/master/HTTF/Common/HPrediction.lua",
	["SPrediction"] = "https://raw.githubusercontent.com/nebelwolfi/BoL/master/Common/SPrediction.lua",
	["VPrediction"] = "",
	["DivinePred"]	= "",
	["SourceLib"] = "https://raw.github.com/LegendBot/Scripts/master/Common/SourceLib.lua",
	["Collision"] = "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/b891699e739f77f77fd428e74dec00b2a692fdef/Common/Collision.lua",
}
function Initiate()
	for LIBRARY, LIBRARY_URL in pairs(SCRIPT_LIBS) do
		if FileExist(LIB_PATH..LIBRARY..".lua") then
			require(LIBRARY)
		else
			DOWNLOADING_LIBS = true
			if LIBRARY == "DivinePred" then
				AutoupdaterMsg("Missing Library! Downloading "..LIBRARY..". If the library doesn't download, please download it manually.")
				DownloadFile("http://divinetek.rocks/divineprediction/DivinePred.lua", LIB_PATH.."DivinePred.lua",function() AutoupdaterMsg("Successfully downloaded "..LIBRARY) end)
				DownloadFile("http://divinetek.rocks/divineprediction/DivinePred.luac", LIB_PATH.."DivinePred.luac",function() AutoupdaterMsg("Successfully downloaded "..LIBRARY) end)
			else
				AutoupdaterMsg("Missing Library! Downloading "..LIBRARY..". If the library doesn't download, please download it manually.")
				DownloadFile(LIBRARY_URL,LIB_PATH..LIBRARY..".lua",function() AutoupdaterMsg("Successfully downloaded "..LIBRARY) end)
			end
		end
	end
	if DOWNLOADING_LIBS then return true end
end
if Initiate() then return end

local STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
local orbload = false
local player = myHero
local TrueRange = myHero.range + myHero:GetDistance(myHero.minBBox)
local minionTable =  minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_MAXHEALTH_DEC)

local SP = SPrediction()
local HP = HPrediction()
local VP = VPrediction()
local dp = DivinePred()

local Colors = { 
    -- O R G B
    Green   =  ARGB(255, 0, 180, 0), 
    Yellow  =  ARGB(255, 255, 215, 00),
    Red     =  ARGB(255, 255, 0, 0),
    White   =  ARGB(255, 255, 255, 255),
    Blue    =  ARGB(255, 0, 0, 255),
}

local SupPred = {"H Prediction", "V Prediction", "S Prediction", "D Prediction"}

function OnOrbLoad()
	if _G.MMA_LOADED then
		AutoupdaterMsg("MMA LOAD")
		MMALoad = true
		orbload = true
	elseif _G.AutoCarry then
		if _G.AutoCarry.Helper then
			AutoupdaterMsg("SIDA AUTO CARRY: REBORN LOAD")
			RebornLoad = true
			orbload = true
		else
			AutoupdaterMsg("SIDA AUTO CARRY: REVAMPED LOAD")
			RevampedLoaded = true
			orbload = true
		end
	elseif _G.Reborn_Loaded then
		SacLoad = true
		DelayAction(OnOrbLoad, 1)
	elseif FileExist(LIB_PATH .. "SxOrbWalk.lua") then
		AutoupdaterMsg("SxOrbWalk Load")
		require 'SxOrbWalk'
		SxO = SxOrbWalk()
		SxOLoad = true
		orbload = true
	end
end

function BlockAA(bool)
	if not bool and orbload then
		if MMALoad then
			_G.MMA_StopAttacks(false)
		elseif SacLoad then
			_G.AutoCarry.MyHero:AttacksEnabled(true)
		elseif SxOLoad then
			SxO:EnableAttacks()
		end
	elseif bool and orbload then
		if MMALoad then
			_G.MMA_StopAttacks(true)
		elseif SacLoad then
			_G.AutoCarry.MyHero:AttacksEnabled(false)
		elseif SxOLoad then
			SxO:DisableAttacks()
		end
	end
end

function BlockMV(bool)
	if not bool and orbload then
		if MMALoad then
			_G.MMA_AvoidMovement(true)
		elseif SacLoad then
			_G.AutoCarry.MyHero:MovementEnabled(true)
		elseif SxOLoad then
			SxO:EnableMove()
		end
	elseif bool and orbload then
		if MMALoad then
			_G.MMA_AvoidMovement(false)
		elseif SacLoad then
			_G.AutoCarry.MyHero:MovementEnabled(false)
		elseif SxOLoad then
			SxO:DisableMove()
		end
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

local function GetCustomTarget()
	local T
	if MMALoad then T = _G.MMA_Target end
	if RebornLoad then T = _G.AutoCarry.Crosshair.Attack_Crosshair.target end
	if RevampedLoaded then T = _G.AutoCarry.Orbwalker.target end
	if SxOLoad then T = SxO:GetTarget() end
	if SOWLoaded then T = SOW:GetTarget() end
	if T and T.type == player.type then
		return T
	end
end

function OnLoad()
	ToUpdate = {}
	ToUpdate.Host = "raw.githubusercontent.com"
	ToUpdate.VersionPath = "/kej1191/anonym/master/KOM/MidKing/MidKing.version"
	ToUpdate.ScriptPath =  "/kej1191/anonym/master/KOM/MidKing/MidKing.lua"
	ToUpdate.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
	ToUpdate.CallbackUpdate = function(NewVersion, OldVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">Updated to "..NewVersion..". </b></font>") end
	ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">You have lastest version ("..OldVersion..")</b></font>") end
	ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
	ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">Error while Downloading. Please try again.</b></font>") end
	ScriptUpdate(VERSION, true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)

	OnOrbLoad()
	Aw = Awareness()
	if myHero.charName == "Xerath" then
		champ = Xerath()
	elseif myHero.charName == "Karthus" then
		champ = Karthus()
	elseif myHero.charName == "MissFortune" then
		champ = MissFortune()
	elseif myHero.charName == "Varus" then
		champ = Varus()
	end
end

function FindSummonerSlot(name)
    for slot = SUMMONER_1,SUMMONER_2 do
        if myHero:GetSpellData(slot).name:lower():find(name:lower()) then
            return slot
        end
    end
    return nil
end

function GetBestCircularFarmPosition(range, radius, objects)
    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
        local hit = CountObjectsNearPos(object.pos or object, range, radius, objects)
        if hit > BestHit then
            BestHit = hit
            BestPos = Vector(object)
            if BestHit == #objects then
               break
            end
         end
    end
    return BestPos, BestHit
end

function GetBestLineFarmPosition(range, width, objects, from)
    local BestPos 
	local _from = from or myHero
    local BestHit = 0
    for i, object in ipairs(objects) do
        local EndPos = Vector(_from.pos) + range * (Vector(object) - Vector(_from.pos)):normalized()
        local hit = CountObjectsOnLineSegment(_from.pos, EndPos, width, objects)
        if hit > BestHit then
            BestHit = hit
            BestPos = Vector(object)
			BestObj = object
            if BestHit == #objects then
               break
            end
         end
    end
    return BestPos, BestHit, BestObj
end

function CountObjectsOnLineSegment(StartPos, EndPos, width, objects)
    local n = 0
    for i, object in ipairs(objects) do
        local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartPos, EndPos, object)
        if isOnSegment and GetDistanceSqr(pointSegment, object) < width * width then
            n = n + 1
        end
    end
    return n
end

function CountObjectsNearPos(pos, range, radius, objects)
    local n = 0
    for i, object in ipairs(objects) do
        if GetDistanceSqr(pos, object) <= radius * radius then
            n = n + 1
        end
    end
    return n
end

function GetClosestTargetToMouse()
	local result
	local mindist = math.huge

	for i, enemy in ipairs(GetEnemyHeroes()) do
		local dist = GetDistanceSqr(mousePos, enemy)
		if ValidTarget(enemy) and dist < 1000 * 1000 then
			if dist <= mindist then
				mindist = dist
				result = enemy
			end
		end
	end

	return result
end

function DrawCircles(x, y, z, radius, color)
    DrawCircle(x, y, z, radius, color)
end

function DrawCircles2(x, y, z, radius, color)

  local length = 75
  local radius = radius*.92
  local quality = math.max(8,self:round(180/math.deg((math.asin((length/(2*radius)))))))
  local quality = 2*math.pi/quality
  local points = {}
  
  for theta = 0, 2*math.pi+quality, quality do
  
    local c = WorldToScreen(D3DXVECTOR3(x+radius*math.cos(theta), y, z-radius*math.sin(theta)))
    points[#points + 1] = D3DXVECTOR2(c.x, c.y)
  end
  
  DrawLines2(points, 1, color or 4294967295)
end

function GetHPBarPos(enemy)
	enemy.barData = {PercentageOffset = {x = -0.05, y = 0}}--GetEnemyBarData()
	local barPos = GetUnitHPBarPos(enemy)
	local barPosOffset = GetUnitHPBarOffset(enemy)
	local barOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local barPosPercentageOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local BarPosOffsetX = 171
	local BarPosOffsetY = 46
	local CorrectionY = 39
	local StartHpPos = 31

	barPos.x = math.floor(barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + StartHpPos)
	barPos.y = math.floor(barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY)

	local StartPos = Vector(barPos.x , barPos.y, 0)
	local EndPos =  Vector(barPos.x + 108 , barPos.y , 0)
	return Vector(StartPos.x, StartPos.y, 0), Vector(EndPos.x, EndPos.y, 0)
end

function CountMinionInRange(range, object)
    object = object or myHero
    range = range and range * range or myHero.range * myHero.range
    local enemyInRange = 0
    for index, minion in pairs(minionTable.objects) do
        if ValidTarget(minion) and GetDistanceSqr(object, minion) <= range and minion ~= object then
            enemyInRange = enemyInRange + 1
        end
    end
    return enemyInRange
end

function LagFreeDrawCircle(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        DrawCircleNextLvl(x, y, z, radius, 1, color, 100) 
    end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
	quality = 2 * math.pi / quality
	radius = radius*.92
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end

function round(num) 
	if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

function _G.Vector.angleBetween(self, v1, v2)

  assert(VectorType(v1) and VectorType(v2), " wrong argument types (2 <Vector> expected)")
  
  local p1, p2 = (-self+v1), (-self+v2)
  local theta = p1:polar()-p2:polar()
  
  if theta < 0 then
    theta = theta+360
  elseif theta >= 360 then
    theta = theta-360
  end
  
  return theta
end

class('Xerath')
function Xerath:__init()
	self.Q	= { Range = 0, MinRange = 750, MaxRange = 1500, Offset = 0, Width = 100, Delay = 0.55, Speed = math.huge, LastCastTime = 0, LastCastTime2 = 0, IsReady = function() return myHero:CanUseSpell(_Q) == READY end, Damage = function(target) return getDmg("Q", target, myHero) end, IsCharging = false, TimeToStopIncrease = 1.5 , End = 3, SentTime = 0, LastFarmCheck = 0, Sent = false}
	self.W	= { Range = 1100, Width = 125, Delay = 0.675, Speed = math.huge,  IsReady = function() return myHero:CanUseSpell(_W) == READY end}
	self.E	= { Range = 1050, Width = 60, Delay = 0.25, Speed = 1400, IsReady = function() return myHero:CanUseSpell(_E) == READY end}
	self.R	= { Range = function() return 2000 + 1200 * myHero:GetSpellData(_R).level end, Width = 120, Delay = 0.9, Speed = math.huge, LastCastTime = 0, LastCastTime2 = 0, Collision = false, IsReady = function() return myHero:CanUseSpell(_R) == READY end, Mana = function() return myHero:GetSpellData(_R).mana end, Damage = function(target) return getDmg("R", target, myHero) end, IsCasting = false, Stacks = 3, ResetTime = 10, MaxStacks = 3, Target = nil, ForceTarget = nil, SentTime = 0, Sent = false}
	
	self.Xerath_Q = HPSkillshot({type = "DelayLine", collisionM = false, collisionH = false, delay = self.Q.Delay, speed = self.Q.Speed, range = self.Q.MaxRange, width = self.Q.Width*2})
	self.Xerath_W = HPSkillshot({type = "DelayCircle", delay = self.W.Delay, speed = self.W.Speed, range = self.W.Range, radius = self.W.Width*2})
	self.Xerath_WS = HPSkillshot({type = "DelayCircle", delay = self.W.Delay, speed = self.W.Speed, range = self.W.Range, radius = 100})
	self.Xerath_E = HPSkillshot({type = "DelayLine", collisionM = true, collisionH = true, speed = self.E.Speed, range = self.E.Range, delay = self.E.Delay, width = self.E.Width*2})
	self.Xerath_R = HPSkillshot({type = "DelayCircle", delay = self.R.Delay, range = 3200, speed = self.R.Speed, radius = self.R.Width*2})
	
	self.minionTable =  minionManager(MINION_ENEMY, self.Q.MaxRange, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, self.Q.MaxRange, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	self.QTS = TargetSelector(TARGET_LESS_CAST, self.Q.MaxRange, DAMAGE_MAGIC, false)
	self.WTS = TargetSelector(TARGET_LESS_CAST, self.W.Range, DAMAGE_MAGIC, false)
	self.ETS = TargetSelector(TARGET_LESS_CAST, self.E.Range, DAMAGE_MAGIC, false)
	self.RTS = TargetSelector(TARGET_LESS_CAST, 3200, DAMAGE_MAGIC, false)

	self.DivineQ = LineSS(self.Q.Speed, self.Q.MaxRange, self.Q.Width, self.Q.Delay * 1000, 0)
	local DivineQ = dp:bindSS("DivineQ", self.DivineQ, 1)
	
	self.DivineW = CircleSS(self.W.Speed, self.W.Range, self.W.Width, self.W.Delay * 1000, 0)
	local DivineW = dp:bindSS("DivineW", self.DivineW, 1)
	
	self.DivineWS = CircleSS(self.W.Speed, self.W.Range, 50, self.W.Delay * 1000, 0)
	local DivineWS = dp:bindSS("DivineWS", self.DivineWS, 1)
	
	self.DivineE = LineSS(self.E.Speed, self.E.Range, self.E.Width, self.E.Delay * 1000,  math.huge)
	local DivineE = dp:bindSS("DivineE", self.DivineE, 1)
	
	self.DivineR = CircleSS(self.R.Speed, 5600, self.R.Width, self.R.Delay * 1000, 0)
	local DivineR = dp:bindSS("DivineR", self.DivineR, 1)
	
	self.ECol = Collision(self.E.Range, self.E.Speed, self.E.Delay, self.E.Width)
	
	self.PassiveUp = false
	self.Qrange = 0
	self.ScriptName = "Jerath"
	self:LoadMenu()
end

function Xerath:LoadMenu()
	self.Config = scriptConfig(self.ScriptName, "Xerath")
	
		if SxOLoad then
			self.Config:addSubMenu("Orbwalking", "Orbwalking")
				SxO:LoadToMenu(self.Config.Orbwalking, Orbwalking)
		end
		
		self.Config:addSubMenu("Target selector", "STS")
			STS:AddToMenu(self.Config.STS)
		
		self.Config:addSubMenu(myHero.charName.." Combo", "Combo")
			self.Config.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
			self.Config.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("Erange",  "E range", SCRIPT_PARAM_SLICE, 1050, 0, 1050)
			self.Config.Combo:addParam("CastE", "Use E!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("O"))
			self.Config.Combo:addParam("Enabled", "Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			
		self.Config:addSubMenu(myHero.charName.." Harass", "Harass")
			self.Config.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
			self.Config.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
			self.Config.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
			
		self.Config:addSubMenu(myHero.charName.." RSnipe", "RSnipe")
			self.Config.RSnipe:addParam("UseKillable", "Only Cast Killable", SCRIPT_PARAM_ONOFF, true)
			self.Config.RSnipe:addParam("DrawRange", "Draw R targetting range", SCRIPT_PARAM_ONOFF, true)
			self.Config.RSnipe:addParam("Targetting", "Targetting mode: ", SCRIPT_PARAM_LIST, 1, { "Near mouse (1000) range from mouse"})
			self.Config.RSnipe:addParam("AutoR2", "Use 1 charge (tap)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
			self.Config.RSnipe:addParam("ForceTarget", "Force Targetting", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
			
			self.Config.RSnipe:addSubMenu("Alerter", "Alerter")
				self.Config.RSnipe.Alerter:addParam("Alert", "Draw \"Snipe\" on killable enemies", SCRIPT_PARAM_ONOFF , true)
				--self.Config.RSnipe.Alerter:addParam("Ping", "Ping if an enemy is killable", SCRIPT_PARAM_ONOFF , true)
				
			
		self.Config:addSubMenu(myHero.charName.." Farm", "Farm")
			self.Config.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_ONOFF, false)
			self.Config.Farm:addParam("ManaCheck", "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
			self.Config.Farm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
		
		--[[Jungle farming]]
		self.Config:addSubMenu(myHero.charName.." JungleFarm", "JungleFarm")
			self.Config.JungleFarm:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.JungleFarm:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			self.Config.JungleFarm:addParam("Enabled", "Farm jungle!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
			
		self.Config:addSubMenu(myHero.charName.." Draw", "Draw")
			self.Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawQColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawWColor", "Draw W Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawEColor", "Draw E Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawRColor", "Draw R Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawTarget", "Draw R Target", SCRIPT_PARAM_ONOFF, false)
			self.Config.Draw:addParam("DrawForceTarget"," Draw R ForceTarget", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("Line", "Draw Line", SCRIPT_PARAM_ONOFF, true)
			
			
		self.Config:addSubMenu(myHero.charName.." Misc", "Misc")
			self.Config.Misc:addParam("WCenter", "Cast W centered", SCRIPT_PARAM_ONOFF, false)
			--self.Config.Misc:addParam("WMR", "Cast W at max range", SCRIPT_PARAM_ONOFF, false)
			self.Config.Misc:addParam("AutoEDashing", "Auto E on dashing enemies", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu(myHero.charName.." Pred", "Pred")
			self.Config.Pred:addParam("QPred", "Q Prediction", SCRIPT_PARAM_LIST,1, SupPred)
			self.Config.Pred:addParam("WPred", "W Prediction", SCRIPT_PARAM_LIST,1, SupPred)
			self.Config.Pred:addParam("EPred", "E Prediction", SCRIPT_PARAM_LIST,1, SupPred)
			self.Config.Pred:addParam("RPred", "R Prediction", SCRIPT_PARAM_LIST,1, SupPred)
			
	AddTickCallback(function() self:Tick() end)
	AddDrawCallback(function() self:Draw() end)
	--AddAnimationCallback(function(unit, animation) self:Animation(unit, animation) end)
	AddProcessSpellCallback(function(unit, spell) self:ProcessSpell(unit, spell) end)
	AddApplyBuffCallback(function(source, unit, buff) self:OnApplyBuff(source, unit, buff) end)
	--AddUpdateBuffCallback(function(unit, buff, stacks) self:UpdateBuff(unit, buff, stacks) end)
	AddRemoveBuffCallback(function(unit, buff) self:OnRemoveBuff(unit, buff) end)	
end

function Xerath:Tick()
	self:GetTargets()
	if self.Config.Combo.Enabled then
		self:Combo()
	elseif self.Config.Harass.Enabled and ((myHero.mana / myHero.maxMana * 100) >= self.Config.Harass.ManaCheck ) then
		self:Harass()
	end
	
	if self.Config.Farm.Enabled and ((myHero.mana / myHero.maxMana * 100) >= self.Config.Farm.ManaCheck or self.Q.IsCharging) then
		self:Farm()
	end

	if self.Config.JungleFarm.Enabled then
		self:JungleFarm()
	end
	if self.Config.RSnipe.AutoR2 and self.R.IsReady() then
		self:CastR()
	end
	if self.R.IsCasting and myHero:GetSpellData(_R).currentCd > 2 then
		self.R.IsCasting = false;
	end
	
	if self.Config.RSnipe.ForceTarget then
		if self.R.ForceTarget then
			if GetDistanceFromMouse(self.R.ForceTarget) > 500 and self.R.ForceTarget ~= self.R.Target then
				self.R.ForceTarget = self.R.Target;
			end
		else
			if self.R.Target then
				self.R.ForceTarget = self.R.Target;
			end
		end
	end
	
	if self.Config.Misc.AutoEDashing then
		for i, target in ipairs(SelectUnits(GetEnemyHeroes(), function(t) return ValidTarget(t, self.E.Range * 1.5) end)) do
			self:CastIfDashing(target)
		end
	end
	
	if self.R.IsCasting and orbload then
		BlockAA(true)
		BlockMV(true)
	elseif not self.R.IsCasting and orbload then
		BlockAA(false)
		BlockMV(false)
	end
	
	if self.R.IsCasting and myHero:GetSpellData(_R).currentCd > 2 then
		self.R.IsCasting = false;
	end
	if self.R.ForceTarget ~= nil and self.R.ForceTarget.dead then
		self.R.ForceTarget = nil
	end
	
	if myHero:GetSpellData(_R).level == 1 then
		self.Xerath_R = HPSkillshot({type = "DelayCircle", delay = self.R.Delay, range = 3200, speed = self.R.Speed, radius = self.R.Width*2})
		dp:getSS("DivineR").range = 3200
	elseif myHero:GetSpellData(_R).level == 2 then
		self.Xerath_R = HPSkillshot({type = "DelayCircle", delay = self.R.Delay, range = 4400, speed = self.R.Speed, radius = self.R.Width*2})
		dp:getSS("DivineR").range = 4400
	elseif myHero:GetSpellData(_R).level == 3 then
		self.Xerath_R = HPSkillshot({type = "DelayCircle", delay = self.R.Delay, range = 5600, speed = self.R.Speed, radius = self.R.Width*2})
		dp:getSS("DivineR").range = 5600
	end
	
	if myHero:GetSpellData(_R).level == 1 then
		self.RTS = TargetSelector(TARGET_LESS_CAST, 3200, DAMAGE_MAGIC, false)
	elseif myHero:GetSpellData(_R).level == 2 then
		self.RTS = TargetSelector(TARGET_LESS_CAST, 4400, DAMAGE_MAGIC, false)
	elseif myHero:GetSpellData(_R).level == 3 then
		self.RTS = TargetSelector(TARGET_LESS_CAST, 5600, DAMAGE_MAGIC, false)
	end
end

function Xerath:GetTargets()
	self.Target = GetTarget()
	
	if self.Target and self.Target.team ~= myHero.team and self.Target.type == myHero.type and ValidTarget(self.Target, self.Q.MaxRange) then
		self.QTarget = self.Target
	else
		self.QTS:update()
		self.QTarget = self.QTS.target
	end
	
	self.WTS:update()
	self.WTarget = self.WTS.target
	
	self.ETS:update()
	self.ETarget = self.ETS.target
	
	if self.Target and self.Target.team ~= myHero.team and self.Target.type == myHero.type and ValidTarget(self.Target, self.R.Range()) then
		self.RTarget = self.Target
	else
		self.RTS:update()
		self.RTarget = self.RTS.target
	end
end

function Xerath:Combo()
	self:GetTargets()

	self.AAtarget = OrbTarget(1000)
	if orbload then BlockAA(true) end

	if (self.AAtarget and self.AAtarget.health < 200) or self.PassiveUp and orbload then
		BlockAA(false)
	end

	if self.QTarget and self.Config.Combo.UseQ and ValidTarget(self.QTarget, self.Q.MaxRange) then
		self:CastQ(self.QTarget)
	end
	
	if self.WTarget and self.Config.Combo.UseW then
		self:CastW(self.WTarget)
	end

	if self.ETarget and self.Config.Combo.UseE then
		self:CastE(self.ETarget)
	end
end

function Xerath:Harass()
	if self.QTarget and self.Config.Harass.UseQ and ValidTarget(self.QTarget, self.Q.MaxRange) then
		self:CastQ(self.QTarget)
	end
end

function Xerath:Farm()
	self.minionTable:update()
	if self.Config.Farm.UseQ then
		local BestPos, BestHit, BestObj = GetBestLineFarmPosition(self.Q.MaxRange, self.Q.Width, self.minionTable.objects)
		if BestPos ~= nil and BestHit ~= nil and BestObj ~= nil then
			self:FarmQ(BestPos)
		end
	end

	if self.Config.Farm.UseW then
		local BestPos, BestHit = GetBestCircularFarmPosition(self.W.Range, self.W.Width, self.minionTable.objects)
		if BestHit ~= nil and BestPos ~= nil then
			CastSpell(_W, BestPos.x, BestPos.z)
		end
	end
end

function Xerath:JungleFarm()
	self.jungleTable:update()
	if self.jungleTable.objects[1] ~= nil then
		if self.Config.JungleFarm.UseQ and GetDistance(self.jungleTable.objects[1]) <= self.Q.MaxRange and self.Q.IsReady() then
			self:CastQ(self.jungleTable.objects[1])
		end

		if self.Config.JungleFarm.UseW and self.W.IsReady() then
			CastSpell(_W, self.jungleTable.objects[1].x, self.jungleTable.objects[1].z)
		end
	end
end

function Xerath:FarmQ(target)
	if self.Q.IsReady() then
		local delay = math.max(GetDistance(myHero, target) - self.Q.MinRange, 0) / ((self.Q.MaxRange - self.Q.MinRange) / self.Q.TimeToStopIncrease) + self.Q.Delay
        if not self.Q.IsCharging then
			if GetDistance(target) < self.Q.MaxRange then
                CastSpell(_Q, mousePos.x, mousePos.z)
            end
        elseif self.Q.IsCharging and self.Q.LastCastTime + delay < os.clock() then
            if GetDistance(target) < self.Q.MaxRange then
                self:CastQ2(target)
            end
        end
    end
end

function Xerath:CastQ(target)
	if self.Q.IsReady() and ValidTarget(target) then
        if self.Q.IsCharging then
            self:CastQ1(target)
        else
            CastSpell(_Q, target.x, target.z)
        end
    end
end

function Xerath:CastQ1(target)
	if target ~= nil then
		self.Qrange = math.min(self.Q.MinRange + (self.Q.MaxRange - self.Q.MinRange) * ((os.clock() - self.Q.LastCastTime) / self.Q.TimeToStopIncrease), self.Q.MaxRange)
		if self.Config.Pred.QPred == 1 then
			self.QPos, self.QHitChance = HP:GetPredict(self.Xerath_Q, target, myHero)
			if self.Qrange ~= self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange - 200)^2 or self.Qrange == self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange)^2 then
				if self.QPos and self.QHitChance >= 1.4 then
					self:CastQ2(self.QPos)
				end
			end
		elseif self.Config.Pred.QPred == 2 then
			self.QPos, self.QHitChance = VP:GetLineAOECastPosition(target, self.Q.Delay, self.Q.Width, self.Q.MaxRange, self.Q.Speed, myHero)
			if self.Qrange ~= self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange - 200)^2 or self.Qrange == self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange)^2 then
				if self.QPos and self.QHitChance >= 1.4 then
					self:CastQ2(self.QPos)
				end
			end
		elseif self.Config.Pred.QPred == 3 then
			self.QPos, self.QHitChance, self.PredPos = SP:Predict(target, self.Q.MaxRange, self.Q.Speed, self.Q.Delay, self.Q.Width*2, false, myHero)
			if self.Qrange ~= self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange - 200)^2 or self.Qrange == self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange)^2 then
				if self.QPos and self.QHitChance >= 1.4 then
					self:CastQ2(self.QPos)
				end
			end
		elseif self.Config.Pred.QPred == 4 then
			local Target = DPTarget(target)
			self.QState, self.QPos, self.QPerc = dp:predict("DivineQ", Target)
			if self.QPos and self.QState and self.QState == SkillShot.STATUS.SUCCESS_HIT then
				if self.Qrange ~= self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange - 200)^2 or self.Qrange == self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange)^2 then
					self:CastQ2(self.QPos)
				end
			end
		end
	end
end

function Xerath:CastQ2(Pos)
	if self.Q.IsReady() and Pos and self.Q.IsCharging then
        local d3vector = D3DXVECTOR3(Pos.x, Pos.y, Pos.z)
        self.Q.Sent = true
        CastSpell2(_Q, d3vector)
        self.Q.Sent = false
    end
end

function Xerath:CastW(target)
	if target ~= nil then
		if self.Config.Pred.WPred == 1 then
			if self.Config.Misc.WCenter then
				self.WPos, self.WHitChance = HP:GetPredict(self.Xerath_WS, target, myHero)
				if self.WPos ~= nil and self.WHitChance ~= nil then
					if self.WHitChance >= 1.4 then
						CastSpell(_W, self.WPos.x, self.WPos.z)
					end
				end
			else
				self.WPos, self.WHitChance = HP:GetPredict(self.Xerath_W, target, myHero)
				if self.WPos ~= nil and self.WHitChance ~= nil then
					if self.WHitChance >= 1.4 then
						CastSpell(_W, self.WPos.x, self.WPos.z)
					end
				end
			end
		elseif self.Config.Pred.WPred == 2 then
			if self.Config.Misc.WCenter then
				self.WPos, self.WHitChance = VP:GetCircularAOECastPosition(target, self.W.Delay, 50, self.W.Range, self.W.Speed, myHero)
				if self.WPos ~= nil and self.WHitChance ~= nil then
					if self.WHitChance >= 1.4 then
						CastSpell(_W, self.WPos.x, self.WPos.z)
					end
				end
			else
				self.WPos, self.WHitChance = VP:GetCircularAOECastPosition(target, self.W.Delay, self.W.Width, self.W.Range, self.W.Speed, myHero)
				if self.WPos ~= nil and self.WHitChance ~= nil then
					if self.WHitChance >= 1.4 then
						CastSpell(_W, self.WPos.x, self.WPos.z)
					end
				end
			end
		elseif self.Config.Pred.WPred == 3 then
			self.WPos, self.WHitChance = SP:PredictPos(target, self.W.Speed, self.W.Delay)
			if self.WPos and self.WHitChance >= 1.4 then
				CastSpell(_W, self.WPos.x, self.WPos.z)
			end
		elseif self.Config.Pred.WPred == 4 then
			local Target = DPTarget(target)
			if self.Config.Misc.WCenter then
				self.WState, self.WPos, self.WPerc = dp:predict("DivineW", Target)
				if self.WPos and self.WState == SkillShot.STATUS.SUCCESS_HIT then
					CastSpell(_W, self.WPos.x, self.WPos.z)
				end
			else
				self.WState, self.WPos, self.WPerc = dp:predict("DivineWS", Target)
				if self.WPos and self.WState == SkillShot.STATUS.SUCCESS_HIT then
					CastSpell(_W, self.WPos.x, self.WPos.z)
				end
			end
		end
	end
end

function Xerath:CastE(target)
	if target ~= nil then
		if self.Config.Pred.EPred == 1 then
			self.EPos, self.EHitChance = HP:GetPredict(self.Xerath_E, target, myHero)
			if self.EPos ~= nil and self.EHitChance ~= nil then
				if self.EHitChance >= 0.8 then
					CastSpell(_E, self.EPos.x, self.EPos.z)
				end
			end
		elseif self.Config.Pred.EPred == 2 then
			self.EPos, self.EHitChance = VP:GetLineCastPosition(target, self.E.Delay, self.E.Width, self.E.Range, self.E.Speed, myHero, true)
			if self.EPos ~= nil and self.EHitChance ~= nil then
				if self.EHitChance >= 0.8 then
					CastSpell(_E, self.EPos.x, self.EPos.z)
				end
			end
		elseif self.Config.Pred.EPred == 3 then
			self.EPos, self.EHitChance, self.PredPos = SP:Predict(target, self.E.Range, self.E.Speed, self.E.Delay, self.E.Width*2, true, myHero)
			if self.EPos ~= nil and self.EHitChance ~= nil then
				if self.EHitChance >= 0.8 then
					CastSpell(_E, self.EPos.x, self.EPos.z)
				end
			end
		elseif self.Config.Pred.EPred == 4 then
			local Target = DPTarget(target)
			self.EState, self.EPos, self.EPerc = dp:predict("DivineE", Target)
			if self.EPos and self.EState == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_E, self.EPos.x, self.EPos.z)
			end
		end
	end
end

function Xerath:CastIfDashing(target)
    local isDashing, canHit, position = VP:IsDashing(target, self.E.Delay + 0.07 + GetLatency() / 2000, self.E.Width, self.E.Speed, player)
    if isDashing and canHit and position ~= nil and self.E.IsReady() then
        if not VP:CheckMinionCollision(target, position, self.E.Delay + 0.07 + GetLatency() / 2000, self.E.Width, self.E.Range, self.E.Speed, player, false, true) then
            return CastSpell(_E, position.x, position.z)
        end
	end
end

function Xerath:CastR()
    if self.R.IsReady() then
        if not self.R.IsCasting then 
            self:CastR1()
        else
			if self.Config.RSnipe.Targetting == 1 then
				self.R.Target = GetClosestTargetToMouse()
			end
            if self.R.Target and ValidTarget(self.R.Target, self.R.Range()) then
				self:CastR2(self.R.Target)
			end
        end
    end
end

function Xerath:CastR1()
    if not self.R.IsCasting and self.R.IsReady() then 
		CastSpell(_R)
	end
end

function Xerath:CastR2(_T)
    if self.R.IsCasting and self.R.IsReady() then
        local target = _T or GetClosestTargetToMouse()
        if ValidTarget(target) and not target.isMe then
			self:CastR3(target)
        end
    end
end

function Xerath:CastR3(target)
	if target ~= nil then
		if self.Config.Pred.RPred == 1 then
			self.RPos, self.RHitChance = HP:GetPredict(self.Xerath_R, target, myHero)
			if self.RPos ~= nil and self.RHitChance ~= nil then
				if self.RHitChance >= 1.2 then
					CastSpell(_R, self.RPos.x, self.RPos.z)
				end
			end
		elseif self.Config.Pred.RPred == 2 then
			self.RPos, self.RHitChance = VP:GetCircularAOECastPosition(target, self.R.Delay, self.R.Width, self.R.Range, self.R.Speed, myHero)
			if self.RPos and self.RHitChance >= 1.4 then
				CastSpell(_R, self.RPos.x, self.RPos.z)
			end
		elseif self.Config.Pred.RPred == 3 then
			self.RPos, self.RHitChance = SP:PredictPos(target, self.R.Speed, self.R.Delay)
			if self.RPos and self.RHitChance >= 1.4 then
				CastSpell(_R, self.RPos.x, self.RPos.z)
			end
		elseif self.Config.Pred.RPred == 4 then
			local Target = DPTarget(target)
			self.RState, self.RPos, self.RPerc = dp:predict("DivineR", Target)
			if self.RPos and self.RState == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_R, self.RPos.x, self.RPos.z)
			end
		end
	end
end

function Xerath:Draw()
	if myHero.dead then return end
	if self.Q.IsReady() and self.Config.Draw.DrawQ then
		DrawCircles(player.x, player.y, player.z, self.Q.MaxRange, TARGB(self.Config.Draw.DrawQColor))
	end

	if self.W.IsReady() and self.Config.Draw.DrawW then
		DrawCircles(player.x, player.y, player.z, self.W.Range, TARGB(self.Config.Draw.DrawWColor))
	end

	if self.E.IsReady() and self.Config.Draw.DrawE then
		DrawCircles(player.x, player.y, player.z, self.Config.Combo.Erange, TARGB(self.Config.Draw.DrawEColor))
	end

	if self.R.IsReady() and self.Config.Draw.DrawR then
		DrawCircles(player.x, player.y, player.z, self.R.Range(), TARGB(self.Config.Draw.DrawRColor))
	end
	
	if self.Config.RSnipe.Alerter.Alert and myHero:GetSpellData(_R).level > 0 then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, self.R.Range()) and (enemy.health < self.R.Damage(enemy) * self.R.Stacks) then
				local pos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
				DrawText("Snipe!", 17, pos.x, pos.y, Colors.Red)
			end
		end
	end
	
	if self.Config.RSnipe.DrawRange and self.R.IsCasting then
		DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, 500, 1, ARGB(255, 0, 0, 255), 30)
	end
	if self.R.IsCasting and self.R.Target then
		DrawCircles(self.R.Target.x, self.R.Target.y, self.R.Target.z, 100, Colors.Blue)
	end
	
	if self.QHitChance ~= nil then
		if self.QHitChance < 1 then
			self.Qcolor = ARGB(0xFF, 0xFF, 0x00, 0x00)
		elseif self.QHitChance == 3 then
			self.Qcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
		elseif self.QHitChance >= 2 then
			self.Qcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.QHitChance >= 1 then
			self.Qcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		end
	end
  
	if self.WHitChance ~= nil then
		if self.WHitChance < 1 then
			self.Wcolor = ARGB(0xFF, 0xFF, 0x00, 0x00)
		elseif self.WHitChance == 3 then
			self.Wcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
		elseif self.WHitChance >= 2 then
			self.Wcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.WHitChance >= 1 then
			self.Wcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		end
	end
  
	if self.EHitChance ~= nil then
		if self.EHitChance == -1 then
			self.Ecolor = ARGB(0xFF, 0x00, 0x00, 0x00)
		elseif self.EHitChance < 1 then
			self.Ecolor = ARGB(0xFF, 0xFF, 0x00, 0x00)
		elseif self.EHitChance == 3 then
			self.Ecolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
		elseif self.EHitChance >= 2 then
			self.Ecolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.EHitChance >= 1 then
			self.Ecolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		end
	end
	
  
	if self.RHitChance ~= nil then
		if self.RHitChance < 1 then
			self.Rcolor = ARGB(0xFF, 0xFF, 0x00, 0x00)
		elseif self.RHitChance == 3 then
			self.Rcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
		elseif self.RHitChance >= 2 then
			self.Rcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.RHitChance >= 1 then
			self.Rcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		end
	end
	
	
	if self.QPos and self.Qcolor and self.Q.IsReady() then
		DrawCircles(self.QPos.x, self.QPos.y, self.QPos.z, self.Q.Width/2, self.Qcolor)
		if self.Config.Draw.Line then
			DrawLine3D(myHero.x, myHero.y, myHero.z, self.QPos.x, self.QPos.y, self.QPos.z, 2, self.Qcolor)
		end
    
		self.QPos = nil
	end
  
	if self.WPos and self.Wcolor and self.W.IsReady() then
		DrawCircles(self.WPos.x, self.WPos.y, self.WPos.z, self.W.Width, self.Wcolor)
		self.WPos = nil
	end
  
	if self.EPos and self.Ecolor and self.E.IsReady() then
		DrawCircles(self.EPos.x, self.EPos.y, self.EPos.z, self.E.Width/2, self.Ecolor)
    
		if self.Config.Draw.Line then
			DrawLine3D(myHero.x, myHero.y, myHero.z, self.EPos.x, self.EPos.y, self.EPos.z, 2, self.Ecolor)
		end
		
		self.EPos = nil
	end
  
	if self.RPos and self.Rcolor and self.R.IsReady() then
		DrawCircles(self.RPos.x, self.RPos.y, self.RPos.z, self.R.Width, self.Rcolor)
		self.RPos = nil
	end
end

function Xerath:ProcessSpell(unit, spell)
	if myHero.dead or self.Config == nil or unit == nil or not unit.isMe then return end
	if spell.name:lower():find("xeratharcanopulsechargeup") then 
		self.Q.LastCastTime = os.clock()
		self.Q.IsCharging = true
	elseif spell.name:lower():find("xeratharcanopulse2") then 
		self.Q.LastCastTime2 = os.clock()
		self.Q.IsCharging = false
	elseif spell.name:lower():find("xerathlocusofpower2") then 
		self.R.LastCastTime = os.clock()
		self.R.IsCasting = true
		self.R.LastCastTime2 = os.clock()
		DelayAction(function() self.R.Stacks = self.R.MaxStacks self.R.Target = nil self.R.IsCasting = false end, self.R.ResetTime)
	elseif spell.name:lower():find("xerathrmissilewrapper") then 
	
	elseif spell.name:lower():find("xerathlocuspulse") then
		self.R.LastCastTime2 = os.clock()
		self.R.Stacks = self.R.Stacks - 1
	end
end

function Xerath:OnApplyBuff(source, unit, buff)
	if unit.isMe and buff.name == "xerathascended2onhit" then
		self.PassiveUp = true
	end
	if unit.isMe and buff.name == "XerathLocusOfPower2" then
		self.R.IsCasting = true
	end
end

function Xerath:OnRemoveBuff(unit, buff)
	if unit.isMe and buff.name == "xerathascended2onhit" then
		self.PassiveUp = false
	end
	if unit.isMe and buff.name == "XerathLocusOfPower2" then
		self.R.IsCasting = false
	end
end

--- Karthus


class('Karthus')
function Karthus:__init()
	self.Q = {Range = 875, Speed = math.huge, Width = 200, Delay = 1.1,  IsReady = function() return myHero:CanUseSpell(_Q) == READY end,}
	self.W = {Range = 1000, Speed = math.huge, Width = 200, Delay = 0.5, IsReady = function() return myHero:CanUseSpell(_W) == READY end,}
	self.E = {Range = 550, Active = false, IsReady = function() return myHero:CanUseSpell(_E) == READY end}
	self.R = {IsReady = function() return myHero:CanUseSpell(_R) == READY end}
	
	self.HP_Q = HPSkillshot({type = "PromptCircle", range = self.Q.Range, width = self.Q.Width, delay = self.Q.Delay, IsLowAccuracy = true})
	self.HP_W = HPSkillshot({type = "PromptLine", range = self.W.Range, width = self.W.Width, delay = self.W.Delay})
	
	self.minionTable =  minionManager(MINION_ENEMY, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	self.DivineQ = CircleSS(math.huge,875,200,600,math.huge)
	local DivineQ = dp:bindSS("DivineQ", self.DivineQ, 1)
	
	self.DivineW = CircleSS(math.huge,1000,10,160,math.huge)
	local DivineW = dp:bindSS("DivineW", self.DivineW, 1)
	
	self.recall = false
	self.dead = false
	
	self.enemyHeroes = {}
	
	self.QTS = TargetSelector(TARGET_LESS_CAST, self.Q.Range, DAMAGE_MAGIC, false)
	self.WTS = TargetSelector(TARGET_LESS_CAST, self.W.Range, DAMAGE_MAGIC, false)
	
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team ~= myHero.team then
			info = {unit = hero, statu = "Can't", color = Colors.Yellow,}
			table.insert(self.enemyHeroes, info)
		end
	end
	
	self:LoadMenu()
end

function Karthus:LoadMenu()
	self.Config = scriptConfig("DDK Kathus", "Kathus")
	
		if SxOLoad then
			self.Config:addSubMenu("Orbwalker", "Orbwalker")
				SxO:LoadToMenu(self.Config.Orbwalker)
		end
		self.Config:addSubMenu("TargetSelector", "TargetSelector")
			STS:AddToMenu(self.Config.TargetSelector)
		
		self.Config:addSubMenu(myHero.charName.." Combo", "Combo")
			self.Config.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("Enabled", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			
		self.Config:addSubMenu(myHero.charName.." Harass", "Harass")
			self.Config.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("Qmana","Q mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			self.Config.Harass:addParam("Qinfo", "", SCRIPT_PARAM_INFO, "")
			self.Config.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("Wmana","W mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			self.Config.Harass:addParam("Winfo", "", SCRIPT_PARAM_INFO, "")
			self.Config.Harass:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("Emana","E mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			self.Config.Harass:addParam("Einfo", "", SCRIPT_PARAM_INFO, "")
			self.Config.Harass:addParam("Enabled", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
			self.Config.Harass:addParam("EnabledToggle", "HarassToggle", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("G"))
			
		self.Config:addSubMenu(myHero.charName.." LineClear", "LineClear")
			self.Config.LineClear:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.LineClear:addParam("Qmana", "Until % Q", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			self.Config.LineClear:addParam("Qinfo", "", SCRIPT_PARAM_INFO, "")
			self.Config.LineClear:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.LineClear:addParam("Emana","E mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			self.Config.LineClear:addParam("Enabled", "Line Clear", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
			
		self.Config:addSubMenu(myHero.charName.." JungleClear", "JungleClear")
			self.Config.JungleClear:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.JungleClear:addParam("Qmana", "Until % Q", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			self.Config.JungleClear:addParam("Qinfo", "", SCRIPT_PARAM_INFO, "")
			self.Config.JungleClear:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.JungleClear:addParam("Emana","E mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			self.Config.JungleClear:addParam("Enabled", "Jungle Clear", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
			
		self.Config:addSubMenu(myHero.charName.." Farm", "Farm")
			self.Config.Farm:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Farm:addParam("Qmana", "Until % Q", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			self.Config.Farm:addParam("Enabled", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
			
		self.Config:addSubMenu(myHero.charName.." Draw", "Draw")
			self.Config.Draw:addParam("info0", "Draw Range", SCRIPT_PARAM_INFO, "")
			self.Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawQColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("info1", "", SCRIPT_PARAM_INFO, "")
			self.Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawWColor", "Draw W Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("info2", "", SCRIPT_PARAM_INFO, "")
			self.Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawEColor", "Draw E Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("info4", "Other", SCRIPT_PARAM_INFO, "")
			self.Config.Draw:addParam("DrawKillmark","Draw KillMark", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawDmgMark", "Draw Damage Mark", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("Line", "Draw Line", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu(myHero.charName.." KillMark", "KillMark")
			self.Config.KillMark:addParam("XPos", "X Pos", SCRIPT_PARAM_SLICE, 100, 0, WINDOW_W, 0)
			self.Config.KillMark:addParam("YPos", "Y Pos", SCRIPT_PARAM_SLICE, 100, 0, WINDOW_H, 0)
			
		self.Config:addSubMenu("[Q] Setting", "Q")
		
		self.Config:addSubMenu("[W] Setting", "W")
			self.Config.W:addParam("UseInQRange", "Use W in Q range", SCRIPT_PARAM_ONOFF, false)
			
		self.Config:addSubMenu("[E] Setting", "E")
			self.Config.E:addParam("autoff", "Auto off", SCRIPT_PARAM_ONOFF, true)
			self.Config.E:addParam("UseEmanaSaveManager", "Use E mana Save manager", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu("[R] Setting", "R")
		
		self.Config:addSubMenu("Misc", "Misc")
			self.Config.Misc:addParam("PassiveManager", "Cast Spell when in passive time", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu(myHero.charName.." Pred", "Pred")
			self.Config.Pred:addParam("QPred", "Q Prediction", SCRIPT_PARAM_LIST,1, SupPred)
			self.Config.Pred:addParam("WPred", "W Prediction", SCRIPT_PARAM_LIST,1, SupPred)
			
	AddTickCallback(function() self:Tick() end)
	AddDrawCallback(function() self:Draw() end)
	--AddAnimationCallback(function(unit, animation) self:Animation(unit, animation) end)
	--AddProcessSpellCallback(function(unit, spell) self:ProcessSpell(unit, spell) end)
	AddApplyBuffCallback(function(source, unit, buff) self:OnApplyBuff(source, unit, buff) end)
	--AddUpdateBuffCallback(function(unit, buff, stacks) self:UpdateBuff(unit, buff, stacks) end)
	AddRemoveBuffCallback(function(unit, buff) self:OnRemoveBuff(unit, buff) end)
end

function Karthus:Tick()
	if self.dead then self:Passive() end
	if player.dead then return end
	if self.Config.Combo.Enabled then self:Combo() end
	if self.Config.Harass.Enabled then self:Harass() end
	if self.Config.Harass.EnabledToggle and not self.recall then self:Harass() end
	if self.Config.LineClear.Enabled  then self:LineClear() end
	if self.Config.JungleClear.Enabled then self:JungleClear() end 
	if self.Config.Farm.Enabled  then self:Farm() end
	
	self:GetTargets()
	
	for i, unit in ipairs(self.enemyHeroes) do
		if getDmg("R", unit.unit, myHero) > unit.unit.health and not unit.unit.dead then
			unit.statu = "Can"
			unit.color = Colors.Red
		elseif getDmg("R", unit.unit, myHero) < unit.unit.health and not unit.unit.dead then
			unit.statu = "Can't"
			unit.color = Colors.Red
		elseif unit.unit.dead then
			unit.statu = "Dead"
			unit.color = Colors.Red
		end
	end
end

function Karthus:GetTargets()
	self.Target = GetTarget()
	
	if self.Target and self.Target.team ~= myHero.team and self.Target.type == myHero.type then
		self.QTarget = self.Target
	else
		self.QTS:update()
		self.QTarget = self.QTS.target
	end
	
	if self.Target and self.Target.team ~= myHero.team and self.Target.type == myHero.type then
		self.WTarget = self.Target
	else
		self.WTS:update()
		self.WTarget = self.WTS.target
	end
end

function Karthus:Combo()
	if self.Q.IsReady() and self.Config.Combo.UseQ then
		self:CastQ(self.QTarget)
	end
	
	if self.W.IsReady() and self.Config.Combo.UseW then
		self:CastW(self.WTarget)
	end
	
	if self.E.IsReady() and self.Config.Combo.UseE then
		self:CastE()
	end
end

function Karthus:Harass()
	if self.Q.IsReady() and self.Config.Harass.UseQ and (myHero.mana / myHero.maxMana * 100) >= self.Config.Harass.Qmana then
		self:CastQ(self.QTarget)
	end
	
	if self.W.IsReady() and self.Config.Harass.UseW and (myHero.mana / myHero.maxMana * 100) >= self.Config.Harass.Wmana then
		self:CastW(self.WTarget)
	end
	
	if self.E.IsReady() and self.Config.Harass.UseE and (myHero.mana / myHero.maxMana * 100) >= self.Config.Harass.Emana then
		self:CastE()
	end
end

function Karthus:LineClear()
	self.minionTable:update()
	for i, minion in pairs(self.minionTable.objects) do
		if minion ~= nil and not minion.dead and GetDistance(minion) < 975 and self.Config.LineClear.UseQ and player.mana > (player.maxMana*(self.Config.LineClear.Qmana*0.01)) then
			local bestpos, besthit = GetBestCircularFarmPosition(875, 200, self.minionTable.objects)
			if bestpos ~= nil then
				CastSpell(_Q, bestpos.x, bestpos.z)
			end
		end
	end
end

function Karthus:JungleClear()
	self.jungleTable:update()
	for i, minion in pairs(self.jungleTable.objects) do
		if minion ~= nil and not minion.dead and GetDistance(minion) < 975 and self.Config.JungleClear.UseQ and player.mana > (player.maxMana*(self.Config.JungleClear.Qmana*0.01)) then
			local bestpos, besthit = GetBestCircularFarmPosition(875, 200, self.jungleTable.objects)
			if bestpos ~= nil then
				CastSpell(_Q, bestpos.x, bestpos.z)
			end
		end
	end
end

function Karthus:Farm()
	self.minionTable:update()
	for i, minion in ipairs(self.minionTable.objects) do
		if GetDistance(minion) <= 875 and self.Q.IsReady() and self.Config.Farm.UseQ then
			if player.mana > player.maxMana*(self.Config.Farm.Qmana*0.01) then
				local count = CountMinionInRange(self.Q.Width, minion)
				local PredHelth = HP:PredictHealth(minion, self.Q.Delay)
				if count == 0 then
					if getDmg("Q", minion, player) > PredHelth then
						CastSpell(_Q, bestpos.x, bestpos.z)
					end
				elseif count > 0 then
					if getDmg("Q", minion, player)*0.5 > PredHelth then
						CastSpell(_Q, bestpos.x, bestpos.z)
					end
				end
			end
		end
	end
end

function Karthus:Passive()
	if self.QTarget ~= nil and self.Config.Misc.PassiveManager then
		self:CastQ(self.QTarget)
	end
	if self.WTarget ~= nil and self.Config.Misc.PassiveManager then
		self:CastW(self.WTarget)
	end
end

function Karthus:CastQ(target)
	if target ~= nil then
		if self.Config.Pred.QPred == 1 then
			self.QPos, self.QHitChance = HP:GetPredict(HP.Presets["Karthus"]["Q"], target, myHero)
			if self.QPos and self.QHitChance >= 0.8 then
				CastSpell(_Q, self.QPos.x, self.QPos.z)
			end
		elseif self.Config.Pred.QPred == 2 then
			self.QPos, self.QHitChance = VP:GetCircularAOECastPosition(target, self.Q.Delay, self.Q.Width, self.Q.Range, self.Q.Speed, myHero)
			if self.QPos and self.QHitChance >= 1.4 then
				CastSpell(_Q, self.QPos.x, self.QPos.z)
			end
		elseif self.Config.Pred.QPred == 3 then
			self.QPos, self.QHitChance, self.PredPos = SP:PredictPos(target, math.huge, self.Q.Delay)
			if self.QPos and self.QHitChance >= 0.8 then
				CastSpell(_Q, self.QPos.x, self.QPos.z)
			end
		elseif self.Config.Pred.QPred == 4 then
			Target = DPTarget(target)
			self.QState, self.QPos, self.Qperc = dp:predict("DivineQ",Target)
			if self.QState == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_Q, self.QPos.x, self.QPos.z)
			end
		end
	end
end

function Karthus:CastW(target)
	if target ~= nil then
		if self.Config.Pred.WPred == 1 then
			self.WPos, self.WHitChance = HP:GetPredict(self.HP_W, target, myHero)
			if self.WPos ~= nil and self.WHitChance ~= nil then
				if self.WHitChance >= 1.4 then
					CastSpell(_W, self.WPos.x, self.WPos.z)
				end
			end
		elseif self.Config.Pred.WPred == 2 then
			self.WPos, self.WHitChance = VP:GetLineAOECastPosition(target, self.W.Delay, self.W.Width, self.W.Range, self.W.Speed, myHero)
			if self.WPos and self.WHitChance >= 1.4 then
				CastSpell(_W, self.WPos.x, self.WPos.z)
			end
		elseif self.Config.Pred.WPred == 3 then
			self.WPos, self.WHitChance = SP:PredictPos(target, self.W.Speed, self.W.Delay)
			if self.WPos and self.WHitChance >= 1.4 then
				CastSpell(_W, self.WPos.x, self.WPos.z)
			end
		elseif self.Config.Pred.WPred == 4 then
			Target = DPTarget(target)
			self.WState, self.WPos, self.Qperc = dp:predict("DivineW",Target)
			if self.WState == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_W, self.WPos.x, self.WPos.z)
			end
		end
	end
end

function Karthus:CastE()
	if CountEnemyHeroInRange(self.E.Range) >= 1 and not self.E.Active then
		CastSpell(_E)
	elseif CountEnemyHeroInRange(self.E.Range) == 0 and self.E.Active then
		CastSpell(_E)
	end
end

function Karthus:Draw()
	if myHero.dead then return end
	if self.Q.IsReady() and self.Config.Draw.DrawQ then
		DrawCircles(player.x, player.y, player.z, self.Q.Range, TARGB(self.Config.Draw.DrawQColor))
	end

	if self.W.IsReady() and self.Config.Draw.DrawW then
		DrawCircles(player.x, player.y, player.z, self.W.Range, TARGB(self.Config.Draw.DrawWColor))
	end

	if self.E.IsReady() and self.Config.Draw.DrawE then
		DrawCircles(player.x, player.y, player.z, self.E.Range, TARGB(self.Config.Draw.DrawEColor))
	end

	if self.QHitChance ~= nil then
		if self.QHitChance < 1 then
			self.Qcolor = ARGB(0xFF, 0xFF, 0x00, 0x00)
		elseif self.QHitChance == 3 then
			self.Qcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
		elseif self.QHitChance >= 2 then
			self.Qcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.QHitChance >= 1 then
			self.Qcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		end
	end
  
	if self.WHitChance ~= nil then
		if self.WHitChance < 1 then
			self.Wcolor = ARGB(0xFF, 0xFF, 0x00, 0x00)
		elseif self.WHitChance == 3 then
			self.Wcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
		elseif self.WHitChance >= 2 then
			self.Wcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.WHitChance >= 1 then
			self.Wcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		end
	end

	
	if self.QPos and self.Qcolor and self.Q.IsReady() then
		DrawCircles(self.QPos.x, self.QPos.y, self.QPos.z, self.Q.Width/2, self.Qcolor)
		if self.Config.Draw.Line then
			DrawLine3D(myHero.x, myHero.y, myHero.z, self.QPos.x, self.QPos.y, self.QPos.z, 2, self.Qcolor)
		end
    
		self.QPos = nil
	end
  
	if self.WPos and self.Wcolor and self.W.IsReady() then
		DrawCircles(self.WPos.x, self.WPos.y, self.WPos.z, self.W.Width, self.Wcolor)
		self.WPos = nil
	end
	
	if self.Config.Draw.DrawKillmark then
		for j, unit in pairs(self.enemyHeroes) do
			DrawText(unit.unit.charName.." can kill with R? | ", 18, self.Config.KillMark.XPos, self.Config.KillMark.YPos+(j*20), unit.color)
			DrawText(unit.statu, 18, self.Config.KillMark.XPos+200, self.Config.KillMark.YPos+(j*20), unit.color)
			DrawText("Missing? | "..tostring(ValidTarget(unit.unit)), 18, self.Config.KillMark.XPos+300, self.Config.KillMark.YPos+(j*20), unit.color)
		end
	end
	
	for i, j in ipairs(GetEnemyHeroes()) do
		if GetDistance(j) < 2000 and not j.dead and self.Config.Draw.DrawDmgMark and ValidTarget(j) then
			local pos = GetHPBarPos(j)
			local dmg, Qdamage = self:GetSpellDmg(j)
			if dmg == "CanComboKill" then
				DrawText("Can Combo Kill!",18 , pos.x, pos.y-48, 0xffff0000)
			else
				local pos2 = ((j.health - dmg)/j.maxHealth)*100
				DrawLine(pos.x+pos2, pos.y, pos.x+pos2, pos.y-30, 1, 0xffff0000)
				local hit = tostring(math.ceil(j.health/Qdamage))
				DrawText("Q hit : "..hit,18 , pos.x, pos.y-48, 0xffff0000)
			end
		end
	end
end

function Karthus:GetSpellDmg(enemy)
	local combodmg
	local Qdmg = getDmg("Q", enemy, player)
	local Edmg = getDmg("E", enemy, player)
	local Rdmg = getDmg("R", enemy, player)
	if enemy.health < Qdmg+Edmg+Rdmg then
		combodmg = "CanComboKill"
		return combodmg
	else
		combodmg = Qdmg+Edmg+Rdmg
		return combodmg, Qdmg
	end
end

function Karthus:OnApplyBuff(source, unit, buff)
	if unit and unit.isMe and buff.name == "KarthusDefile" then
		self.E.Active = true
    end
	if unit and unit.isMe and buff.name == "recall" then
		self.recall = true
    end
	if unit and unit.isMe and buff.name == "KarthusDeathDefiedBuff" then
		self.dead = true
	end
end

function Karthus:OnRemoveBuff(unit, buff)
	if unit and unit.isMe and buff.name == "KarthusDefile" then
        self.E.Active = false
    end
	if unit and unit.isMe and buff.name == "recall" then
		self.recall = false
    end
	if unit and unit.isMe and buff.name == "KarthusDeathDefiedBuff" then
		self.dead = false
	end
end


class('MissFortune')
function MissFortune:__init()
	self.Q = {Name = "Double Up", Range = 625, RangeTwo = 1125,IsReady = function() return player:CanUseSpell(_Q) == READY end,}
	self.W = {Name = "Impure Shots", Range = TrueRange, IsReady = function() return player:CanUseSpell(_W) == READY end,}
	self.E = {Name = "Make It Rain", Range = 800, Width = 300, Speed = 500, Delay = 0.5,  IsReady = function() return player:CanUseSpell(_E) == READY end,}
	self.R = {Name = "Bullet Time", Range = 1400, Width = 400, Speed = 780, Delay = 0.5,  IsReady = function() return player:CanUseSpell(_R) == READY end,}
	
	self.minionTable =  minionManager(MINION_ENEMY, self.E.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, self.E.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	self.ETS = TargetSelector(TARGET_LESS_CAST, self.E.Range, DAMAGE_MAGIC, false)
	self.RTS = TargetSelector(TARGET_LESS_CAST, self.R.Range, DAMAGE_MAGIC, false)
	
	self.QTS = TargetSelector(TARGET_LESS_CAST, self.Q.RangeTwo, DAMAGE_MAGIC, false)
	self.WTS = TargetSelector(TARGET_LESS_CAST, self.W.Range, DAMAGE_MAGIC, false)
	self.ETS = TargetSelector(TARGET_LESS_CAST, self.E.Range, DAMAGE_MAGIC, false)
	self.RTS = TargetSelector(TARGET_LESS_CAST, self.R.Range, DAMAGE_MAGIC, false)
	
	self.ScriptName = "Project Kidding"
	
	self.HP_E = HPSkillshot({type = "PromptCircle", range = self.E.Range, delay = self.E.Delay, radius = self.E.Width})
	
	self.DivineE = CircleSS(self.E.Speed, self.E.Range, self.E.Width, self.E.Delay * 1000, math.huge)
	local DivineE = dp:bindSS("DivineE", self.DivineE, 1)
	
	self:LoadMenu()
end

function MissFortune:LoadMenu()
	self.Config = scriptConfig(self.ScriptName, "MissFortune")
	
		if SxOLoad then
			self.Config:addSubMenu("Orbwalking", "Orbwalking")
				SxO:LoadToMenu(self.Config.Orbwalking, Orbwalking)
		end
		
		self.Config:addSubMenu(myHero.charName.." Combo", "Combo")
			self.Config.Combo:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseW", "UseW", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseE", "UseE", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("Enabled", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		
		self.Config:addSubMenu(myHero.charName.." Harass", "Harass")
			self.Config.Harass:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("UseE", "UseE", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("Enabled", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
			
			
		self.Config:addSubMenu(myHero.charName.." LineClear", "LineClear")
			self.Config.LineClear:addParam("UseE", "UseE", SCRIPT_PARAM_ONOFF, true)
			self.Config.LineClear:addParam("Enabled", "Line Clear !", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
			
		self.Config:addSubMenu(myHero.charName.." JungleClear", "JungleClear")
			self.Config.JungleClear:addParam("UseE", "UseE", SCRIPT_PARAM_ONOFF, true)
			self.Config.JungleClear:addParam("Enabled", "Jungle Clear !", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
			
		self.Config:addSubMenu(myHero.charName.." Draw", "Draw")
			self.Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawQColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawEColor", "Draw E Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawRColor", "Draw R Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("Line", "Draw Line", SCRIPT_PARAM_ONOFF, true)
		
		self.Config:addSubMenu(myHero.charName.." Pred", "Pred")
			self.Config.Pred:addParam("EPred", "E Prediction", SCRIPT_PARAM_LIST,1, SupPred)
			
			
	AddTickCallback(function() self:Tick() end)
	AddDrawCallback(function() self:Draw() end)
end

function MissFortune:Tick()
	self:GetTargets()
	if self.Config.Combo.Enabled then
		self:Combo()
	elseif self.Config.Harass.Enabled then
		self:Harass()
	end
	
	if self.Config.LineClear.Enabled then
		self:LineClear()
	end
	
	if self.Config.JungleClear.Enabled then
		self:JungleClear()
	end
end

function MissFortune:Combo()	
	if self.QTarget and self.Config.Combo.UseQ and ValidTarget(self.QTarget, self.Q.RangeTwo) and self.Q.IsReady() then
		self:CastQ(self.QTarget)
	end
	
	if self.WTarget and self.Config.Combo.UseW and self.W.IsReady() then
		self:CastW(self.WTarget)
	end
	
	if self.ETarget and self.Config.Combo.UseE and self.E.IsReady() then
		self:CastE(self.ETarget)
	end
end

function MissFortune:Harass()
	if self.QTarget and self.Config.Harass.UseQ and ValidTarget(self.QTarget, self.Q.Range) then
		self:CastQ(self.QTarget)
	end
	
	if self.ETarget and self.Config.Harass.UseE then
		self:CastE(self.ETarget)
	end
end

function MissFortune:LineClear()
	self.minionTable:update()
	for i, minion in pairs(self.minionTable.objects) do
		if minion ~= nil and not minion.dead then
			if self.Config.LineClear.UseE and self.E.IsReady()then
				local bestpos, besthit = GetBestCircularFarmPosition(self.E.Range, self.E.Width, self.minionTable.objects)
				if besthit ~= nil and bestpos ~= nil then
					CastSpell(_E, bestpos.x, bestpos.z)
				end
			end
		end
	end
end

function MissFortune:JungleClear()
	self.jungleTable:update()
	for i, minion in pairs(self.jungleTable.objects) do
		if minion ~= nil and not minion.dead then
			if self.Config.LineClear.UseE and self.E.IsReady()then
				local bestpos, besthit = GetBestCircularFarmPosition(self.E.Range, self.E.Width, self.jungleTable.objects)
				if besthit ~= nil and bestpos ~= nil then
					CastSpell(_E, bestpos.x, bestpos.z)
				end
			end
		end
	end
end

function MissFortune:GetTargets()
	self.Target = GetTarget()
	
	if self.Target and self.Target.team ~= myHero.team and self.Target.type == myHero.type and ValidTarget(self.Target, self.Q.Range) then
		self.QTarget = self.Target
	else
		self.QTS:update()
		self.QTarget = self.QTS.target
	end
	
	self.WTS:update()
	self.WTarget = self.WTS.target
	
	self.ETS:update()
	self.ETarget = self.ETS.target
end

function MissFortune:CastQ(unit)
	if unit ~= nil then
		if GetDistance(player, unit) < self.Q.Range then
			CastSpell(_Q, unit)
		elseif GetDistance(unit) < self.Q.RangeTwo then
			for i, Champion in pairs(GetEnemyHeroes()) do
				local Theta = Vector(Champion):angleBetween(Vector(myHero), Vector(unit))
				if 157.5 < Theta and Theta < 202.5 and GetDistance(unit, Champion) < 450 and GetDistance(Champion) < self.Q.Range and unit ~= Champion then
					CastSpell(_Q, Champion)
					return
				end
			end
			self.minionTable:update()
			for i , Minion in pairs(self.minionTable.objects) do
				local Theta = Vector(Minion):angleBetween(Vector(myHero), Vector(unit))
				if 157.5 < Theta and Theta < 202.5 and GetDistance(unit, Minion) < 450 and GetDistance(Minion) < self.Q.Range then
					CastSpell(_Q, Minion)
				end
			end
		end
	end
end

function MissFortune:CastW(target)
	if target~= nil then
		if self.WTarget ~= nil then
			CastSpell(_W)
		end
	end
end


function MissFortune:CastE(target)
	if target ~= nil then
		if self.Config.Pred.EPred == 1 then
			self.EPos, self.EHitChance = HP:GetPredict(self.HP_E, target, myHero)
			if self.EHitChance >= 1.4 and self.EPos ~= nil then
				CastSpell(_E, self.EPos.x, self.EPos.z)
			end
		elseif self.Config.Pred.EPred == 2 then
			self.EPos, self.EHitChance = VP:GetLineAOECastPosition(target, self.E.Delay, self.E.Width, self.E.Range, self.E.Speed, myHero)
			if self.EPos and self.EHitChance >= 1.4 then
				CastSpell(_W, self.EPos.x, self.EPos.z)
			end
		elseif self.Config.Pred.EPred == 3 then
			self.EPos, self.EHitChance, self.PredPos = SP:PredictPos(target, self.E.Speed, self.E.Delay)
			if self.EPos and self.EHitChance >= 0.4 then
				CastSpell(_Q, self.EPos.x, self.EPos.z)
			end
		elseif self.Config.Pred.EPred == 4 then
			Target = DPTarget(target)
			self.EState, self.EPos, self.Qperc = dp:predict("DivineE",Target)
			if self.EState == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_E, self.EPos.x, self.EPos.z)
			end
		end
	end
end

function MissFortune:Draw()
	if myHero.dead then return end
	if self.Q.IsReady() and self.Config.Draw.DrawQ then
		DrawCircles(player.x, player.y, player.z, self.Q.Range, TARGB(self.Config.Draw.DrawQColor))
	end

	if self.E.IsReady() and self.Config.Draw.DrawE then
		DrawCircles(player.x, player.y, player.z, self.E.Range, TARGB(self.Config.Draw.DrawEColor))
	end

	if self.R.IsReady() and self.Config.Draw.DrawR then
		DrawCircles(player.x, player.y, player.z, self.R.Range, TARGB(self.Config.Draw.DrawRColor))
	end
	
		if self.EHitChance ~= nil then
		if self.EHitChance == -1 then
			self.Ecolor = ARGB(0xFF, 0x00, 0x00, 0x00)
		elseif self.EHitChance < 1 then
			self.Ecolor = ARGB(0xFF, 0xFF, 0x00, 0x00)
		elseif self.EHitChance == 3 then
			self.Ecolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
		elseif self.EHitChance >= 2 then
			self.Ecolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.EHitChance >= 1 then
			self.Ecolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		end
	end

	
		if self.EPos and self.Ecolor and self.E.IsReady() then
		DrawCircles(self.EPos.x, self.EPos.y, self.EPos.z, self.E.Width/2, self.Ecolor)
    
		if self.Config.Draw.Line then
			DrawLine3D(myHero.x, myHero.y, myHero.z, self.EPos.x, self.EPos.y, self.EPos.z, 2, self.Ecolor)
		end
		
		self.EPos = nil
	end
end

--[[
class('Interrupt')
function Interrupt:__init(spell, Col, table)
	self.InterruptList = {
		{ charName = "Caitlyn", spellName = "CaitlynAceintheHole"},
		{ charName = "FiddleSticks", spellName = "Crowstorm"},
		{ charName = "FiddleSticks", spellName = "DrainChannel"},
		{ charName = "Galio", spellName = "GalioIdolOfDurand"},
		{ charName = "Karthus", spellName = "FallenOne"},
		{ charName = "Katarina", spellName = "KatarinaR"},
		{ charName = "Lucian", spellName = "LucianR"},
		{ charName = "Malzahar", spellName = "AlZaharNetherGrasp"},
		{ charName = "MissFortune", spellName = "MissFortuneBulletTime"},
		{ charName = "Nunu", spellName = "AbsoluteZero"},
		{ charName = "Pantheon", spellName = "Pantheon_GrandSkyfall_Jump"},
		{ charName = "Shen", spellName = "ShenStandUnited"},
		{ charName = "Urgot", spellName = "UrgotSwap2"},
		{ charName = "Varus", spellName = "VarusQ"},
		{ charName = "Warwick", spellName = "InfiniteDuress"}
	}
	self.ToInterrupt ={}
	
	self.scriptName = "ezInterrupt"
	self.Version = "1.0.0"
	
	self.AntiIntSpell = spell or nil
	self.SpellCol = Col or false
	self.Spell = {}
	if Col then
		self.Spell = table
	end
	if self.SpellCol then self.SpellCollistion = Collision(self.Spell.Range, self.Spell.Speed, self.Spell.Delay, self.Spell.Width) end
	
	for i = 1, heroManager.iCount do
        local hero = heroManager:GetHero(i)
		for _, champ in pairs(self.InterruptList) do
			if hero.charName == champ.charName and hero.team ~= myHero.team then
				table.insert(self.ToInterrupt, champ)
			end
        end
    end
end

function Interrupt:LoadToMenu(menu)
	if menu then
		self.Config = menu
	else
		self.Config = scriptConfig(self.scriptName, self.scriptName)
	end
	
	self.Config:addSubMenu(self.scriptName.." General", "General")
		self.Config.General:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
		self.Config.General:addParam("Delay" ,"Delay", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
		
	self.Config:addSubMenu(self.scriptName.." InterruptList", "InterruptList")
		for index, _spell in ipairs(self.ToInterrupt) do
			self.Config.InterruptList:addParam(_spell.spellName, "Cansel ".._spell.spellName, SCRIPT_PARAM_ONOFF, true)
		end
	
	self.Config:addParam("BLANK", "", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("Spell" ,"Interrupt Spell", SCRIPT_PARAM_INFO, tostring(self.AntiIntSpell))
	self.Config:addParam("Version", "Version", SCRIPT_PARAM_INFO, self.Version)
	AddProcessSpellCallback(function(unit, spell) self:ProcessSpell(unit, spell) end)
end

function Interrupt:ProcessSpell(unit, spell)
	if #self.ToInterrupt > 0 then
		for _, ability in pairs(self.ToInterrupt) do
			if spell.name == ability.spellName and unit.team ~= player.team and GetDistance(unit) < 2000 and self.Config.InterruptList[ability.spellName] and self.AntiIntSpell ~= nil then
				if self.SpellCol then
					if self.SpellCollistion:GetMinionCollision(myHero, unit) and self.SpellCollistion:GetHeroCollision(myHero, unit, HERO_ENEMY) then	
						CastSpell(self.AntiIntSpell, unit.x, unit.z)
					end
				else
					CastSpell(self.AntiIntSpell, unit.x, unit.z)
				end
			end
		end
	end
end
]]
class('Awareness')
function Awareness:__init()
	self.SpellsData = {}
	self.SSpells = {
			{CName="Flash", Name="summonerflash", Color={255, 255, 255, 0} },
			{CName="Ghost", Name="summonerhaste", Color={255, 0, 0, 255} },
			{CName="Ignite", Name="summonerdot", Color={255, 255, 0, 0 }},
			{CName="Barrier", Name="summonerbarrier", Color={255, 209, 143, 0}},
			{CName="Smite", Name="summonersmite", Color={255, 209, 143, 0}},
			{CName="Exhaust", Name="summonerexhaust", Color={255, 209, 143, 0}},
			{CName="Heal", Name="summonerheal", Color={255, 0, 255, 0}},
			{CName="Teleport", Name="summonerteleport", Color={255, 192, 0, 209}},
			{CName="Cleanse", Name="summonerboost", Color={255, 255, 138, 181}},
			{CName="Clarity", Name="summonermana", Color={255, 0, 110, 255}},
			{CName="Clairvoyance", Name="summonerclairvoyance", Color={255, 0, 110, 255}},
			{CName="Revive", Name="summonerrevive", Color={255, 0, 255, 0}},
			{CName="Garrison", Name="summonerodingarrison", Color={255, 0, 110, 255}},
			{CName="The Rest", Name="TheRest", Color={255, 255, 255, 255}},
	}
	self.TrackSpells = {_Q, _W, _E, _R}
	self.TickLimit = 0
	self.wards = {}
	self.visions= {}
	
	self.Ignite		= {slot = nil, Range = 600, IsReady = function() return (self.Ignite.slot ~= nil and myHero:CanUseSpell(self.Ignite.slot) == READY) end, Damage = function(target) return getDmg("IGNITE", target, myHero)*0.95 end}
	self.Barrier	= {slot = nil, Range = 0, IsReady = function() return (self.Barrier.slot ~= nil and myHero:CanUseSpell(self.Barrier.slot) == READY) end,}
	self.Smite		= {slot = nil, Range = 700, IsReady = function() return (self.Smite.slot ~= nil and myHero:CanUseSpell(self.Smite.slot) == READY) end, Damage = 0 }
	
	self.Ignite.slot = FindSummonerSlot("summonerdot")
	self.Barrier.slot = FindSummonerSlot("summonerbarrier")
	self.Smite.slot = FindSummonerSlot("summonersmite")
	
	self.minionTable =  minionManager(MINION_ENEMY, self.Smite.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, self.Smite.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	self.STS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 730, DAMAGE_PHYSICAL, false)
	
	self:LoadToMenu()
end

function Awareness:LoadToMenu()
	self.Config = scriptConfig("ezAwareness", "ezAwareness")
		self.Config:addSubMenu("CoolDownChecker", "CoolDownChecker")
			self.Config.CoolDownChecker:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			self.Config.CoolDownChecker:addParam("EnemyOn", "Enemy On", SCRIPT_PARAM_ONOFF, true)
			self.Config.CoolDownChecker:addParam("AllyOn", "Ally On", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu("WardTracker", "WardTracker")
			self.Config.WardTracker:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			
		
		self.Config:addSubMenu("SummonerHelper", "SummonerHelper")
			self.Config.SummonerHelper:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
				if self.Ignite.slot ~= nil then
					self.Config.SummonerHelper:addSubMenu("Ignite", "Ignite")
						self.Config.SummonerHelper.Ignite:addParam("IgniteOn", "Ignite On", SCRIPT_PARAM_ONOFF, true)
				end
				if self.Barrier.slot ~= nil then
					self.Config.SummonerHelper:addSubMenu("Barrier", "Barrier")
					self.Config.SummonerHelper.Barrier:addParam("BarrierOn", "Barrier On", SCRIPT_PARAM_ONOFF, true)
					self.Config.SummonerHelper.Barrier:addParam("health", "health", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
				end
				if self.Smite.slot ~= nil then
					self.Config.SummonerHelper:addSubMenu("smite", "smite")
						self.Config.SummonerHelper.smite:addParam("toggleuse", "Toggle Use", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("N"))
						self.Config.SummonerHelper.smite:addParam("autouse", "Auto Use", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
						self.Config.SummonerHelper.smite:addParam("hotkeycc", "Object: CC HotKey", SCRIPT_PARAM_ONKEYDOWN, false, 32)
						self.Config.SummonerHelper.smite:addParam("smite0", "Object: Champion CC", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite00", "Object: Champion LastHit", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
						self.Config.SummonerHelper.smite:addParam("smite1", "Baron", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite2", "Dragon", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite3", "Crab(Baron/Dragon)", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
						self.Config.SummonerHelper.smite:addParam("smite4", "Full Blue Camp", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite5", "Red", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite6", "Blue", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite7", "Gromp", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite8", "Wolf", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite9", "Beak", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite10", "Krug", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
						self.Config.SummonerHelper.smite:addParam("smite11", "Full Red Camp", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite12", "Red", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite13", "Blue", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite14", "Gromp", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite15", "Wolf", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite16", "Beak", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite17", "Krug", SCRIPT_PARAM_ONOFF, true)
				end
			
	AddTickCallback(function() self:Tick() end)
	AddDrawCallback(function() self:Draw() end)
	AddCreateObjCallback(function(obj) self:OnCreatWard(obj) end)
	AddDeleteObjCallback(function(obj) self:OnDeleteWard(obj) end)
end

function Awareness:Tick()
	self:CoolDownTick()
	if self.Config.SummonerHelper.On then self:SummonerHelper() end
	if self.Config.SummonerHelper.On and self.Smite.slot ~= nil then
		if myHero.level >14 then self.Smite.Damage = 800 + ((myHero.level-14)*50) end
		if myHero.level > 9 then self.Smite.Damage = 600 + ((myHero.level-9)*40) end
		if myHero.level > 5 then self.Smite.Damage = 480 + ((myHero.level-5)*30) end
		if myHero.level > 0 then self.Smite.Damage = 370 + ((myHero.level)*20) end
	end
	
	if self.Smite.slot ~= nil then
		self.STS:update()
		self.STarget = self.STS.target
	end
end

function Awareness:Draw()
	if self.Config.CoolDownChecker.On then self:CoolDownDraw() end
	if self.Config.WardTracker.On then self:WardTrackerDraw() end
	if self.Smite.slot ~= nil and (self.Config.SummonerHelper.smite.toggleuse or self.Config.SummonerHelper.smite.autouse) then
		DrawCircle(player.x, player.y, player.z, self.Smite.Range, Colors.Green)
	end
end

function Awareness:SummonerHelper()
	if self.Ignite.slot ~= nil and self.Config.SummonerHelper.Ignite.IgniteOn then
		for index, hero in ipairs(GetEnemyHeroes()) do
			if GetDistance(hero) < self.Ignite.Range and self.Ignite.Damage(hero) > hero.health and self.Ignite.IsReady() then
				CastSpell(self.Ignite.slot, hero)
			end
		end
	end
	
	if self.Smite.slot ~= nil and self.Config.SummonerHelper.smite.hotkeycc and self.Config.SummonerHelper.smite.smite0 and ValidTarget(self.STarget, 710) and self.Smite.IsReady() then
		self:CastSmite(self.STarget)
	end
	
	if self.Barrier.slot ~= nil and self.Config.SummonerHelper.Barrier.BarrierOn then
		if (myHero.health / myHero.maxHealth * 100) < self.Config.SummonerHelper.Barrier.health and self.Barrier.IsReady() then
			CastSpell(self.Barrier.slot)
		end
	end
		
	if self.Smite.slot ~= nil and (self.Config.SummonerHelper.smite.toggleuse or self.Config.SummonerHelper.smite.autouse) then
		self.jungleTable:update()
		for i, junglemob in pairs(self.jungleTable.objects) do				
			if junglemob == nil then
				return
			end			
			if ValidTarget(junglemob, 720) then
				if self.Config.SummonerHelper.smite.smite1 and junglemob.name=="SRU_Baron12.1.1" and junglemob.health < self.Smite.Damage then
					self:CastSmite(junglemob)
				end

				if self.Config.SummonerHelper.smite.smite2 and junglemob.name=="SRU_Dragon6.1.1" and junglemob.health < self.Smite.Damage then					
					self:CastSmite(junglemob)
				end

				if self.Config.SummonerHelper.smite.smite3 and (junglemob.name=="Sru_Crab15.1.1" or junglemob.name=="Sru_Crab16.1.1") and junglemob.health < self.Smite.Damage then
					self:CastSmite(junglemob)
				end

				if self.Config.SummonerHelper.smite.smite4 then					
					if self.Config.SummonerHelper.smite.smite5 and junglemob.name=="SRU_Red4.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end
					
					if self.Config.SummonerHelper.smite.smite6 and junglemob.name=="SRU_Blue1.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite7 and junglemob.name=="SRU_Gromp13.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite8 and junglemob.name=="SRU_Murkwolf2.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite9 and junglemob.name=="SRU_Razorbeak3.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite10 and junglemob.name=="SRU_Krug5.1.2" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end
				end

				if self.Config.SummonerHelper.smite.smite11 then
					if self.Config.SummonerHelper.smite.smite12 and junglemob.name=="SRU_Red10.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite13 and junglemob.name=="SRU_Blue7.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite14 and junglemob.name=="SRU_Gromp14.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite15 and junglemob.name=="SRU_Murkwolf8.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite16 and junglemob.name=="SRU_Razorbeak9.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite17 and junglemob.name=="SRU_Krug11.1.2" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end
				end
			end
		end
	end
end

function Awareness:CastSmite(target)
	if target ~= nil and GetDistance(target) < self.Smite.Range then
		CastSpell(self.Smite.slot, target)
	end
end

function Awareness:CoolDownTick()
	if os.clock() - self.TickLimit > 0.3 then
		self.TickLimit = os.clock()
		for i=1, heroManager.iCount, 1 do
			local hero = heroManager:getHero(i)
			if ValidTarget(hero, math.huge, false) or ValidTarget(hero) then
				--[[	Update the current cooldowns]]
				hero = heroManager:getHero(i)
				for _, spell in pairs(self.TrackSpells) do
					if self.SpellsData[i] == nil then
						self.SpellsData[i] = {}
					end
					if self.SpellsData[i][spell] == nil then
						self.SpellsData[i][spell] = {currentCd=0, maxCd = 0, level=0}
					end
					--[[	Get the maximum cooldowns to make the progress  bar]]
					local thespell = hero:GetSpellData(spell)
					local currentcd
					if thespell and thespell.currentCd then
						currentcd = thespell.currentCd
					end
					if currentcd and thespell and thespell.currentCd then
						self.SpellsData[i][spell] = {
							currentCd = math.floor(currentcd),
							maxCd = math.floor(currentcd) > self.SpellsData[i][spell].maxCd and math.floor(currentcd) or self.SpellsData[i][spell].maxCd,
							level = thespell.level
						}
					end
				end
			end
		end
	end
	self.FirstTick = true
end


function Awareness:CoolDownDraw()
	if (self.Config.CoolDownChecker.EnemyOn or self.Config.CoolDownChecker.AllyOn) and self.FirstTick then
		for i=1, heroManager.iCount, 1 do
			local hero = heroManager:getHero(i)
			if ((ValidTarget(hero, math.huge,false)  and (self.Config.CoolDownChecker.AllyOn)) or (ValidTarget(hero) and (self.Config.CoolDownChecker.EnemyOn))) and not hero.isMe then
				local barpos = GetHPBarPos(hero)
				if OnScreen(barpos.x, barpos.y) and (self.SpellsData[i] ~= nil) then
					local pos = Vector(barpos.x, barpos.y, 0)
					local CDcolor = ARGB(255, 214, 114, 0)
					local Readycolor = ARGB(255, 54, 214, 0)
					local Textcolor = ARGB (255, 255, 255, 255)
					local Backgroundcolor = ARGB(255, 128, 128, 128)
					local width = 20
					local height = 5
					local sep = 2
					--[[First 4 spells]]
					pos.y =  pos.y + 0
					for j, Spells in ipairs (self.TrackSpells) do
						local currentcd = self.SpellsData[i][Spells].currentCd
						local maxcd = self.SpellsData[i][Spells].maxCd
						local level = self.SpellsData[i][Spells].level
						
						if j > 4 then
							CDcolor = ARGB(255, 255, 255, 255)
							--[[
							for _, spell in ipairs(SSpells) do
								if (hero:GetSpellData(j == 5 and SUMMONER_1 or SUMMONER_2).name == spell.Name) then
									CDcolor = ARGB(255, 214, 114, 0)
								end
							end
							]]
							Readycolor = CDcolor
						end
						
						self:DrawRectangleAL(pos.x-1, pos.y-1, width + sep , height+4, Backgroundcolor)
					
						if level == 0 then
							self:DrawRectangleAL(pos.x, pos.y, width, height, 0xBBFFFFFF)
						else
							if (currentcd ~= 0) then
								self:DrawRectangleAL(pos.x, pos.y, width - math.floor(width * currentcd) / maxcd, height, CDcolor)
							else
								self:DrawRectangleAL(pos.x, pos.y, width, height, Readycolor)
							end
						end
					
						if (currentcd ~= 0) and (currentcd < 100) then
							DrawText(tostring(currentcd),13, pos.x+6, pos.y+4, ARGB(255, 0, 0, 0))
							DrawText(tostring(currentcd),13, pos.x+8, pos.y+6, ARGB(255, 0, 0, 0))
							DrawText(tostring(currentcd),13, pos.x+7, pos.y+5, Textcolor)
						--[[
						elseif IsKeyDown(16) then
							DrawText(tostring(level),13, pos.x+6, pos.y+4, ARGB(255, 0, 0, 0))
							DrawText(tostring(level),13, pos.x+8, pos.y+6, ARGB(255, 0, 0, 0))
							DrawText(tostring(level),13, pos.x+7, pos.y+5, Textcolor)
						]]
						end
						pos.x = pos.x + width + sep
						if j == 4 then break end
					end
					pos.x = barpos.x + 25*5+3 + 2*4
					pos.y = barpos.y - 8
					--[[Last 2 spells]]
					--[[
					for j, Spells in ipairs (TrackSpells) do
						local currentcd = self.SpellsData[i][Spells].currentCd
						local maxcd = self.SpellsData[i][Spells].maxCd
						local width2 = 202
						if j > 4 then
							CDcolor = ARGB(255, 255, 255, 255)
							for _, spell in ipairs(SSpells) do
								if  (hero:GetSpellData(j == 5 and SUMMONER_1 or SUMMONER_2).name == spell.Name) then
									CDcolor = ARGB(255, 214, 114, 0)
								end
							end
							self:DrawRectangleAL(pos.x, pos.y,width2+2,11,Backgroundcolor)
							if currentcd ~= 0 then
								self:DrawRectangleAL(pos.x+1, pos.y+1, width2 - width2 * currentcd / maxcd,9,CDcolor)
							else
								self:DrawRectangleAL(pos.x+1, pos.y+1, width2, 9, CDcolor)
							end
							if (currentcd ~= 0) and (currentcd < 100) then
								DrawText(tostring(currentcd),13, pos.x-1, pos.y-1, ARGB(255, 0, 0, 0))
								DrawText(tostring(currentcd),13, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
								DrawText(tostring(currentcd),13, pos.x, pos.y, Textcolor)
							end
							Readycolor = CDcolor
							pos.y = pos.y - 12
						end
					end
					]]
				end
			end
		end
	end
end

function Awareness:DrawRectangleAL(x, y, w, h, color)
	local Points = {}
	Points[1] = D3DXVECTOR2(math.floor(x), math.floor(y))
	Points[2] = D3DXVECTOR2(math.floor(x + w), math.floor(y))
	DrawLines2(Points, math.floor(h), color)
end


function Awareness:OnCreatWard(obj)
	if obj.name:lower():find("sight") and obj.maxMana > 0 and obj.team ~= myHero.team then
		local ward = {x = obj.x, y = obj.y, z = obj.z, mana = obj.mana, time = GetGameTimer(), type = "SightWard"}
		table.insert(self.wards, ward);
	end
end

function Awareness:OnDeleteWard(obj)
	for index, ward in pairs(self.wards) do
		if (obj.x == ward.x) and (obj.x == ward.x) and (obj.x == ward.x) then
			table.remove(self.wards, index)
		end
	end
end

function Awareness:WardTrackerDraw()
	for index, ward in pairs(self.wards) do
		currentMana = math.floor(ward.mana - (GetGameTimer() - ward.time))
		if (currentMana <= 0) then
			table.remove(self.wards, index)
		else
			LagFreeDrawCircle(ward.x, ward.y, ward.z, 100, RGBA(127, 255, 0, 255))
			DrawText3D(tostring(currentMana), ward.x, ward.y, ward.z, 20, RGBA(127, 255, 0, 255), true)
		end
	end
	
	for index, ward in pairs(self.visions) do
		currentMana = math.floor(ward.mana - (GetGameTimer() - ward.time))
		if (currentMana <= 0) then
			table.remove(self.wards, index)
		else
			LagFreeDrawCircle(ward.x, ward.y, ward.z, 100, Colors.Red)
			DrawText3D(tostring(currentMana), ward.x, ward.y, ward.z, 20, Colors.Red, true)
		end
	end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
    radius = radius or 300
    quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
    quality = 2 * math.pi / quality
    radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end

function DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
        DrawCircleNextLvl(x, y, z, radius, 1, color, 75)
    end
end

function DrawCircles(x,y,z,radius, color)
    DrawCircle2(x, y, z, radius, color)
end

