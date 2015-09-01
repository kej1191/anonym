local champions = {
    ["Azir"]        	  = true,
	["Varus"]			= true,
}
local function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>9999 Azir:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
Version = 1.09
require 'SourceLib'
require 'HPrediction'
require 'DivinePred'
require 'SPrediction'
require 'VPrediction'

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
    DrawText('Download Status: '..(self.DownloadStatus or 'Unknown'),18,10,50,ARGB(0xFF,0xFF,0xFF,0xFF))
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

local STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
local orbload = false
local player = myHero
local TrueRange = myHero.range + myHero:GetDistance(myHero.minBBox)
local minionTable =  minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_MAXHEALTH_DEC)

local SP = SPrediction()
local HP = HPrediction()
local dp = DivinePred()
local VP = VPrediction()


local LastCheck = 0
local Colors = { 
    -- O R G B
    Green   =  ARGB(255, 0, 180, 0), 
    Yellow  =  ARGB(255, 255, 215, 00),
    Red     =  ARGB(255, 255, 0, 0),
    White   =  ARGB(255, 255, 255, 255),
    Blue    =  ARGB(255, 0, 0, 255),
}

local InterruptList = {
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

function AuthCheck()
	randomkey = tostring(math.random(10000, 99999))
	username = (RC4("username"..randomkey, GetUser())):tohex()
	Uri = "/auth/api.php?key="..tostring(randomkey).."&username="..username.."&&status=launch&keycode=6b94368c4127ba5f8b2c88359ad66b3d&region=KR&version=5.16"

	LuaSocket = require("socket")
	key = "vcVV2dB5gjm7hTJwsOvE"..randomkey
	getSocketData = LuaSocket.connect("authauth.net", 80)
	getSocketData:send("GET "..Uri.." HTTP/1.0\r\nHost: auth.zhost.kr\r\n\r\n")
	-- getSocketData:settimeout(0, 'b')
	getSocketData:settimeout(99, 't')
	dataReceive, socketStatus = getSocketData:receive('*a')
	result = string.split(dataReceive, "\r\n\r\n")
	if result[2]:find("_invalid@key_") or result[2]:find("_invalid@username_") or result[2]:find("_invalid@keycode_") then
		AutoupdaterMsg("Invalid Information")
		return 
	end
	result3 = RC4(key, (result[2]):fromhex())
	if result3:find("_trial@user_") then
		AutoupdaterMsg("Wellcome "..GetUser().." to Trial User")
	elseif result3:find("_trial@finished_") then
		AutoupdaterMsg("Trial Finished, buy this script")
		return
	elseif result3:find("_auth@user_") then
		AutoupdaterMsg("Wellcome "..username.." to Auth User")
	elseif result3:find("_banned@user_") then
		AutoupdaterMsg("Fuck You Ban User")
		return
	elseif result3 == "0" then
		AutoupdaterMsg("Auth Checking Error")
		DelayAction(AuthCheck, 1)
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

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

local function KSA(key)
  local key_len = string.len(key)
  local S = {}
  local key_byte = {}

  for i = 0, 255 do
    S[i] = i
  end

  for i = 1, key_len do
    key_byte[i-1] = string.byte(key, i, i)
  end

  local j = 0
  for i = 0, 255 do
    j = (j + S[i] + key_byte[i % key_len]) % 256
    S[i], S[j] = S[j], S[i]
  end
  return S
end

local function PRGA(S, text_len)
  local i = 0
  local j = 0
  local K = {}

  for n = 1, text_len do

    i = (i + 1) % 256
    j = (j + S[i]) % 256

    S[i], S[j] = S[j], S[i]
    K[n] = S[(S[i] + S[j]) % 256]
  end
  return K
end

--RC4 cryption
--key: crypte key
--text: text needed to crypte
function RC4(key, text)
  local text_len = string.len(text)

  local S = KSA(key)
  local K = PRGA(S, text_len)
  return output(K, text)
end

function output(S, text)
  local len = string.len(text)
  local c = nil
  local res = {}
  for i = 1, len do
    c = string.byte(text, i, i)
    res[i] = string.char(bxor(S[i], c))
  end
  return table.concat(res)
end

bit_op = {}
function bit_op.cond_and(r_a, r_b)
  return (r_a + r_b == 2) and 1 or 0
end

function bit_op.cond_xor(r_a, r_b)
  return (r_a + r_b == 1) and 1 or 0
end

function bit_op.cond_or(r_a, r_b)
  return (r_a + r_b > 0) and 1 or 0
end

function bit_op.base(op_cond, a, b)
  -- bit operation
  if a < b then
    a, b = b, a
  end
  local res = 0
  local shift = 1
  while a ~= 0 do
    r_a = a % 2
    r_b = b % 2

    res = shift * bit_op[op_cond](r_a, r_b) + res
    shift = shift * 2

    a = math.modf(a / 2)
    b = math.modf(b / 2)
  end
  return res
end

function bxor(a, b)
  return bit_op.base('cond_xor', a, b)
end

function band(a, b)
  return bit_op.base('cond_and', a, b)
end

function bor(a, b)
  return bit_op.base('cond_or', a, b)
end

function string.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

function string.fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
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
function OnLoad()
	AuthCheck()
	ToUpdate = {}
	ToUpdate.Host = "raw.githubusercontent.com"
	ToUpdate.VersionPath = "/kej1191/anonym/master/KOM/OnYour/OnYour.version"
	ToUpdate.ScriptPath =  "/kej1191/anonym/master/KOM/OnYour/OnYour.lua"
	ToUpdate.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
	ToUpdate.CallbackUpdate = function(NewVersion, OldVersion) print("<font color=\"#00FA9A\"><b>[OnYour] </b></font> <font color=\"#6699ff\">Updated to "..NewVersion..". </b></font>") end
	ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#00FA9A\"><b>[OnYour] </b></font> <font color=\"#6699ff\">You have lastest version ("..OldVersion..")</b></font>") end
	ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#00FA9A\"><b>[OnYour] </b></font> <font color=\"#6699ff\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
	ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#00FA9A\"><b>[OnYour] </b></font> <font color=\"#6699ff\">Error while Downloading. Please try again.</b></font>") end
	ScriptUpdate(Version, true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)

	Aw= Awareness()
	if myHero.charName == "Azir" then
		champ = Azir()
	elseif myHero.charName == "Varus" then
		champ = Varus()
	end
end

function OnUnLoad()
	--local Auth = GetWebResult("auth.zhost.kr", "/api.php?key=24587&username=test&status=win&keycode=e873d0696494f30c136f62b2e0cc9222")
end

function OnTick()
	 if os.clock()-LastCheck > 3 then
		LastCheck = os.clock()
		for i = 1, objManager.iCount, 1 do
			local object = objManager:getObject(i)
			if object and object.type and type(object.type) == "string" and object.type == "obj_HQ" and object.health and type(object.health) == "number" and object.health == 0 and not _end then
				if object.team == myHero.team then
					Uri = "/api.php?key="..tostring(randomkey).."&username="..username.."&&status=lose&keycode=6b94368c4127ba5f8b2c88359ad66b3d&region=KR&version=5.16"
					LuaSocket = require("socket")
					key = "vcVV2dB5gjm7hTJwsOvE"..randomkey
					getSocketData = LuaSocket.connect("auth.zhost.kr", 80)
					getSocketData:send("GET "..Uri.." HTTP/1.0\r\nHost: auth.zhost.kr\r\n\r\n")
					-- getSocketData:settimeout(0, 'b')
					getSocketData:settimeout(99, 't')
					dataReceive, socketStatus = getSocketData:receive('*a')
				else
					Uri = "/api.php?key="..tostring(randomkey).."&username="..username.."&&status=win&keycode=6b94368c4127ba5f8b2c88359ad66b3d&region=KR&version=5.16"
					LuaSocket = require("socket")
					key = "vcVV2dB5gjm7hTJwsOvE"..randomkey
					getSocketData = LuaSocket.connect("auth.zhost.kr", 80)
					getSocketData:send("GET "..Uri.." HTTP/1.0\r\nHost: auth.zhost.kr\r\n\r\n")
					-- getSocketData:settimeout(0, 'b')
					getSocketData:settimeout(99, 't')
					dataReceive, socketStatus = getSocketData:receive('*a')
				end
			end
		end
	end
end

class('Azir')
function Azir:__init()
  
	OnOrbLoad()
	self.Q = {Range = 800, Speed = 1600, Witdh = 80, Delay = 0, IsReady = function() return myHero:CanUseSpell(_Q) == READY end,}
	self.W = {Range = 450, IsReady = function() return myHero:CanUseSpell(_W) == READY end,}
	self.E = {Range = 1100, Speed = 1200, Delay = 0.25, Width = 100, IsReady = function() return myHero:CanUseSpell(_E) == READY end,}
	self.R = {Range = 250, Speed = 1400, Width = 700, Delay = 0.5, IsReady = function() return myHero:CanUseSpell(_R) == READY end,}
	self.AS = {Range = 310}
	
	self.minionTable =  minionManager(MINION_ENEMY, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	self.QTS = TargetSelector(TARGET_LESS_CAST, self.Q.Range, DAMAGE_MAGIC, false)
	self.WTS = TargetSelector(TARGET_LESS_CAST, self.W.Range, DAMAGE_MAGIC, false)
	self.ETS = TargetSelector(TARGET_LESS_CAST, self.E.Range, DAMAGE_MAGIC, false)
	self.RTS = TargetSelector(TARGET_LESS_CAST, self.R.Range, DAMAGE_MAGIC, false)
	
	--self.Interrupt = Interrupt(_R, false, {})
	self.ScriptName = "9999 Azir"
	self.Flash = FindSummonerSlot("summonerflash")
	
	self.ToInterrupt = {}
	for i = 1, heroManager.iCount do
        local hero = heroManager:GetHero(i)
		for _, champ in pairs(InterruptList) do
			if hero.charName == champ.charName then
				table.insert(self.ToInterrupt, champ.spellName)
			end
        end
    end
	self:LoadMenu()
	
	self.AzirSoldier = {}
end

function Azir:LoadMenu()
		self.Config = scriptConfig(self.ScriptName, "Azir")
		
		if SxOLoad then
			self.Config:addSubMenu("Orbwalking", "Orbwalking")
				SxO:LoadToMenu(self.Config.Orbwalking, Orbwalking)
		end
			
		self.Config:addSubMenu("Azir - Combo", "Combo")
			self.Config.Combo:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseW", "UseW", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseQunder", "Use Q under can aa", SCRIPT_PARAM_SLICE, 1, 0, 3, 0)
			self.Config.Combo:addParam("Enabled", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		
		self.Config:addSubMenu("Azir - Harass", "Harass")
			self.Config.Harass:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("UseW", "UseW", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("LimitAS", "Limit AzirSoldier", SCRIPT_PARAM_SLICE, 1, 1, 3, 0)
			self.Config.Harass:addParam("UseQunder", "Use Q under can aa", SCRIPT_PARAM_SLICE, 1, 0, 3, 0)
			self.Config.Harass:addParam("Enabled", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
			
		self.Config:addSubMenu("Azir - Insec", "Insec")
			self.Config.Insec:addParam("To", "To", SCRIPT_PARAM_LIST, 1, {"To Mouse", "To Closet Tower"})
			self.Config.Insec:addParam("DrawTarget", "Draw Insec Line", SCRIPT_PARAM_ONOFF, true)
			self.Config.Insec:addParam("Enabled", "Insec", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
			
		self.Config:addSubMenu("Azir - LineClear", "LineClear")
			self.Config.LineClear:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			self.Config.LineClear:addParam("UseW", "UseW", SCRIPT_PARAM_ONOFF, true)
			self.Config.LineClear:addParam("LimitAS", "Limit AzirSoldier", SCRIPT_PARAM_SLICE, 1, 1, 3, 0)
			self.Config.LineClear:addParam("Enabled", "Line Clear !", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
			
		self.Config:addSubMenu("Azir - JungleClear", "JungleClear")
			self.Config.JungleClear:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			self.Config.JungleClear:addParam("UseW", "UseW", SCRIPT_PARAM_ONOFF, true)
			self.Config.JungleClear:addParam("LimitAS", "Limit AzirSoldier", SCRIPT_PARAM_SLICE, 1, 1, 3, 0)
			self.Config.JungleClear:addParam("Enabled", "Jungle Clear !", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
			
		self.Config:addSubMenu("Azir - Misc", "Misc")
			self.Config.Misc:addParam("GapCloser", "GapCloser", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('N'))
			self.Config.Misc:addParam("Escape", "Escape", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('G'))
			self.Config.Misc:addParam("AntiCapCloser", "AntiCapCloser", SCRIPT_PARAM_ONOFF, true)
			self.Config.Misc:addParam("Interrupt", "Interrupt", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu("Azir -  Draw", "Draw")
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
			
	AddTickCallback(function() self:Tick() end)
	AddDrawCallback(function() self:Draw() end)
	--AddAnimationCallback(function(unit, animation) self:Animation(unit, animation) end)
	AddProcessSpellCallback(function(unit, spell) self:ProcessSpell(unit, spell) end)
	--AddApplyBuffCallback(function(source, unit, buff) self:OnApplyBuff(source, unit, buff) end)
	--AddUpdateBuffCallback(function(unit, buff, stacks) self:UpdateBuff(unit, buff, stacks) end)
	--AddRemoveBuffCallback(function(unit, buff) self:OnRemoveBuff(unit, buff) end)
	AddCreateObjCallback(function(obj) self:CreateObj(obj) end)
	AddDeleteObjCallback(function(obj) self:DeleteObj(obj) end)
end

function Azir:Tick()
	if self.Config.Combo.Enabled then 
		self:Combo()
	elseif self.Config.Harass.Enabled then
		self:Harass()
	end
	if self.Config.Insec.Enabled then self:Insec() end
	if self.Config.Misc.GapCloser then self:GapCloser() end
	if self.Config.Misc.Escape then self:Dash(mousePos) end
	if self.Config.LineClear.Enabled then self:LineClear() end 
	if self.Config.JungleClear.Enabled then self:JungleClear() end 
	self.customSAR = self.AS.Range
	self:GetTargets()
end

function Azir:GetTargets()
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
	
	if self.Target and self.Target.team ~= myHero.team and self.Target.type == myHero.type and ValidTarget(self.Target, self.R.Range) then
		self.RTarget = self.Target
	else
		self.RTS:update()
		self.RTarget = self.RTS.target
	end
	
	if self.Target and self.Target.team ~= myHero.team and self.Target.type == myHero.type and ValidTarget(self.Target, self.E.Range) then
		self.ITarget = self.Target
	else
		self.QTS:update()
		self.ITarget = self.QTS.target
	end
end

function Azir:Combo()
	if self.Q.IsReady() and self.Config.Combo.UseQ and self.Config.Combo.UseQunder >= self:CanAASoldier(self.QTarget) and self.QTarget ~= nil then
		self:CastQ(self.QTarget)
	end
	if self.W.IsReady() and self.Config.Combo.UseW and self.QTarget ~= nil then
		if self.QTarget~= nil then
			self:CastW(self.QTarget)
		else
			self:CastW(self.WTarget)
		end
	end
end

function Azir:Harass()
	if self.Q.IsReady() and self.Config.Harass.UseQ and self.Config.Harass.UseQunder >= self:CanAASoldier(self.QTarget) then
		self:CastQ(self.QTarget)
	end
	if self.QTarget~= nil and self.Config.Harass.UseW and #self.AzirSoldier < self.Config.Harass.LimitAS then 
		self:CastW(self.QTarget)
	end
end

function Azir:LineClear()
	self.minionTable:update()
	for i, minion in pairs(self.minionTable.objects) do
		if minion ~= nil and not minion.dead then
			if self.Config.LineClear.UseQ and self.Q.IsReady() and #self.AzirSoldier > 0 then
				local bestpos, besthit = GetBestLineFarmPosition(self.Q.Range, 75, self.minionTable.objects, self.AzirSoldier[1])
				if besthit ~= nil and bestpos ~= nil then
					self:CastQ(bestpos)
				end
			end
			if self.Config.LineClear.UseW and #self.AzirSoldier < self.Config.LineClear.LimitAS and self.W.IsReady()then
				local bestpos, besthit = GetBestCircularFarmPosition(self.W.Range, self.customSAR, self.minionTable.objects)
				if besthit ~= nil and bestpos ~= nil then
					self:CastW(bestpos)
				end
			end
		end
	end
end

function Azir:JungleClear()
	self.jungleTable:update()
	for i, minion in pairs(self.jungleTable.objects) do
		if minion ~= nil and not minion.dead then
			if self.Config.JungleClear.UseQ and self.Q.IsReady() and #self.AzirSoldier > 0 then
				local bestpos, besthit = GetBestLineFarmPosition(self.Q.Range, 75, self.jungleTable.objects, self.AzirSoldier[1])
				if besthit ~= nil and bestpos ~= nil then
					self:CastQ(bestpos)
				end
			end
			if self.Config.JungleClear.UseW and #self.AzirSoldier < self.Config.JungleClear.LimitAS and self.W.IsReady() then
				local bestpos, besthit = GetBestCircularFarmPosition(self.W.Range, self.customSAR, self.jungleTable.objects)
				if besthit ~= nil and bestpos ~= nil then
					self:CastW(bestpos)
				end
			end
		end
	end
end

function Azir:GapCloser()
	Dash(self.Target)
end

function Azir:Dash(Pos)
	local Pos2 = Pos or mousePos
	if self.W.IsReady()and (#self.AzirSoldier == 0 or GetDistance(self:ClosetSoldier(Pos2), Pos2) > GetDistance(Pos2, myHero)) then
		self:CastW(Pos2)
	end
	if self.Q.IsReady() and self.E.IsReady() and #self.AzirSoldier > 0 then
		local etarget = self:ClosetSoldier(Pos2)
		if etarget ~= nil then
			self:CastE(etarget)
		end
	end
	if self.Q.IsReady() and not self.E.IsReady() then
		self:CastQ(Pos2)
	end
end

function Azir:Insec()
	if ValidTarget(self.ITarget, self.E.Range) and self.ITarget.team ~= myHero.team and self.ITarget.type == myHero.type then
		if self.Config.Insec.To == 1 then
			self.ToTarget = mousePos
		elseif self.Config.Insec.To == 2 then
			self.ToTarget = self:GetClosestAllyTower(2000)
		end
		
		if self.R.IsReady() then
			if self.ITarget ~= nil and self.ToTarget ~= nil then
				self.behindTarget = self:GetLocationBehindTarget(self.ITarget, self.ToTarget)
				if GetDistance(self.ITarget) < 250 then
					self:CastR(self.ToTarget)
				elseif GetDistance(self.ITarget) < self.Q.Range then
					self:Dash(self.ITarget)
				end
			else
				myHero:MoveTo(mousePos.x, mousePos.z)
			end
		else
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
	else
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function Azir:CastQ(Pos)
	if Pos then
		CastSpell(_Q, Pos.x, Pos.z)
	end
end

function Azir:CastW(Pos)
	if Pos then
		CastSpell(_W, Pos.x, Pos.z)
	end
end

function Azir:CastE(Pos)
	if Pos then
		CastSpell(_E, Pos.x, Pos.z)
	end
end

function Azir:CastR(Pos)
	if Pos then
		CastSpell(_R, Pos.x, Pos.z)
	end
end


function Azir:Draw()
	if myHero.dead then return end
	if self.Q.IsReady() and self.Config.Draw.DrawQ then
		DrawCircle(player.x, player.y, player.z, self.Q.Range, TARGB(self.Config.Draw.DrawQColor))
	end

	if self.W.IsReady() and self.Config.Draw.DrawW then
		DrawCircle(player.x, player.y, player.z, self.W.Range, TARGB(self.Config.Draw.DrawWColor))
	end

	if self.E.IsReady() and self.Config.Draw.DrawE then
		DrawCircle(player.x, player.y, player.z, self.E.Range, TARGB(self.Config.Draw.DrawEColor))
	end

	if self.R.IsReady() and self.Config.Draw.DrawR then
		DrawCircle(player.x, player.y, player.z, self.R.Range, TARGB(self.Config.Draw.DrawRColor))
	end
	
	if self.Config.Insec.DrawTarget and self.Config.Misc.Insec and self.ToTarget ~= nil and self.ITarget then
		DrawLine3D(myHero.x, myHero.y, myHero.z, self.ITarget.x, self.ITarget.y, self.ITarget.z, 2, RGBA(0, 255, 0, 254))
		DrawCircle3D(myHero.x, myHero.y, myHero.z, 10, 3, RGBA(0, 255, 0, 254), 100)
		DrawCircle3D(self.ITarget.x, self.ITarget.y, self.ITarget.z, 10, 3, RGBA(0, 255, 0, 254), 100)
		DrawLine3D(self.ToTarget.x, self.ToTarget.y, self.ToTarget.z, self.ITarget.x, self.ITarget.y, self.ITarget.z, 2, RGBA(0, 255, 0, 254))
	end
	if self.behindTarget ~= nil then
		DrawCircle(self.behindTarget.x, self.behindTarget.y, self.behindTarget.z, 100, Colors.Red)
	end
end

function Azir:ClosetSoldier(Pos)
	local target
	for unit, soldier in ipairs(self.AzirSoldier) do
		if target == nil then
			target = soldier
		elseif GetDistance(target, Pos) > GetDistance(soldier, Pos) and GetDistance(soldier) <= 2000 then
			target = soldier
		end
	end
	return target
end

function Azir:ProcessSpell(unit, spell)
	if #self.ToInterrupt > 0 then
		for _, ability in pairs(self.ToInterrupt) do
			if spell.name == ability and unit.team ~= player.team and GetDistance(unit) < self.R.Range and self.Config.Misc.Interrupt and self.R.IsReady() then
				CastE(unit)
			end
		end
	end
end

function Azir:CreateObj(obj)
	if obj ~= nil then
		if obj.name == "AzirSoldier" and obj.team == myHero.team then
			table.insert(self.AzirSoldier, obj)
		end
	end
end

function Azir:DeleteObj(obj)
	if obj ~= nil then
		if obj.name == "AzirSoldier" and obj.team == myHero.team then
			for unit, sold in pairs(self.AzirSoldier) do
				if sold == obj then
					table.remove(self.AzirSoldier, unit)
				end
			end
		end
	end
end

function Azir:CanAASoldier(target)
	local CanAANum = 0
	for unit, soldier in pairs(self.AzirSoldier) do
		if GetDistance(soldier, target) < self.customSAR then
			CanAANum = CanAANum + 1
		end
	end
	return CanAANum
end

function Azir:GetLocationBehindTarget(theTarget, toWhom)
	return theTarget + Vector(toWhom.x-theTarget.x,toWhom.y,toWhom.z-theTarget.z):normalized()*(GetDistance(toWhom,theTarget)+75)
end

function Azir:GetClosestAllyTower(maxRange)
	local theTower = nil;
	local towerDistance = maxRange;
	for I, allyTower in pairs(self:GetAllyTowers()) do
		local tempDistance = GetDistance(myHero, allyTower)
		if (tempDistance <= towerDistance) then
			towerDistance = tempDistance
			theTower = allyTower
		end
	end
	return theTower
end

function Azir:GetAllyTowers()
	local theTowers = {}
	for I = 1, objManager.maxObjects do
		local theTower = objManager:getObject(I)
		if ((theTower ~= nil) and (theTower.valid) and (theTower.type == 'obj_AI_Turret') and (theTower.visible) and (theTower.team == myHero.team)) then
			table.insert(theTowers, theTower)
		end
	end
	return theTowers
end

class('Varus')
function Varus:__init()

	OnOrbLoad()
	self.Q = {Range = 0, MinRange = 850, MaxRange = 1475, Offset = 0, Width = 100, Delay = 0.55, Speed = 1900, LastCastTime = 0, LastCastTime2 = 0, Collision = false, Aoe = true, IsReady = function() return myHero:CanUseSpell(_Q) == READY end, Mana = function() return myHero:GetSpellData(_Q).mana end, Damage = function(target) return getDmg("Q", target, myHero) end, IsCharging = false, TimeToStopIncrease = 1.5 , End = 4, SentTime = 0, LastFarmCheck = 0, Sent = false}
	self.E = {Range = 925, Speed = 1500, Width = 240, Delay = 0.251,IsReady = function() return myHero:CanUseSpell(_E) == READY end }
	self.R = {Range = 800, Speed = 1500, Width = 240, Delay = 0.251,IsReady = function() return myHero:CanUseSpell(_R) == READY end }
	
	
	self.HP_Q = HPSkillshot({type = "DelayLine", collisionM = false, collisionH = false, delay = self.Q.Delay, speed = self.Q.Speed, range = self.Q.MaxRange, width = self.Q.Width})
	self.HP_E = HPSkillshot({type = "DelayCircle", delay = self.E.Delay, speed = self.E.Speed, range = self.E.Speed, radius = self.Q.Width*2})
	
	self.DivineQ = LineSS(self.E.Speed, self.E.Range, self.E.Width, self.E.Delay, math.huge)
	self.DivineE = CircleSS(self.E.Speed, self.E.Range, self.E.Width, self.E.Delay, math.huge)
	
	self.Qbuff = {}
	
	for i, hero in ipairs(GetEnemyHeroes()) do
		buff = {unit = hero, stacks = 0}
		table.insert(self.Qbuff, buff)
	end
	
	self:LoadMenu()
	self.QTS = TargetSelector(TARGET_LESS_CAST, self.Q.MaxRange, DAMAGE_MAGIC, false)
end

function Varus:LoadMenu()
	self.Config = scriptConfig("Varus", "Varus")
		if SxOLoad then
			self.Config:addSubMenu("Orbwalking", "Orbwalking")
				SxO:LoadToMenu(self.Config.Orbwalking, Orbwalking)
		end
		
		self.Config:addSubMenu("Varus - Combo Setting", "Combo")
			self.Config.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseQstack", "Use Q Stack", SCRIPT_PARAM_SLICE, 2, 0, 3)
			self.Config.Combo:addParam("UseQKillable", "Use Q When Killable", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("Enable", "Enable", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			
		self.Config:addSubMenu("Varus - Harass Setting", "Harass")
			self.Config.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("UseQstack", "Use Q Stack", SCRIPT_PARAM_SLICE, 1, 0, 2)
			self.Config.Harass:addParam("Enable", "Enable", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
			
		self.Config:addSubMenu("Varus - Auto Setting", "Auto")
			self.Config.Auto:addParam("AutoR", "Auto Use R", SCRIPT_PARAM_ONOFF, true)
			self.Config.Auto:addParam("AutoRnum", "Auto R Near Enemy >=", SCRIPT_PARAM_SLICE, 2, 0, 2)
			self.Config.Auto:addParam("AutoAntiGapCloser", "Auto AntiGapCloser With R", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu("Varus - Misc Setting", "Misc")
			self.Config.Auto:addParam("ForceCastR", "Force Cast R", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
		
		self.Config:addSubMenu(myHero.charName.." Pred", "Pred")
			self.Config.Pred:addParam("QPred", "Q Prediction", SCRIPT_PARAM_LIST,1, SupPred)
			self.Config.Pred:addParam("EPred", "E Prediction", SCRIPT_PARAM_LIST,1, SupPred)
		
	AddTickCallback(function() self:Tick() end)
	AddProcessSpellCallback(function(unit, spell) self:ProcessSpell(unit, spell) end)
	AddApplyBuffCallback(function(source, unit, buff) self:OnApplyBuff(source, unit, buff) end)
	AddUpdateBuffCallback(function(unit, buff, stacks) self:OnUpdateBuff(unit, buff, stacks) end)
	AddRemoveBuffCallback(function(unit, buff) self:OnRemoveBuff(unit, buff) end)	
	AddDrawCallback(function() self:Draw() end)
end

function Varus:Tick()
	if self.Q.IsCharging and myHero:GetSpellData(_Q).currentCd > 1 then
		self.Q.IsCharging = false
	end
	if self.Config.Combo.Enable then
		self:Combo()
	elseif self.Config.Harass.Enabled then
		self:Harass()
	end
end

function Varus:Combo()
	self.QTS:update()
	if self.Config.Combo.UseQ then
		for i, Qbuff in ipairs(self.Qbuff) do
			if GetDistance(Qbuff.unit) < self.Q.MaxRange and Qbuff.stacks > 2 then
				self:CastQ(Qbuff.unit)
			end
			if myHero:GetSpellData(_W).level == 0 then
				self:CastQ(self.QTarget)
			end
		end
	end
end

function Varus:Harass()

end

function Varus:CastQ(target)
	if self.Q.IsReady() and ValidTarget(target) then
        if self.Q.IsCharging then
            self:CastQ1(target)
        else
            CastSpell(_Q, target.x, target.z)
        end
    end
end

function Varus:CastQ1(target)
	self.Qrange = math.min(self.Q.MinRange + (self.Q.MaxRange - self.Q.MinRange) * ((os.clock() - self.Q.LastCastTime) / self.Q.TimeToStopIncrease), self.Q.MaxRange)
	if self.Config.Pred.QPred == 1 then
		self.QPos, self.QHitChance = HP:GetPredict(self.HP_Q, target, myHero)
		if self.Qrange ~= self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange - 200)^2 or self.Qrange == self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange)^2 then
			if self.QPos and self.QHitChance >= 1.4 then
				self:CastQ2(self.QPos)
			end
		end
	elseif self.Config.Pred.QPred == 2 then
		local Target = DPTarget(target)
		local DivineQ = LineSS(self.Q.Speed, self.Q.MaxRange, self.Q.Width/2, self.Q.Delay, math.huge)
		DivineQ = dp:bind("DivineQ", DivineQ)
		self.Qstate, self.QPos, self.Prec = dp:predict("DivineQ", Target)
		if self.Qrange ~= self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange - 200)^2 or self.Qrange == self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange)^2 then
			if self.QPos and self.Qstate == SkillShot.STATUS.SUCCESS_HIT then
				self:CastQ2(self.QPos)
			end
		end
	elseif self.Config.Pred.QPred == 3 then
		self.QPos, self.QHitChance, self.PredPos = SP:Predict(target, self.Q.MaxRange, self.Q.Speed, self.Q.Delay, self.Q.Width, false, myHero)
		if self.Qrange ~= self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange - 200)^2 or self.Qrange == self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange)^2 then
			if self.QPos and self.QHitChance >= 1.4 then
				self:CastQ2(self.QPos)
			end
		end
	end
end

function Varus:CastQ2(Pos)
	if self.Q.IsReady() and Pos and self.Q.IsCharging then
        local d3vector = D3DXVECTOR3(Pos.x, Pos.y, Pos.z)
        self.Q.Sent = true
        CastSpell2(_Q, d3vector)
        self.Q.Sent = false
    end
end

function Varus:CastE(target)
	if target ~= nil then
		if self.Config.Pred.EPews == 1 then
			self.EPos, self.EHitChance = HP:GetPredict(self.HP_E, target, myHero)
			if self.EPos and self.EHitChance >= 0.8 then
				CastSpell(_E, self.EPos.x, self.EPos.z)
			end
		elseif self.Config.Pred.EPews == 2 then
			local Target = DPTarget(target)
			local DivineE = dp:bindSS("DivineE", self.DivineE)
			self.Estate, self.EPos, self.Prec = dp:predict("DivineE", Target)
			if self.EPos and self.Estate == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_E, self.EPos.x, self.EPos.z)
			end
		elseif self.Config.Pred.EPews == 3 then
			self.EPos, self.EHitChance, self.PredPos = SP:PredictPos(target, math.huge, self.E.Delay)
			if self.EPos and self.EHitChance >= 0.8 then
				CastSpell(_E, self.EPos.x, self.EPos.z)
			end
		end
	end
end

function Varus:CastR(target)
end

function Varus:Draw()
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
	
	if self.Qstate ~= nil then
		if self.Qstate == SkillShot.STATUS.MINION_HIT then
			self.Qcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		elseif self.Qstate == SkillShot.STATUS.HERO_HIT then
			self.Qcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.Qstate == SkillShot.STATUS.SUCCESS_HIT then
			self.Qcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
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
	
	if self.Estate ~= nil then
		if self.Estate == SkillShot.STATUS.MINION_HIT then
			self.Ecolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		elseif self.Estate == SkillShot.STATUS.HERO_HIT then
			self.Ecolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.Estate == SkillShot.STATUS.SUCCESS_HIT then
			self.Ecolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
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
end

function Varus:ProcessSpell(unit, spell)
	if myHero.dead or self.Config == nil or unit == nil or not unit.isMe then return end
	if spell.name:lower():find("varusq") then 
		self.Q.LastCastTime = os.clock()
		self.Q.IsCharging = true
	end
end

function Varus:OnApplyBuff(source, unit, buff)
	if buff.name == "varuswdebuff" then
		for i, Qbuff in ipairs(self.Qbuff) do
			if Qbuff.unit == unit then
				Qbuff.stacks = 1
			end
		end
	end
end

function Varus:OnUpdateBuff(unit, buff, stacks)
	if buff.name == "varuswdebuff" then
		for i, Qbuff in ipairs(self.Qbuff) do
			print(stacks)
			if Qbuff.unit == unit then
				Qbuff.stacks = stacks
			end
		end
	end
end

function Varus:OnRemoveBuff(unit, buff)
	if buff.name == "varuswdebuff" then
		for i, Qbuff in ipairs(self.Qbuff) do
			if Qbuff.unit == unit then
				Qbuff.stacks = 0
			end
		end
	end
end

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













