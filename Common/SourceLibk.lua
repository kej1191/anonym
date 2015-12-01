
--[[

      _________                                 .____    ._____.    
     /   _____/ ____  __ _________   ____  ____ |    |   |__\_ |__  
     \_____  \ /  _ \|  |  \_  __ \_/ ___\/ __ \|    |   |  || __ \ 
     /        (  <_> )  |  /|  | \/\  \__\  ___/|    |___|  || \_\ \
    /_______  /\____/|____/ |__|    \___  >___  >_______ \__||___  /
            \/                          \/    \/        \/       \/ 

    SourceLib - a common library by Team TheSource
    Copyright (C) 2014  Team TheSource

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/.


    Introduction:
        We were tired of updating every single script we developed so far so we decided to have it a little bit
        more dynamic with a custom library which we can update instead and every script using it will automatically
        be updated (of course only the parts which are in this lib). So let's say packet casting get's fucked up
        or we want to change the way some drawing is done, we just need to update it here and all scripts will have
        the same tweaks then.
		-- rework by kaokaoni
	
	Reworks:
		SourceUpdater	-- Better good
		Spell			-- Add Prediction, bug fix
		Interrupter		-- documented
		AntiGapCloser	-- documented
		
		
    Contents:
        Require         -- A basic but powerful library downloader
        SourceUpdater   -- One of the most basic functions for every script we use
        Spell           -- Spells handled the way they should be handled
        DrawManager     -- Easy drawing of all kind of things, comes along with some other classes such as Circle
        DamageLib       -- Calculate the damage done do others and even print it on their healthbar
        STS             -- SimpleTargetSelector is a simple and yet powerful target selector to provide very basic target selecting
        Interrupter     -- Easy way to handle interruptable spells
        AntiGetcloser   -- Never let them get close to you
	
	removed:
		MenuWrapper		-- No more use
		//STS
]]

_G.srcLib = {}
_G.srcLib.Menu = scriptConfig("[SourceLib]", "SourceLib")
_G.srcLib.version = 0.1
local autoUpdate = true

--[[

'||''|.                              ||                  
 ||   ||    ....    ... .  ... ...  ...  ... ..    ....  
 ||''|'   .|...|| .'   ||   ||  ||   ||   ||' '' .|...|| 
 ||   |.  ||      |.   ||   ||  ||   ||   ||     ||      
.||.  '|'  '|...' '|..'||   '|..'|. .||. .||.     '|...' 
                       ||                                
                      ''''                               

    Require - A simple library downloader

    Introduction:
        If you want to use this class you need to put this at the beginning of you script.

    Functions:
        Require(myName)

    Members:
        Require.downloadNeeded

    Methods:
        Require:Add(name, url)
        Require:Check()
		
	Example:
		if player.charName ~= "Brand" then return end
		require "SourceLib"

		local libDownloader = Require("Brand script")
		libDownloader:Add("VPrediction", "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua")
		libDownloader:Add("SOW",         "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua")
		libDownloader:Check()

		if libDownloader.downloadNeeded then return end
]]
class 'Require'
function __require_afterDownload(requireInstance)
    requireInstance.downloadCount = requireInstance.downloadCount - 1
    if requireInstance.downloadCount == 0 then
        print("<font color=\"#6699ff\"><b>" .. requireInstance.myName .. ":</b></font> <font color=\"#FFFFFF\">Required libraries downloaded! Please reload!</font>")
    end
end

function Require:__init(myName)
    self.myName = myName or GetCurrentEnv().FILE_NAME
    self.downloadNeeded = false
    self.requirements = {}
end
function Require:Add(name, url)
    assert(name and type(name) == "string" and url and type(url) == "string", "Require:Add(): Some or all arguments are invalid.")
    self.requirements[name] = url
    return self
end

function Require:Check()
    for scriptName, scriptUrl in pairs(self.requirements) do
        local scriptFile = LIB_PATH .. scriptName .. ".lua"
        if FileExist(scriptFile) then
            require(scriptName)
        else
            self.downloadNeeded = true
            self.downloadCount = self.downloadCount and self.downloadCount + 1 or 1
			print("<font color=\"#6699ff\"><b>" .. requireInstance.myName .. ":</b></font> <font color=\"#FFFFFF\">Missing Library! Downloading "..scriptName..". If the library doesn't download, please download it manually.!</font>")
            DownloadFile(scriptUrl, scriptFile, function() __require_afterDownload(self) end)
        end
    end
    return self
end

--[[

.|'''|                          '||`           '||   ||`             ||`           ||                  
||       ''                      ||             ||   ||              ||            ||                  
`|'''|,  ||  '||),,(|,  '||''|,  ||  .|''|,     ||   ||  '||''|, .|''||   '''|.  ''||''  .|''|, '||''| 
 .   ||  ||   || || ||   ||  ||  ||  ||..||     ||   ||   ||  || ||  ||  .|''||    ||    ||..||  ||    
 |...|' .||. .||    ||.  ||..|' .||. `|...      `|...|'   ||..|' `|..||. `|..||.   `|..' `|...  .||.   
                         ||                               ||                                           
                        .||                              .||                                           
						

    SimpleUpdater - a simple updater class

    Introduction:
        Scripts that want to use this class need to have a version field at the beginning of the script, like this:
            local version = YOUR_VERSION (YOUR_VERSION can either be a string a a numeric value!)
        It does not need to be exactly at the beginning, like in this script, but it has to be within the first 100
        chars of the file, otherwise the webresult won't see the field, as it gathers only about 100 chars

    Functions:
        SimpleUpdater(scriptName, version, host, updatePath, filePath, versionPath)

    Members:
        SimpleUpdater.silent | bool | Defines wheather to print notifications or not

    Methods:
        SimpleUpdater:SetSilent(silent)
        SimpleUpdater:CheckUpdate()

]]
class('SimpleUpdater')
--[[
    Create a new instance of SimpleUpdater

    @param scriptName  | string        | Name of the script which should be used when printed in chat
    @param version     | float/string  | Current version of the script
    @param host        | string        | Host, for example "bitbucket.org" or "raw.github.com"
    @param updatePath  | string        | Raw path to the script which should be updated
    @param filePath    | string        | Path to the file which should be replaced when updating the script
    @param versionPath | string        | (optional) Path to a version file to check against. The version file may only contain the version.
]]
function SimpleUpdater:__init(scriptName, version, host, updatePath, filePath, versionPath)

    self.printMessage = function(message) if not self.silent then print("<font color=\"#6699ff\"><b>" .. self.UPDATE_SCRIPT_NAME .. ":</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") end end
    self.getVersion = function(version) return tonumber(string.match(version or "", "%d+%.?%d*")) end

    self.UPDATE_SCRIPT_NAME = scriptName
    self.UPDATE_HOST = host
    self.UPDATE_PATH = updatePath .. "?rand="..math.random(1,10000)
    self.UPDATE_URL = "https://"..self.UPDATE_HOST..self.UPDATE_PATH

    -- Used for version files
    self.VERSION_PATH = versionPath and versionPath .. "?rand="..math.random(1,10000)
    self.VERSION_URL = versionPath and "https://"..self.UPDATE_HOST..self.VERSION_PATH

    self.UPDATE_FILE_PATH = filePath

    self.FILE_VERSION = self.getVersion(version)
    self.SERVER_VERSION = nil

    self.silent = false

end

--[[
    Allows or disallows the updater to print info about updating

    @param  | bool   | Message output or not
    @return | class  | The current instance
]]
function SimpleUpdater:SetSilent(silent)

    self.silent = silent
    return self

end

--[[
    Check for an update and downloads it when available
]]
function SimpleUpdater:CheckUpdate()

    local webResult = GetWebResult(self.UPDATE_HOST, self.VERSION_PATH or self.UPDATE_PATH)
    if webResult then
        if self.VERSION_PATH then
            self.SERVER_VERSION = webResult
        else
            self.SERVER_VERSION = string.match(webResult, "%s*local%s+version%s+=%s+.*%d+%.%d+")
        end
        if self.SERVER_VERSION then
            self.SERVER_VERSION = self.getVersion(self.SERVER_VERSION)
            if not self.SERVER_VERSION then
                print("SourceLib: Please contact the developer of the script \"" .. (GetCurrentEnv().FILE_NAME or "DerpScript") .. "\", since the auto updater returned an invalid version.")
                return
            end
            if self.FILE_VERSION < self.SERVER_VERSION then
                self.printMessage("New version available: v" .. self.SERVER_VERSION)
                self.printMessage("Updating, please don't press F9")
                DelayAction(function () DownloadFile(self.UPDATE_URL, self.UPDATE_FILE_PATH, function () self.printMessage("Successfully updated, please reload!") end) end, 2)
            else
                self.printMessage("You've got the latest version: v" .. self.SERVER_VERSION)
            end
        else
            self.printMessage("Something went wrong! Please manually update the script!")
        end
    else
        self.printMessage("Error downloading version info!")
    end

end

--[[

 .|'''.|                                           '||'  '|'               '||            .                   
 ||..  '    ...   ... ...  ... ..    ....    ....   ||    |  ... ...     .. ||   ....   .||.    ....  ... ..  
  ''|||.  .|  '|.  ||  ||   ||' '' .|   '' .|...||  ||    |   ||'  ||  .'  '||  '' .||   ||   .|...||  ||' '' 
.     '|| ||   ||  ||  ||   ||     ||      ||       ||    |   ||    |  |.   ||  .|' ||   ||   ||       ||     
|'....|'   '|..|'  '|..'|. .||.     '|...'  '|...'   '|..'    ||...'   '|..'||. '|..'|'  '|.'  '|...' .||.    
                                                              ||                                              
                                                             ''''                                             

	SourceUpdater - a simple updater class

	Introduction:
        Scripts that want to use this class need to have a version field at the beginning of the script, like this:
            local version = YOUR_VERSION (YOUR_VERSION can either be a string a a numeric value!)
        It does not need to be exactly at the beginning, like in this script, but it has to be within the first 100
        chars of the file, otherwise the webresult won't see the field, as it gathers only about 100 chars

    Functions:
        SourceUpdater(LocalVersion, UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
		
	Methods:
		SourceUpdater:SetScriptName(ScriptName)
	
	Example:
		ToUpdate = {}
		ToUpdate.Host = "raw.githubusercontent.com"
		ToUpdate.VersionPath = "/kej1191/anonym/master/KOM/MidKing/MidKing.version"
		ToUpdate.ScriptPath =  "/kej1191/anonym/master/KOM/MidKing/MidKing.lua"
		ToUpdate.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
		ToUpdate.CallbackUpdate = function(NewVersion, OldVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">Updated to "..NewVersion..". </b></font>") end
		ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">You have lastest version ("..OldVersion..")</b></font>") end
		ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
		ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">Error while Downloading. Please try again.</b></font>") end
		SourceUpdater(VERSION, true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
]]
class 'SourceUpdater'
function SourceUpdater:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
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
	self.ScriptName = nil
end
function SourceUpdater:print(str)
	print('<font color="#FFFFFF">'..os.clock()..': '..str)
end
function SourceUpdater:SetScriptName(ScriptName)
	self.ScriptName = ScriptName
end
function SourceUpdater:OnDraw()
	if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
		if self.ScriptName ~= nil then
			DrawText3D(self.ScriptName ,myHero.x,myHero.y,myHero.z+70, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
		end
		DrawText3D('Download Status: '..(self.DownloadStatus or 'Unknown'),myHero.x,myHero.y,myHero.z+50, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
	end
end
function SourceUpdater:CreateSocket(url)
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

function SourceUpdater:Base64Encode(data)
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
function SourceUpdater:GetOnlineVersion()
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
			if self.OnlineVersion == nil then
				if self.CallbackError and type(self.CallbackError) == 'function' then
					self.CallbackError()
				end
			end
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

function SourceUpdater:DownloadUpdate()
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

--[[

 .|'''.|                   '||  '||  
 ||..  '  ... ...    ....   ||   ||  
  ''|||.   ||'  || .|...||  ||   ||  
.     '||  ||    | ||       ||   ||  
|'....|'   ||...'   '|...' .||. .||. 
           ||                        
          ''''                       
		Spell - Handled with ease!

    Functions:
        Spell(spellId, menu, skillshotType, range, width, delay, speed, collision)

    Members:
        Spell.range          | float  | Range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.rangeSqr       | float  | Squared range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.packetCast     | bool   | Set packet cast state
        -- This only applies for skillshots
        Spell.sourcePosition | vector | From where the spell is casted, default: player
        Spell.sourceRange    | vector | From where the range should be calculated, default: player
        -- This only applies for AOE skillshots
        Spell.minTargetsAoe  | int    | Set minimum targets for AOE damage

    Methods:
        Spell:SetRange(range)
        Spell:SetSource(source)
        Spell:SetSourcePosition(source)
        Spell:SetSourceRange(source)

        Spell:SetSkillshot(skillshotType, width, delay, speed, collision)
        Spell:SetAOE(useAoe, radius, minTargetsAoe)

        Spell:SetCharged(spellName, chargeDuration, maxRange, timeToMaxRange, abortCondition)
        Spell:IsCharging()
        Spell:Charge()

        Spell:SetHitChance(hitChance)
        Spell:ValidTarget(target)

        Spell:GetPrediction(target)
        Spell:CastIfDashing(target)
        Spell:CastIfImmobile(target)
        Spell:Cast(param1, param2)

        Spell:AddAutomation(automationId, func)
        Spell:RemoveAutomation(automationId)
        Spell:ClearAutomations()

        Spell:TrackCasting(spellName)
        Spell:WillHitTarget()
        Spell:RegisterCastCallback(func)

        Spell:GetLastCastTime()

        Spell:IsInRange(target, from)
        Spell:IsReady()
        Spell:GetManaUsage()
        Spell:GetCooldown()
        Spell:GetLevel()
        Spell:GetName()
]]
class 'Spell'

-- Class related constants
SKILLSHOT_LINEAR   = 0
SKILLSHOT_CIRCULAR = 1
SKILLSHOT_CONE     = 2
SKILLSHOT_OTHER    = 3

-- Different SpellStates returned when Spell:Cast() is called
SPELLSTATE_TRIGGERED          = 0
SPELLSTATE_OUT_OF_RANGE       = 1
SPELLSTATE_LOWER_HITCHANCE    = 2
SPELLSTATE_COLLISION          = 3
SPELLSTATE_NOT_ENOUGH_TARGETS = 4
SPELLSTATE_NOT_DASHING        = 5
SPELLSTATE_DASHING_CANT_HIT   = 6
SPELLSTATE_NOT_IMMOBILE       = 7
SPELLSTATE_INVALID_TARGET     = 8
SPELLSTATE_NOT_TRIGGERED      = 9
SPELLSTATE_IS_READY			  = 10

local spellNum = 1
--[[
    New instance of Spell

    @param spellId       | int          | Spell ID (_Q, _W, _E, _R)
    @param menu          | scriptCofnig | (Sub)Menu to add the spell casting menu to
    @param range         | float        | Range of the spell
	@param range		 | float        | Range of the skillshot
	@param width		 | float 		| Width of the skillshot
	@param delay		 | float 		| Delay of the skillshot
	@param speed		 | float 		| Speed of the skillshot
	@param collision	 | bool			| (optional) Respect unit collision when casting
]]
function Spell:__init(spellId, menu, skillshotType, range, width, delay, speed, collision)
	assert(spellId ~= nil and range ~= nil and type(spellId) == "number" and type(range) == "number", "Spell: Can't initialize Spell without valid arguments.")
	DelayAction(function(menu)
		if (_G.srcLib.Prediction == nil) then
			_G.srcLib.Prediction = {}
			if FileExist(LIB_PATH .. "SPrediction.lua") and _G.srcLib.SP == nil then
				require("SPrediction")
				_G.srcLib.SP = SPrediction()
				table.insert(_G.srcLib.Prediction, "SPrediction")
			end
			if FileExist(LIB_PATH .. "VPrediction.lua") and _G.srcLib.VP == nil then
				require("VPrediction")
				_G.srcLib.VP = VPrediction()
				table.insert(_G.srcLib.Prediction, "VPrediction")
			end
			if FileExist(LIB_PATH .. "HPrediction.lua") and _G.srcLib.HP == nil then
				require("HPrediction")
				_G.srcLib.HP = HPrediction()
				table.insert(_G.srcLib.Prediction, "HPrediction")
			end
			if FileExist(LIB_PATH.."DivinePred.lua") and FileExist(LIB_PATH.."DivinePred.luac") and _G.srcLib.dp == nil then
				require "DivinePred"
				_G.srcLib.dp = DivinePred()
				table.insert(_G.srcLib.Prediction, "DivinePred")
			end
		end
		DelayAction(function(menu)
			menu = menu or scriptConfig("[SourceLib] SpellClass", "srcSpellClass")
				menu:addParam("predictionType", "Prediction Type", SCRIPT_PARAM_LIST, 1, _G.srcLib.Prediction)
				menu:addParam("packetCast", "Packet Cast", SCRIPT_PARAM_ONOFF, false)
				menu:addParam("Hitchance", "Hitchance", SCRIPT_PARAM_SLICE, 1.4, 0, 3, 1)
		end, 1, {menu})
	end, 1, {menu})
	self.spellId = spellId
	self.packetCast = packetCast or false
	
	if (not _G.srcLib.Menu.Spell) then
		_G.srcLib.Menu:addSubMenu("Spell dev menu", "Spell")
			_G.srcLib.Menu.Spell:addParam("Debug", "dev debug", SCRIPT_PARAM_ONOFF, false)
	end

	width = width or 0
	delay = delay or 0
	speed = speed or 0
	collision = collision or false
	
	self:SetRange(range)
	self:SetSource(myHero)
	self:SetSkillshot(skillshotType, width, delay, speed, collision)
	
	self._automations = {}
	self._spellNum = spellNum
	spellNum = spellNum+1
	self.predictionType = 1
	
	
	
	AddTickCallback(function()
        -- Prodiction found, apply value
        if _G.srcLib.spellMenu ~= nil then
            self:SetPredictionType(_G.srcLib.spellMenu.predictionType)
			self:SetPacketCast(_G.srcLib.spellMenu.packetCast)
			self.hitChance = _G.srcLib.spellMenu.Hitchance
        end
    end)
end
--[[
    Update the spell range with the new given value

    @param range | float | Range of the spell
    @return      | class | The current instance
]]
function Spell:SetRange(range)
    assert(range and type(range) == "number", "Spell: range is invalid")
    self.range = range
    self.rangeSqr = math.pow(range, 2)
    return self
end
--[[
    Update both the sourcePosition and sourceRange from where everything will be calculated

    @param source | Cunit | Source position, for example player
    @return       | class | The current instance
]]
function Spell:SetSource(source)
    assert(source, "Spell: source can't be nil!")
    self.sourcePosition = source
    self.sourceRange    = source
    return self
end
--[[
    Update the source posotion from where the spell will be shot

    @param source | Cunit | Source position from where the spell will be shot, player by default
    @ return      | class | The current instance
]]
function Spell:SetSourcePosition(source)
    assert(source, "Spell: source can't be nil!")
    self.sourcePosition = source
    return self
end
--[[
    Update the source unit from where the range will be calculated

    @param source | Cunit | Source object unit from where the range should be calculed
    @return       | class | The current instance
]]
function Spell:SetSourceRange(source)
    assert(source, "Spell: source can't be nil!")
    self.sourceRange = source
    return self
end
--[[
    Define this spell as skillshot (can't be reversed)

    @param skillshotType | int   | Type of this skillshot
    @param width         | float | Width of the skillshot
    @param delay         | float | (optional) Delay in seconds
    @param speed         | float | (optional) Speed in units per second
    @param collision     | bool  | (optional) Respect unit collision when casting
    @rerurn              | class | The current instance
]]
function Spell:SetSkillshot(skillshotType, width, delay, speed, collision)
    assert(skillshotType ~= nil, "Spell: Need at least the skillshot type!")
    self.skillshotType = skillshotType
	if (skillshotType ~= SKILLSHOT_OTHER) then
		self.width = width or 0
		self.delay = delay or 0
		self.speed = speed
		self.collision = collision or false
		self:HPSettings()
		self:DPSettings()
	end
    if not self.hitChance then self.hitChance = 2 end
    return self
end

function Spell:HPSettings()
	if self.HP ~= nil then
		if self.skillshotType == SKILLSHOT_LINEAR then
			if self.speed ~= math.huge then 
				if self.collision then
					self.HPSS = HPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay, collisionM = self.collision, collisionH = self.collision})
				else
					self.HPSS = HPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay})
				end
			else
				self.HPSS = HPSkillshot({type = "PromptLine", range = self.range, width = 2*self.width, delay = self.delay, collisionM = self.collision, collisionH = self.collision })
			end
		elseif self.skillshotType == SKILLSHOT_CIRCULAR then
			if self.speed ~= math.huge then 
				self.HPSS = HPSkillshot({type = "DelayCircle", range = self.range, speed = self.speed, radius = self.width, delay = self.delay})
			else
				self.HPSS = HPSkillshot({type = "PromptCircle", range = self.range, radius = self.width, delay = self.delay})
			end
		elseif self.skillshotType == SKILLSHOT_CONE then
			if self.speed ~= math.huge then 
				if self.collision then
					self.HPSS = HPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay, collisionM = self.collision, collisionH = self.collision})
				else
					self.HPSS = HPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay})
				end
			else
				self.HPSS = HPSkillshot({type = "PromptLine", range = self.range, width = 2*self.width, delay = self.delay, collisionM = self.collision, collisionH = self.collision})
			end
			-- not yet serport in sourcelib
			if self.delay == 0 then
				--self.HPSS = HPSkillshot({type ="PromptArc", collisionH = _collisionH, collisionM = _collisionM, speed = _speed, width = _width, range = _range, delay = _delay})
			else
				--self.HPSS = HPSkillshot({type ="DelayArc", collisionH = _collisionH, collisionM = _collisionM, speed = _speed, width = _width, range = _range, delay = _delay})
			end
		end
	end
end
--[[
]]
function Spell:DPSettings(skillshotType, range, width, delay, speed, collision)
	if self.dp ~= nil then
		local col = collision and ((myHero.charName=="Lux" or myHero.charName=="Veigar") and 1 or 0) or math.huge
		if self.skillshotType == SKILLSHOT_LINEAR then
			Spell = LineSS(spell.speed, spell.range, spell.width, spell.delay * 1000, col)
		elseif self.skillshotType == SKILLSHOT_CIRCULAR then
			Spell = CircleSS(spell.speed, spell.range, spell.width, spell.delay * 1000, col)
		elseif self.skillshotType == SKILLSHOT_CONE then
			Spell = coneSS(spell.speed, spell.range, spell.width, spell.delay * 1000, col)
		end
		_G.srcLib.dp:bindSS(SpellToString(self.spellId), Spell, 1)
	end
end
--[[
    Sets the prediction type

    @param typeId | int | type ID (VPrediction, SPrediction, DivinePred, HPrediction)
]]
function Spell:SetPredictionType(typeId)
    assert(typeId and type(typeId) == 'number', 'Spell:SetPredictionType(): typeId is invalid!')
    self.predictionType = typeId
end
function Spell:SetPacketCast(typebool)
    --assert(typebool and type(typebool) == 'bool', 'Spell:SetPacketCast(): typebool is invalid!')
    self.packetCast = typebool
end
--[[
    Set the AOE status of this spell, this can be changed later

    @param useAoe        | bool  | New AOE state
    @param radius        | float | Radius of the AOE damage
    @param minTargetsAoe | int   | Minimum targets to be hitted by the AOE damage
    @rerurn              | class | The current instance
]]
function Spell:SetAOE(useAoe, radius, minTargetsAoe)
	-- couse error
	--[[    self.useAoe = useAoe or false
    self.radius = radius or self.width
    self.minTargetsAoe = minTargetsAoe or 0
    return self
	]]
end
--[[
    Define this spell as charged spell

    @param spellName      | string   | Name of the spell, example: VarusQ
    @param chargeDuration | float    | Seconds of the spell to charge, after the time the charge expires
	@param minRange       | float    | Min range the spell will have start charging
    @param maxRange       | float    | Max range the spell will have after fully charging
    @param timeToMaxRange | float    | Time in seconds to reach max range after casting the spell
    @param abortCondition | function | (optional) A function which returns true when the charge process should be stopped.
]]
function Spell:SetCharged(spellName, chargeDuration, minRange, maxRange, timeToMaxRange, abortCondition)
    assert(self.skillshotType, "Spell:SetCharged(): Only skillshots can be defined as charged spells!")
    assert(spellName and type(spellName) == "string" and chargeDuration and type(chargeDuration) == "number", "Spell:SetCharged(): Some or all arguments are invalid!")
    assert(self.__charged == nil, "Spell:SetCharged(): Already marked as charged spell!")
    self.__charged           = true
    self.__charged_aborted   = true
    self.__charged_spellName = spellName
    self.__charged_duration  = chargeDuration
	self.__charged_initialRange = minRange
    self.__charged_maxRange       = maxRange
    self.__charged_chargeTime     = timeToMaxRange
    self.__charged_abortCondition = abortCondition or function () return false end
    self.__charged_active   = false
    self.__charged_castTime = 0
    -- Register callbacks
    if not self.__tickCallback then
        AddTickCallback(function() self:OnTick() end)
        self.__tickCallback = true
    end
	--[[
	Packet Error Close until fix
    
	if not self.__sendPacketCallback then
	    AddSendPacketCallback(function(p) self:OnSendPacket(p) end)
        self.__sendPacketCallback = true
    end
    ]]
	if not self.__processSpellCallback then
        AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        self.__processSpellCallback = true
    end
    return self
end
--[[
    Returns whether the spell is currently charging or not

    @return | bool | Spell charging or not
]]
function Spell:IsCharging()
    return self.__charged_abortCondition() == false and self.__charged_active
end
--[[
    Charges the spell
]]
function Spell:Charge()
    assert(self.__charged, "Spell:Charge(): Spell is not defined as chargeable spell!")
    if not self:IsCharging() then
        CastSpell(self.spellId, mousePos.x, mousePos.z)
    end
end
-- Internal function, do not use!
function Spell:_AbortCharge()
    if self.__charged and self.__charged_active then
        self.__charged_aborted = true
        self.__charged_active  = false
        self:SetRange(self.__charged_initialRange)
    end
end
--[[
    Set the hitChance of the predicted target position when to cast

    @param hitChance | int   | New hitChance for predicted positions
    @rerurn          | class | The current instance
]]
function Spell:SetHitChance(hitChance)
    self.hitChance = hitChance or 2
    return self
end
--[[
    Checks if the given target is valid for the spell

    @param target | userdata | Target to be checked if valid
    @return       | bool     | Valid target or not
]]
function Spell:ValidTarget(target, range)
    return ValidTarget(target, range or self.range)
end
--[[
    Returns the prediction results from VPrediction/Prodiction/SPrediction/HPrediction/DPrediction

    @return | various data | Prediction information
]]
function Spell:GetPrediction(target)
    if self.skillshotType ~= nil and _G.srcLib.Prediction ~= nil then
        -- VPrediction
        if _G.srcLib.Prediction[self.predictionType] == "VPrediction" then -- self.Prediction[self.predictionType] == "HPrediction"
            if self.skillshotType == SKILLSHOT_LINEAR then
                if self.useAoe then
                    return _G.srcLib.VP:GetLineAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return _G.srcLib.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    return _G.srcLib.VP:GetCircularAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return _G.srcLib.VP:GetCircularCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    return _G.srcLib.VP:GetConeAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return _G.srcLib.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
            end
        -- Prodiction
        elseif _G.srcLib.Prediction[self.predictionType] == "Prediction" then
            if self.useAoe then
                if self.skillshotType == SKILLSHOT_LINEAR then
                    local pos, info, objects = Prodiction.GetLineAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                    local pos, info, objects = Prodiction.GetCircularAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                 elseif self.skillshotType == SKILLSHOT_CONE then
                    local pos, info, objects = Prodiction.GetConeAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                end
            else
                local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                local hitChance = self.collision and info.collision() and -1 or info.hitchance
                return pos, hitChance, info.pos
            end

            -- Someday it will look the same as with VPrediction ;D
            --[[
            if self.skillshotType == SKILLSHOT_LINEAR then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetLineAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetCircularAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetConeAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
            end
            ]]
		--SPrediction <Someday rework after SP all done>
		elseif _G.srcLib.Prediction[self.predictionType] == "SPrediction" then
			if self.skillshotType == SKILLSHOT_LINEAR then
                return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
                else
                    return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
                else
                    return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
                end
            end
		--HPrediction <HTTF>
		elseif _G.srcLib.Prediction[self.predictionType] == "HPrediction" then
			if self.useAoe then
				return _G.srcLib.HP:GetPredict(self.HPSS, target, self.sourcePosition, true)
			else
				return _G.srcLib.HP:GetPredict(self.HPSS, target, self.sourcePosition)
			end
		--DivinePred <Divine>
		elseif _G.srcLib.Prediction[self.predictionType] == "DivinePred" then
			local Target = DPTarget(target)
			local fuck, the, divine = _G.srcLib.dp:predict(SpellToString(self.spellId), Target, self.sourcePosition)
			local you = -1
			if fuck == SkillShot.STATUS.SUCCESS_HIT then
				you = 3
			end
			return the, you, divine
        end
    end
end
--[[
    Tries to cast the spell when the target is dashing

    @param target | Cunit | Dashing target to attack
    @param return | int   | SpellState of the current spell
]]
function Spell:CastIfDashing(target)
    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then
		if _G.srcLib.Menu.Spell.Debug then
			print("SPELLSTATE_INVALID_TARGET")
		end
		return SPELLSTATE_INVALID_TARGET 
	end
    if self.skillshotType ~= nil then
        local isDashing, canHit, position = self.VP:IsDashing(target, self.delay + 0.07 + GetLatency() / 2000, self.width, self.speed, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_OUT_OF_RANGE")
			end
			return SPELLSTATE_OUT_OF_RANGE 
		end
        if isDashing and canHit then
            -- Collision
            if not self.collision or self.collision and not self.VP:CheckMinionCollision(target, position, self.delay + 0.07 + GetLatency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true) then
                return self:__Cast(self.spellId, position.x, position.z)
            else
				if _G.srcLib.Menu.Spell.Debug then
					print("SPELLSTATE_COLLISION")
				end
                return SPELLSTATE_COLLISION
            end
        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    else
        local isDashing, canHit, position = self.VP:IsDashing(target, 0.25 + 0.07 + GetLatency() / 2000, 1, math.huge, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end
        if isDashing and canHit then
            return self:__Cast(position.x, position.z)
        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    end
    return SPELLSTATE_NOT_TRIGGERED
end
--[[
    Tries to cast the spell when the target is immobile

    @param target | Cunit | Immobile target to attack
    @param return | int   | SpellState of the current spell
]]
function Spell:CastIfImmobile(target)
    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then return SPELLSTATE_INVALID_TARGET end
    if self.skillshotType ~= nil then
        local isImmobile, position = self.VP:IsImmobile(target, self.delay + 0.07 + GetLatency() / 2000, self.width, self.speed, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end
        if isImmobile then
            -- Collision
            if not self.collision or (self.collision and not self.VP:CheckMinionCollision(target, position, self.delay + 0.07 + GetLatency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true)) then
                return self:__Cast(position.x, position.z)
            else
                return SPELLSTATE_COLLISION
            end
        else return SPELLSTATE_NOT_IMMOBILE end
    else
        local isImmobile, position = self.VP:IsImmobile(target, 0.25 + 0.07 + GetLatency() / 2000, 1, math.huge, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, target) then return SPELLSTATE_OUT_OF_RANGE end
        if isImmobile then
            return self:__Cast(target)
        else
            return SPELLSTATE_NOT_IMMOBILE
        end
    end
    return SPELLSTATE_NOT_TRIGGERED
end
--[[
    Cast the spell, respecting previously made decisions about skillshots and AOE stuff

    @param param1 | userdata/float | When param2 is nil then this can be the target object, otherwise this is the X coordinate of the skillshot position
    @param param2 | float          | Z coordinate of the skillshot position
    @param return | int            | SpellState of the current spell
]]
function Spell:Cast(param1, param2)
	local castPosition, hitChance, position, nTargets = nil, nil, nil, nil
    if self.skillshotType ~= nil and param1 ~= nil and param2 == nil then
        -- Don't calculate stuff when target is invalid
        if not ValidTarget(param1) then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_INVALID_TARGET")
			end
			return SPELLSTATE_INVALID_TARGET 
		end
		-- Is ready
		--[[
		
		if self:IsReady() then
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_IS_READY")
			end
			return SPELLSTATE_IS_READY 
		end
		
		]]
        if self.skillshotType == SKILLSHOT_LINEAR or self.skillshotType == SKILLSHOT_CONE then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if self.range < GetDistance(self.sourceRange, castPosition) then
					if _G.srcLib.Menu.Spell.Debug then
						print("SPELLSTATE_OUT_OF_RANGE")
					end
					return SPELLSTATE_OUT_OF_RANGE 
				end
            end
        elseif self.skillshotType == SKILLSHOT_CIRCULAR then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if self.range + self.width + GetDistance(param1.minBBox) < GetDistance(self.sourceRange, castPosition) then 
					if _G.srcLib.Menu.Spell.Debug then
						print("SPELLSTATE_OUT_OF_RANGE")
					end
					return SPELLSTATE_OUT_OF_RANGE 
				end
            end
        end
        -- Validation (for Prodiction)
        if not castPosition then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_NOT_TRIGGERED")
			end
			return SPELLSTATE_NOT_TRIGGERED
		end
        -- AOE not enough targets
        if nTargets and nTargets < self.minTargetsAoe then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_NOT_ENOUGH_TARGETS")
			end
			return SPELLSTATE_NOT_ENOUGH_TARGETS 
		end
        -- Collision detected
        if self.collision and hitChance < 0 then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_COLLISION")
			end
			return SPELLSTATE_COLLISION 
		end
        -- Hitchance too low
        if hitChance and hitChance < self.hitChance then 
			if _G.srcLib.Menu.Spell.Debug then
				print(hitChance .." "..self.hitChance)
				print("SPELLSTATE_LOWER_HITCHANCE")
			end
			return SPELLSTATE_LOWER_HITCHANCE 
		end
        -- Out of range
		
		if self.range < GetDistance(self.sourceRange, castPosition) then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_OUT_OF_RANGE")
			end
			return SPELLSTATE_OUT_OF_RANGE 
		end
		
        param1 = castPosition.x
        param2 = castPosition.z
    end
    -- Cast charged spell
    if castPosition ~= nil and self.__charged and self:IsCharging() then
		print(tostring(GetDistance(castPosition) < (self.range)) .. " " .. tostring(GetDistance(castPosition) < (self.range)))
		if self.range ~= self.__charged_maxRange and GetDistance(castPosition) < (self.range) or self.range == self.__charged_maxRange and GetDistance(castPosition) < (self.range) then
			local d3vector = D3DXVECTOR3(castPosition.x, castPosition.y, castPosition.z)
			CastSpell2(self.spellId, d3vector)
		end
		if _G.srcLib.Menu.Spell.Debug then
			print("SPELLSTATE_TRIGGERED")
		end
        return SPELLSTATE_TRIGGERED
    end
    -- Cast the spell
	if _G.srcLib.Menu.Spell.Debug then
		print("SPELLSTATE_CALL_CASTSPELL")
	end
    return self:__Cast(param1, param2)
end
--[[
    Internal function, do not use this!
]]
function Spell:__Cast(param1, param2)
    if self.packetCast then
        if param1 ~= nil and param2 ~= nil then
            if type(param1) ~= "number" and type(param2) ~= "number" and VectorType(param1) and VectorType(param2) then
                Packet("S_CAST", {spellId = self.spellId, toX = param2.x, toY = param2.z, fromX = param1.x, fromY = param1.z}):send()
            else
                Packet("S_CAST", {spellId = self.spellId, toX = param1, toY = param2, fromX = param1, fromY = param2}):send()
            end
        elseif param1 ~= nil then
            Packet("S_CAST", {spellId = self.spellId, toX = param1.x, toY = param1.z, fromX = param1.x, fromY = param1.z, targetNetworkId = param1.networkID}):send()
        else
            Packet("S_CAST", {spellId = self.spellId, toX = player.x, toY = player.z, fromX = player.x, fromY = player.z, targetNetworkId = player.networkID}):send()
        end
    else
        if param1 ~= nil and param2 ~= nil then
            if type(param1) ~= "number" and type(param2) ~= "number" and VectorType(param1) and VectorType(param2) then
                --Packet("S_CAST", {spellId = self.spellId, toX = param2.x, toY = param2.z, fromX = param1.x, fromY = param1.z}):send()
				CastSpell(self.spellId, param1, param2)
            else
                CastSpell(self.spellId, param1, param2)
            end
        elseif param1 ~= nil then
            CastSpell(self.spellId, param1)
        else
            CastSpell(self.spellId)
        end
    end
    return SPELLSTATE_TRIGGERED
end
--[[
    Add an automation to the spell to let it cast itself when a certain condition is met

    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
    @param func         | function   | Function to be called when checking, should return a bool value indicating if it should be casted and optionally the cast params (ex: target or x and z)
]]
function Spell:AddAutomation(automationId, func)
    assert(automationId, "Spell: automationId is invalid!")
    assert(func and type(func) == "function", "Spell: func is invalid!")
    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then return end
    end
    table.insert(self._automations, { id == automationId, func = func })
    -- Register callbacks
    if not self.__tickCallback then
        AddTickCallback(function() self:OnTick() end)
        self.__tickCallback = true
    end
end
--[[
    Remove and automation by it's id

    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
]]
function Spell:RemoveAutomation(automationId)
    assert(automationId, "Spell: automationId is invalid!")
    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then
            table.remove(self._automations, index)
            break
        end
    end
end
--[[
    Clear all automations assinged to this spell
]]
function Spell:ClearAutomations()
    self._automations = {}
end
--[[
    Track the spell like in OnProcessSpell to add more features to this Spell instance

    @param spellName | string/table | Case insensitive name(s) of the spell
    @return          | class        | The current instance
]]
function Spell:TrackCasting(spellName)
    assert(spellName, "Spell:TrackCasting(): spellName is invalid!")
    assert(self.__tracked_spellNames == nil, "Spell:TrackCasting(): This spell is already tracked!")
    assert(type(spellName) == "string" or type(spellName) == "table", "Spell:TrackCasting(): Type of spellName is invalid: " .. type(spellName))
    self.__tracked_spellNames = type(spellName) == "table" and spellName or { spellName }
    -- Register callbacks
    if not self.__processSpellCallback then
        AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        self.__processSpellCallback = true
    end
    return self
end
--[[
    When the spell is casted and about to hit a target, this will return the following
	
	@param name  | string      | Name of the object
	@param width | int		   | Width of the object
	@param type  | string	   | Type of the object
    @return		 | CUnit,float | The target unit, the remaining time in seconds it will take to hit the target, otherwise nil
]]
function Spell:WillHitTarget(name, width, _type)
	local _type = _type or "missileclient"
    for i = 1, objManager.iCount, 1 do
        local obj = objManager:getObject(i)
        if obj ~= nil and obj.spellName == name and obj.type == _type then
			local Pos = Vector(obj);
			for index, hero in GetEnemyHeroes() do
				if hero and GetDistanceSqr(hero, Pos) < width then
					return
				end
			end
		end
	end
	return false
end
--[[
    Register a function which will be triggered when the spell is being casted the function will be given the spell object as parameter

    @param func | function | Function to be called when the spell is being processed (casted)
]]
function Spell:RegisterCastCallback(func)
    assert(func and type(func) == "function" and self.__tracked_castCallback == nil, "Spell:RegisterCastCallback(): func is either invalid or a callback is already registered!")
    self.__tracked_castCallback = func
end
--[[
    Get if the target is in range
	
    @return | bool | In range or not
]]
function Spell:IsInRange(target, from)
    return self.rangeSqr >= _GetDistanceSqr(target, from or self.sourcePosition)
end
--[[
    Get if the spell is ready or not

    @return | bool | Spell state ready or not
]]
function Spell:IsReady()
    return player:CanUseSpell(self.spellId) == READY
end
--[[
    Get the mana usage of the spell

    @return | float | Mana usage of the spell
]]
function Spell:GetManaUsage()
    return player:GetSpellData(self.spellId).mana
end
--[[
    Get the CURRENT cooldown of the spell

    @return | float | Current cooldown of the spell
]]
function Spell:GetCooldown(current)
    return current and player:GetSpellData(self.spellId).currentCd or player:GetSpellData(self.spellId).totalCooldown
end
--[[
    Get the stat points assinged to this spell (level)

    @return | int | Stat points assinged to this spell (level)
]]
function Spell:GetLevel()
    return player:GetSpellData(self.spellId).level
end
--[[
    Get the name of the spell

    @return | string | Name of the the spell
]]
function Spell:GetName()
    return player:GetSpellData(self.spellId).name
end
--[[
    Get the damage of the spell

    @return | string | Name of the the spell
]]
function Spell:GetName()
    return player:GetSpellData(self.spellId).name
end
--[[
    Internal callback, don't use this!
]]
function Spell:OnTick()
    -- Automations
    if self._automations and #self._automations > 0 then
        for _, automation in ipairs(self._automations) do
            local doCast, param1, param2 = automation.func()
            if doCast == true then
                self:Cast(param1, param2)
            end
        end
    end
    -- Charged spells
    if self.__charged then
        if self:IsCharging() then
            self:SetRange(math.min(self.__charged_initialRange + (self.__charged_maxRange - self.__charged_initialRange) * ((os.clock() - self.__charged_castTime) / self.__charged_chargeTime), self.__charged_maxRange))
        elseif not self.__charged_aborted and os.clock() - self.__charged_castTime > 0.1 then
            self:_AbortCharge()
        end
    end

end

--[[
    Internal callback, don't use this!
]]
function Spell:OnProcessSpell(unit, spell)
    if unit and unit.valid and unit.isMe and spell and spell.name then
        -- Tracked spells
        if self.__tracked_spellNames then
            for _, trackedSpell in ipairs(self.__tracked_spellNames) do
                if trackedSpell:lower() == spell.name:lower() then
                    self.__tracked_lastCastTime = os.clock()
                    self.__tracked_castCallback(spell)
                end
            end
        end
        -- Charged spells
        if self.__charged and self.__charged_spellName:lower() == spell.name:lower() then
            self.__charged_active       = true
            self.__charged_aborted      = false
            self.__charged_castTime     = os.clock()
            self.__charged_count        = self.__charged_count and self.__charged_count + 1 or 1
            DelayAction(function(chargeCount)
                if self.__charged_count == chargeCount then
                    self:_AbortCharge()
                end
            end, self.__charged_duration, { self.__charged_count })
        end
    end
end

--[[
    Internal callback, don't use this!
]]
function Spell:OnSendPacket(p)

    -- Charged spells
    if self.__charged then
        if p.header == 230 then
            if os.clock() - self.__charged_castTime <= 0.1 then
                p:Block()
            end
        elseif p.header == Packet.headers.S_CAST then
            local packet = Packet(p)
            if packet:get("spellId") == self.spellId then
                if os.clock() - self.__charged_castTime <= self.__charged_duration then
                    self:_AbortCharge()
                    local newPacket = CLoLPacket(230)
                    newPacket:EncodeF(player.networkID)
                    newPacket:Encode1(0x80)
                    newPacket:EncodeF(mousePos.x)
                    newPacket:EncodeF(mousePos.y)
                    newPacket:EncodeF(mousePos.z)
                    SendPacket(newPacket)
                    p:Block()
                end
            end
        end
    end

end

function Spell:__eq(other)

    return other and other._spellNum and other._spellNum == self._spellNum or false

end

--[[

'||''|.                                              '||'       ||  '||      
 ||   ||   ....   .. .. ..    ....     ... .   ....   ||       ...   || ...  
 ||    || '' .||   || || ||  '' .||   || ||  .|...||  ||        ||   ||'  || 
 ||    || .|' ||   || || ||  .|' ||    |''   ||       ||        ||   ||    | 
.||...|'  '|..'|' .|| || ||. '|..'|'  '||||.  '|...' .||.....| .||.  '|...'  
                                     .|....'                                 

    DamageLib - Holy cow, so precise!

    Functions:
        DamageLib(source)

    Members:
        DamageLib.source | Cunit | Source unit for which the damage should be calculated

    Methods:
        DamageLib:RegisterDamageSource(spellId, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)
        DamageLib:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)
        DamageLib:GetTrueDamage(target, spell, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)
        DamageLib:CalcSpellDamage(target, spell)
        DamageLib:CalcComboDamage(target, combo)
        DamageLib:IsKillable(target, combo)
        DamageLib:AddToMenu(menu, combo)

    -Available spells by default (not added yet):
        _AA: Returns the auto-attack damage.
        _IGNITE: Returns the ignite damage.
        _ITEMS: Returns the damage dealt by all the items actives.

    -Damage types:
        _MAGIC
        _PHYSICAL
        _TRUE

    -Scaling types: _AP, _AD, _BONUS_AD, _HEALTH, _ARMOR, _MR, _MAXHEALTH, _MAXMANA 
]]
class 'DamageLib'

--Damage types
_MAGIC, _PHYSICAL, _TRUE = 0, 1, 2

--Percentage scale type's 
_AP, _AD, _BONUS_AD, _HEALTH, _ARMOR, _MR, _MAXHEALTH, _MAXMANA = 1, 2, 3, 4, 5, 6, 7, 8

--Percentage scale functions
local _ScalingFunctions = {
    [_AP] = function(x, y) return x * y.source.ap end,
    [_AD] = function(x, y) return x * y.source.totalDamage end,
    [_BONUS_AD] = function(x, y) return x * y.source.addDamage end,
    [_ARMOR] = function(x, y) return x * y.source.armor end,
    [_MR] = function(x, y) return x * y.source.magicArmor end,
    [_MAXHEALTH] = function(x, y) return x * y.source.maxHeath end,
    [_MAXMANA] = function(x, y) return x * y.source.maxMana end,
}

--[[
    New instance of DamageLib

    @param source | Cunit | Source unit (attacker, player by default)
]]
function DamageLib:__init(source)

    self.sources = {}
    self.source = source or player

    --Damage multiplicators:
    self.Magic_damage_m    = 1
    self.Physical_damage_m = 1

    -- Most common damage sources
    self:RegisterDamageSource(_IGNITE, _TRUE, 0, 0, _TRUE, _AP, 0, function() return _IGNITE and (self.source:CanUseSpell(_IGNITE) == READY) end, function() return (50 + 20 * self.source.level) end)
    self:RegisterDamageSource(ItemManager:GetItem("DFG"):GetId(), _MAGIC, 0, 0, _MAGIC, _AP, 0, function() return ItemManager:GetItem("DFG"):GetSlot() and (self.source:CanUseSpell(ItemManager:GetItem("DFG"):GetSlot()) == READY) end, function(target) return 0.15 * target.maxHealth end)
    self:RegisterDamageSource(ItemManager:GetItem("BOTRK"):GetId(), _MAGIC, 0, 0, _MAGIC, _AP, 0, function() return ItemManager:GetItem("BOTRK"):GetSlot() and (self.source:CanUseSpell(ItemManager:GetItem("BOTRK"):GetSlot()) == READY) end, function(target) return 0.15 * target.maxHealth end)
    self:RegisterDamageSource(_AA, _PHYSICAL, 0, 0, _PHYSICAL, _AD, 1)

end

--[[
    Register a new spell

    @param spellId        | int      | (unique) Spell id to add.
    
    @param damagetype     | int      | The type(s) of the base and perlevel damage (_MAGIC, _PHYSICAL, _TRUE).
    @param basedamage     | int      | Base damage(s) of the spell.
    @param perlevel       | int      | Damage(s) scaling per level.

    @param scalingtype    | int      | Type(s) of the percentage scale (_MAGIC, _PHYSICAL, _TRUE).
    @param scalingstat    | int      | Stat(s) that the damage scales with.
    @param percentscaling | int      | Percentage(s) the stat scales with.

    @param condition      | function | (optional) A function that returns true / false depending if the damage will be taken into account or not, the target is passed as param.
    @param extra          | function | (optional) A function returning extra damage, the target is passed as param.
    
    -Example Spells: 
    Teemo Q:  80 / 125 / 170 / 215 / 260 (+ 80% AP) (MAGIC)
    DamageLib:RegisterDamageSource(_Q, _MAGIC, 35, 45, _MAGIC, _AP, 0.8, function() return (player:CanUseSpell(_Q) == READY) end)

    Akalis E: 30 / 55 / 80 / 105 / 130 (+ 30% AP) (+ 60% AD) (PHYSICAL) 
    DamageLib:RegisterDamageSource(_E, _PHYSICAL, 5, 25, {_PHYSICAL,_PHYSICAL}, {_AP, _AD}, {0.3, 0.6}, function() return (player:GetSpellData(_Q).currentCd < 2) or (player:CanUseSpell(_Q) == READY) end)

    * damagetype, basedamage, perlevel and scalingtype, scalingstat, percentscaling can be tables if there are 2 or more damage types.
]]
function DamageLib:RegisterDamageSource(spellId, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)

    condition = condition or function() return true end
    if spellId then
        self.sources[spellId] = {damagetype = damagetype, basedamage = basedamage, perlevel = perlevel, condition = condition, extra = extra, scalingtype = scalingtype, percentscaling = percentscaling, scalingstat = scalingstat}
    end

end

function DamageLib:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)

    local amount = (_ScalingFunctions[scalingstat] or function() return 0 end)(percentscaling, self)

    if scalingtype == _MAGIC then
        return self.Magic_damage_m * self.source:CalcMagicDamage(target, amount)
    elseif scalingtype == _PHYSICAL then
        return self.Physical_damage_m * self.Physical_damage_m * self.source:CalcDamage(target, amount)
    elseif scalingtype == _TRUE then
        return amount
    end

    return 0

end

function DamageLib:GetTrueDamage(target, spell, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)

    basedamage = basedamage or 0
    perlevel = perlevel or 0
    condition = condition(target)
    scalingtype = scalingtype or 0
    scalingstat = scalingstat or _AP
    percentscaling = percentscaling or 0
    extra = extra or function() return 0 end
    local ScalingDamage = 0

    if not condition then return 0 end

    if type(scalingtype) == "number" then
        ScalingDamage = ScalingDamage + self:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)
    elseif type(scalingtype) == "table" then
        for i, v in ipairs(scalingtype) do
            ScalingDamage = ScalingDamage + self:GetScalingDamage(target, scalingtype[i], scalingstat[i], percentscaling[i])
        end
    end

    if damagetype == _MAGIC then
        return self.Magic_damage_m * self.source:CalcMagicDamage(target, basedamage + perlevel * self.source:GetSpellData(spell).level + extra(target)) + ScalingDamage
    end
    if damagetype == _PHYSICAL then
        return self.Physical_damage_m * self.source:CalcDamage(target, basedamage + perlevel * self.source:GetSpellData(spell).level + extra(target)) + ScalingDamage
    end
    if damagetype == _TRUE then
        return basedamage + perlevel * self.source:GetSpellData(spell).level + extra(target) + ScalingDamage
    end

    return 0

end

function DamageLib:CalcSpellDamage(target, spell)

    if not spell then return 0 end
    local spelldata = self.sources[spell]
    local result = 0
    assert(spelldata, "DamageLib: The spell has to be added first!")

    local _type = type(spelldata.damagetype)

    if _type == "number" then
        result = self:GetTrueDamage(target, spell, spelldata.damagetype, spelldata.basedamage, spelldata.perlevel, spelldata.scalingtype, spelldata.scalingstat, spelldata.percentscaling, spelldata.condition, spelldata.extra)
    elseif _type == "table" then
        for i = 1, #spelldata.damagetype, 1 do                 
            result = result + self:GetTrueDamage(target, spell, spelldata.damagetype[i], spelldata.basedamage[i], spelldata.perlevel[i], 0, 0, 0, spelldata.condition)
        end
        result = result + self:GetTrueDamage(target, spell, 0, 0, 0, spelldata.scalingtype, spelldata.scalingstat, spelldata.percentscaling, spelldata.condition, spelldata.extra)
    end

    return result

end

function DamageLib:CalcComboDamage(target, combo)

    local totaldamage = 0

    for i, spell in ipairs(combo) do
        if spell == ItemManager:GetItem("DFG"):GetId() and ItemManager:GetItem("DFG"):IsReady() then
            self.Magic_damage_m = 1.2
        end
    end

    for i, spell in ipairs(combo) do
        totaldamage = totaldamage + self:CalcSpellDamage(target, spell)
    end

    self.Magic_damage_m = 1

    return totaldamage

end

--[[
    Returns if the unit will die after taking the combo damage.

    @param target | Cunit | Target.
    @param combo  | table | The combo table.
]]
function DamageLib:IsKillable(target, combo)
    return target.health <= self:CalcComboDamage(target, combo)
end

--[[
    Adds the Health bar indicators to the menu.

    @param menu  | scriptConfig | AllClass menu or submenu instance.
    @param combo | table        | The combo table.
]]
function DamageLib:AddToMenu(menu, combo)

    self.menu = menu
    self.combo = combo
    self.ticklimit = 5 --5 ticks per seccond
    self.barwidth = 100
    self.cachedDamage = {}
    menu:addParam("DrawPredictedHealth", "Draw damage after combo.", SCRIPT_PARAM_ONOFF , true)
    self.enabled = menu.DrawPredictedHealth
    AddTickCallback(function() self:OnTick() end)
    AddDrawCallback(function() self:OnDraw() end)

end

function DamageLib:OnTick()

    if not self.menu["DrawPredictedHealth"] then return end
    self.lasttick = self.lasttick or 0
    if os.clock() - self.lasttick > 1 / self.ticklimit then
        self.lasttick = os.clock()
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy) then
                self.cachedDamage[enemy.hash] = self:CalcComboDamage(enemy, self.combo)
            end
        end
    end

end

function DamageLib:OnDraw()

    if not self.menu["DrawPredictedHealth"] then return end
    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy) then
            self:DrawIndicator(enemy)
        end
    end

end

function DamageLib:DrawIndicator(enemy)

    local damage = self.cachedDamage[enemy.hash] or 0
    local SPos, EPos = GetEnemyHPBarPos(enemy)

    -- Validate data
    if not SPos then return end

    local barwidth = EPos.x - SPos.x
    local Position = SPos.x + math.max(0, (enemy.health - damage) / enemy.maxHealth) * barwidth

    DrawText("|", 16, math.floor(Position), math.floor(SPos.y + 8), ARGB(255,0,255,0))
    DrawText("HP: "..math.floor(enemy.health - damage), 13, math.floor(SPos.x), math.floor(SPos.y), (enemy.health - damage) > 0 and ARGB(255, 0, 255, 0) or  ARGB(255, 255, 0, 0))

end

--[[

 .|'''.|  |''||''|  .|'''.|  
 ||..  '     ||     ||..  '  
  ''|||.     ||      ''|||.  
.     '||    ||    .     '|| 
|'....|'    .||.   |'....|'  

    Simple Target Selector (STS) - Why using the regular one when you can have it even more simple.
	
	Introduction:
        Use targetselector more simply

    Functions:
        SimpleTS(mode)

    Methods:
        SimpleTS:AddToMenu(menu)
        SimpleTS:GetTarget(range, n, forcemode)
]]
class 'SimpleTS'

function STS_GET_PRIORITY(target)
    if not STS_MENU or not STS_MENU.STS[target.hash] then
        return 1
    else
        return STS_MENU.STS[target.hash]
    end
end

STS_MENU = nil
STS_NEARMOUSE                     = {id = 1, name = "Near mouse", sortfunc = function(a, b) return _GetDistanceSqr(mousePos, a) < _GetDistanceSqr(mousePos, b) end}
STS_LESS_CAST_MAGIC               = {id = 2, name = "Less cast (magic)", sortfunc = function(a, b) return (player:CalcMagicDamage(a, 100) / a.health) > (player:CalcMagicDamage(b, 100) / b.health) end}
STS_LESS_CAST_PHYSICAL            = {id = 3, name = "Less cast (physical)", sortfunc = function(a, b) return (player:CalcDamage(a, 100) / a.health) > (player:CalcDamage(b, 100) / b.health) end}
STS_PRIORITY_LESS_CAST_MAGIC      = {id = 4, name = "Less cast priority (magic)", sortfunc = function(a, b) return STS_GET_PRIORITY(a) * (player:CalcMagicDamage(a, 100) / a.health) > STS_GET_PRIORITY(b) * (player:CalcMagicDamage(b, 100) / b.health) end}
STS_PRIORITY_LESS_CAST_PHYSICAL   = {id = 5, name = "Less cast priority (physical)", sortfunc = function(a, b) return STS_GET_PRIORITY(a) * (player:CalcDamage(a, 100) / a.health) > STS_GET_PRIORITY(b) * (player:CalcDamage(b, 100) / b.health) end}
STS_AVAILABLE_MODES = {STS_NEARMOUSE, STS_LESS_CAST_MAGIC, STS_LESS_CAST_PHYSICAL, STS_PRIORITY_LESS_CAST_MAGIC, STS_PRIORITY_LESS_CAST_PHYSICAL}
--[[
	Create a new instance of TargetSelector
	
	@param mode | mode | Mode of the TargetSelector
]]
function SimpleTS:__init(mode)
    self.mode = mode and mode or STS_LESS_CAST_PHYSICAL
    AddDrawCallback(function() self:OnDraw() end)
    AddMsgCallback(function(msg, key) self:OnMsg(msg, key) end)
end
--[[
	Check enemy in range
	
	
	@param target   | CUnit   | Unit will be check
	@param range    | int     | Checking range
	@param selected | boolean | is checked
	@return			| boolean | In Range or not

]]
function SimpleTS:IsValid(target, range, selected)
    if ValidTarget(target) and (_GetDistanceSqr(target) <= range or (self.hitboxmode and (_GetDistanceSqr(target) <= (math.sqrt(range) + GetDistance(myHero.minBBox) + GetDistance(target.minBBox)) ^ 2))) then
        if selected or (not (HasBuff(target, "UndyingRage") and (target.health == 1)) and not HasBuff(target, "JudicatorIntervention")) then
            return true
        end
    end
end
--[[
	SimpleTS add to menu
	
	@param menu | menu | Be added to the menu
]]
function SimpleTS:AddToMenu(menu)
    self.menu = menu or scriptConfig("[SourceLib] SimpleTS", "srcSimpleTSClass")
    self.menu:addSubMenu("Target Priority", "STS")
    for i, target in ipairs(GetEnemyHeroes()) do
            self.menu.STS:addParam(target.hash, target.charName, SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
    end
    self.menu.STS:addParam("Info", "Info", SCRIPT_PARAM_INFO, "5 Highest priority")

    local modelist = {}
    for i, mode in ipairs(STS_AVAILABLE_MODES) do
        table.insert(modelist, mode.name)
    end

    self.menu:addParam("mode", "Targetting mode: ", SCRIPT_PARAM_LIST, 1, modelist)
    self.menu["mode"] = self.mode.id

    self.menu:addParam("Selected", "Focus selected target", SCRIPT_PARAM_ONOFF, true)

    STS_MENU = self.menu
end

function SimpleTS:OnMsg(msg, key)
    if msg == WM_LBUTTONDOWN then
        local MinimumDistance = math.huge
        local SelectedTarget
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy) then
                if _GetDistanceSqr(enemy, mousePos) <= MinimumDistance then
                    MinimumDistance = _GetDistanceSqr(enemy, mousePos)
                    SelectedTarget = enemy
                end
            end
        end
        if SelectedTarget and MinimumDistance < 150 * 150 then
            self.STarget = SelectedTarget
        else
            self.STarget = nil
        end
    end
end
--[[
	who is selected target?
	
	@return | CUnit | Selected unit
]]
function SimpleTS:SelectedTarget()
    return self.STarget
end
--[[
	Get target to kill
	
	@param range 	 | int  | range
	@param n 		 | int  | (optional) how many get target
	@param forcemode | mode | (optional) target be search with this mode

]]
function SimpleTS:GetTarget(range, n, forcemode)
    assert(range, "SimpleTS: range can't be nil")
    range = range
    local PosibleTargets = {}
    local selected = self:SelectedTarget()

    if self.menu then
        self.mode = STS_AVAILABLE_MODES[self.menu.mode]
        if self.menu.Selected and selected and selected.type == player.type and self:IsValid(selected, range, true) then
            return selected
        end
    end

    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy) and GetDistance(enemy) < range then --self:IsValid(enemy, range) not perfect
            table.insert(PosibleTargets, enemy)
        end
    end
    table.sort(PosibleTargets, forcemode and forcemode.sortfunc or self.mode.sortfunc)

    return PosibleTargets[n and n or 1]
end

function SimpleTS:OnDraw()
    local selected = self:SelectedTarget()
    if self.menu and self.menu.Selected and ValidTarget(selected) then
        DrawCircle3D(selected.x, selected.y, selected.z, 100, 2, ARGB(175, 0, 255, 0), 25)
    end
end

--[[

'||'   .                      '||    ||'                                                  
 ||  .||.    ....  .. .. ..    |||  |||   ....   .. ...    ....     ... .   ....  ... ..  
 ||   ||   .|...||  || || ||   |'|..'||  '' .||   ||  ||  '' .||   || ||  .|...||  ||' '' 
 ||   ||   ||       || || ||   | '|' ||  .|' ||   ||  ||  .|' ||    |''   ||       ||     
.||.  '|.'  '|...' .|| || ||. .|. | .||. '|..'|' .||. ||. '|..'|'  '||||.  '|...' .||.    
                                                                  .|....'                 

    ItemManager - Better handle them properly

    Functions:
        ItemManager() -- Adding

    Methods:
        ItemManager:ItemCast(param, param1, param2)
		ItemManager:GetSlotItem(param, unit)
		ItemManager:IsReady(param)
		ItemManager:InRange(param, target)
		ItemManager:GetRange(param)

]]
-- item type
ITEM_TARGETING = 0
ITEM_NONTARGETING = 1
ITEM_MYSELF = 2
ITEM_POTION = 3
ITEM_BUFF = 4


class "ItemManager"
function ItemManager:__init()
    self.items = {
			--TARGETING
            ["DFG"] 				= {id = 3128, range = 650, type = ITEM_TARGETING, name = ""},
            ["BOTRK"]				= {id = 3153, range = 450, type = ITEM_TARGETING, name = "itemswordoffeastandfamine"},
			["BilgeWaterCuless"]	= {id = 3144, range = 450, type = ITEM_TARGETING, name = "Bilgewatercutlass"},
			
			-- NONTARGETING
			
			-- myself
			["YOUMUUS"] 			= {id = 3142, range = 450, type = ITEM_MYSELF, name = "Youmusblade"},
			
			-- POTIONS
			["Elixirofwrath"]		= {id = 0001, range = 450, type = ITEM_POTION, name = "Elixirofwrath"},
        }
end
--[[
    Casts all known offensive items on the given target
	
	@param param    | int or string    | Item id or name
    @param param1	| Vector or target | Target x pos or Target unit
	@parma param2   | Vector           | Target z pos
	@param name		| String           | Item name 
]]
function ItemManager:ItemCast(param, param1, param2)
	local slot
	if (type(param) == "string") then
		slot = self:GetSlotItem(self.items[param].id)
	elseif (type(param) == "number") then
		slot = self:GetSlotItem(param)
	else
		print("ItemManager: ItemCast(param, target) : param is invalid type(not string or number)")
		return
	end
	if (param1 ~= nil and param2 ~= nil) then
		CastSpell(slot, param1, param2)
	elseif (param ~= nil and param == nil) then
		CastSpell(slot, param1)
	else
		CastSpell(slot)
	end
end
--[[
    Return Item slot with item name or id
	
	@param param | int or string | Item id or name
	@param unit  | Cunit		 | (optional) Searching target
    @return		 | integer		 | Item slot
]]
function ItemManager:GetSlotItem(param, unit)

	unit 		= unit or myHero
	
	if (type(param) == "number") then 
		if (not self.items[param]) then
			return ___GetInventorySlotItem(param, unit)
		end
		for slot = ITEM_1, ITEM_7 do
			local item = unit:GetSpellData(slot).name
			local name = self:GetName(id)
			if ((#item > 0) and (item:lower() == name:lower())) then
				return slot
			end
		end
		return nil
	elseif(type(param) == "string") then
		for slot = ITEM_1, ITEM_7 do
			local item = unit:GetSpellData(slot).name
			if ((#item > 0) and (item:lower() == param:lower())) then
				return slot
			end
		end
		return nil
	else
		print("ItemManager: GetSlotItem(param, unit) : param is invalid type(not string or number)")
	end
end

--[[
    Returns if the item is ready to be casted (only working when it's an active item)

	@param param | int or string  | Item name or id
    @return		 | boolean 		  | State of the item
]]
function ItemManager:IsReady(param)
	if (type(param) == "string") then
		return self:GetSlotItem(param) and (player:CanUseSpell(self:GetSlotItem(param)) == READY)
	elseif (type(param) == "number") then
		return self:GetSlotItem(param) and (player:CanUseSpell(self:GetSlotItem(param)) == READY)
	else
		print("ItemManager: IsReady(param) : param is invalid type(not string or number)")
		return
	end
end
--[[
    Returns if the item (actually player) is in range of the target

	@param param  | int or string  | Item name or id
    @param target | CUnit          | Target unit
    @return       | boolean        | In range or not
]]
function ItemManager:InRange(param, target)
	if(type(param) == "string") then
		return GetDistance(target) <= self:GetRange(param)
	elseif(type(param) == "number") then
		return GetDistance(target) <= self:GetRange(param)
	else
		print("ItemManager: InRange(param, target) : param is invalid type(not string or number)")
		return
	end
end

function ItemManager:GetRange(param)
	if(type(param) == "string") then
		return self.items[param].range
	elseif(type(param) == "number") then
		for index, item in self.items do
			if item.id == param then
				return item.range
			end
		end
		return 0;
	else
		print("ItemManager: GetRange(param) : param is invalid type(not string or number)")
		return
	end
end
function ItemManager:GetName(id)
	for index, item in self.items do
		if item.id == id then
			return item.name
		end
	end
end
--[[

'||'   .                      '||    ||'                                                   ''|, 
 ||  .||.    ....  .. .. ..    |||  |||   ....   .. ...    ....     ... .   ....  ... ..   '  || 
 ||   ||   .|...||  || || ||   |'|..'||  '' .||   ||  ||  '' .||   || ||  .|...||  ||' ''    .|' 
 ||   ||   ||       || || ||   | '|' ||  .|' ||   ||  ||  .|' ||    |''   ||       ||       //   
.||.  '|.'  '|...' .|| || ||. .|. | .||. '|..'|' .||. ||. '|..'|'  '||||.  '|...' .||.     ((... 
                                                                  .|....'                 

    ItemManager - Better handle them properly

    Functions:
        _ItemManager(menu) -- Adding

    Methods:
        _ItemManager:CastOffensiveItems(target)
        _ItemManager:GetItem(name)

]]
class "_ItemManager"

function _ItemManager:__init(menu)
    self.items = {
            ["DFG"] 				= {id = 3128, range = 650, cancastonenemy = true, name = ""},
            ["BOTRK"]				= {id = 3153, range = 450, cancastonenemy = true, name = "itemswordoffeastandfamine"}, -- currently work
			--["YOUMUUS"] 			= {id = 3142, range = 450, cancastonenemy = false, name = "Youmusblade"} -- currently work
			["BilgeWaterCuless"]	= {id = 3144, range = 450, cancastonenemy = true, name = "Bilgewatercutlass"}, -- currently work
			--["Elixirofwrath"]		= {id = 0001, range = 450, cancastonenemy = false, name = "Elixirofwrath"} -- currently work
        }

    self.requesteditems = {}
	
	--self.menu = menu or scriptConfig("[SourceLib] ItemManager", "srcItemManagerClass")
	--	self.menu:addParam("nontargetingrange", "Use non targeting spell in range", SCRIPT_PARAM_SLICE, 450, 0, 1000)
	--	_G.srcLib.itemmanagerMenu = self.menu
end

--[[
    Casts all known offensive items on the given target

    @param target      | CUnit | Target unit
]]
function _ItemManager:CastOffensiveItems(target)
    for name, itemdata in pairs(self.items) do
        local item = self:GetItem(name)
        if item:InRange(target) then
			item:Cast(target)
        end
    end
end

--[[
    Gets the items by name.

    @param name   | string | Name of the item (not the ingame name, the name used when registering, like DFG)
    @param return | class  | Instance of the item that was requested or nil if not found
]]
function _ItemManager:GetItem(name)
    assert(name and self.items[name], "ItemManager: Item not found")
    if not self.requesteditems[name] then
        self.requesteditems[name] = Item(self.items[name].id, self.items[name].range, self.items[name].name)
    end
    return self.requesteditems[name]
end

-- Make a global ItemManager instance. This means you don't need to make an instance for yourself.
ItemManager = _ItemManager()


--[[

'||'   .                      
 ||  .||.    ....  .. .. ..   
 ||   ||   .|...||  || || ||  
 ||   ||   ||       || || ||  
.||.  '|.'  '|...' .|| || ||. 

    Item - Best used in ItemManager

    Functions:
        Item(id, range)

    Methods:
        Item:GetId()
        Item:GetRange(sqr)
        Item:GetSlot()
        Item:UpdateSlot()
        Item:IsReady()
        Item:InRange(target)
        Item:Cast(param1, param2)
]]
class "Item"

--[[
    Create a new instance of Item

    @param id    | integer | Item id 
    @param range | float   | (optional) Range of the item
	@param name  | string  | (optional) Name of the item
]]
function Item:__init(id, range, name)

    assert(id and type(id) == "number", "Item: id is invalid!")
    assert(not range or range and type(range) == "number", "Item: range is invalid!")

    self.id = id
    self.range = range
	self.name = name or ""
    self.rangeSqr = range and range * range
    self.slot = self:GetSlotItem(id, myHero)

end

--[[
    Returns the id of the item

    @return | integer | Item id
]]
function Item:GetId()
    return self.id
end

--[[
    Return Item slot with item name
	
	@param id	| int     | Item id
	@param unit | Cunit   | (optional) Searching target
    @return		| integer | Item slot
]]
function Item:GetSlotItem(id, unit)

	unit 		= unit or myHero

	if (not ItemNames[id]) then
		return ___GetInventorySlotItem(id, unit)
	end

	local name	= self.name

	for slot = ITEM_1, ITEM_7 do
		local item = unit:GetSpellData(slot).name
		if ((#item > 0) and (item:lower() == name:lower())) then
			return slot
		end
	end
	return nil
end
--[[
    Returns the range of the item, only working when the item was defined with a range.

    @param sqr | boolean | Range squared or not
    @return    | float   | Range of the item
]]
function Item:GetRange(sqr)
    return sqr and self.rangeSqr or self.range
end

--[[
    Return the slot the item is in

    @return | integer | Slot it
]]
function Item:GetSlot()
    self:UpdateSlot()
    return self.slot
end

--[[
    Updates the item slot to the current one (if changed)
]]
function Item:UpdateSlot()
    self.slot = self:GetSlotItem(self.id)
end

--[[
    Returns if the item is ready to be casted (only working when it's an active item)

    @return | boolean | State of the item
]]
function Item:IsReady()
    self:UpdateSlot()
    return self.slot and (player:CanUseSpell(self.slot) == READY)
end

--[[
    Returns if the item (actually player) is in range of the target

    @param target | CUnit   | Target unit
    @return       | boolean | In range or not
]]
function Item:InRange(target)
    return _GetDistanceSqr(target) <= self.rangeSqr
end

--[[
    Casts the item

    @param param1 | CUnit/float | Either the target unit itself or as part of the position the X coordinate
    @param param2 | float       | (only use when param1 is given) The Z coordinate
    @return       | integer     | The spell state
]]
function Item:Cast(param1, param2)
    self:UpdateSlot()
    if self.slot then
        if param1 ~= nil and param2 ~= nil then
            CastSpell(self.slot, param1, param2)
        elseif param1 ~= nil then
            CastSpell(self.slot, param1)
        else
            CastSpell(self.slot)
        end
        return SPELLSTATE_TRIGGERED
    end
end

--[[

'||'            .                                               .                   
 ||  .. ...   .||.    ....  ... ..  ... ..  ... ...  ... ...  .||.    ....  ... ..  
 ||   ||  ||   ||   .|...||  ||' ''  ||' ''  ||  ||   ||'  ||  ||   .|...||  ||' '' 
 ||   ||  ||   ||   ||       ||      ||      ||  ||   ||    |  ||   ||       ||     
.||. .||. ||.  '|.'  '|...' .||.    .||.     '|..'|.  ||...'   '|.'  '|...' .||.    
                                                      ||                            
                                                     ''''                           

    Interrupter - They will never cast!

    Function:
		Interrupter(menu, cb)
	
	Methods:
		Interrupter:AddToMenu(menu)
		Interrupter:AddCallback(unit, spell)
	
	Example:
		Interrupter(menu):AddCallback(function(target) self:CastE(target) end)
]]
class 'Interrupter'

local _INTERRUPTIBLE_SPELLS = {
    ["KatarinaR"]                          = { charName = "Katarina",     DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["Meditate"]                           = { charName = "MasterYi",     DangerLevel = 1, MaxDuration = 2.5, CanMove = false },
    ["Drain"]                              = { charName = "FiddleSticks", DangerLevel = 3, MaxDuration = 2.5, CanMove = false },
    ["Crowstorm"]                          = { charName = "FiddleSticks", DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["GalioIdolOfDurand"]                  = { charName = "Galio",        DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["MissFortuneBulletTime"]              = { charName = "MissFortune",  DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["VelkozR"]                            = { charName = "Velkoz",       DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["InfiniteDuress"]                     = { charName = "Warwick",      DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["AbsoluteZero"]                       = { charName = "Nunu",         DangerLevel = 4, MaxDuration = 2.5, CanMove = false },
    ["ShenStandUnited"]                    = { charName = "Shen",         DangerLevel = 3, MaxDuration = 2.5, CanMove = false },
    ["FallenOne"]                          = { charName = "Karthus",      DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["AlZaharNetherGrasp"]                 = { charName = "Malzahar",     DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["Pantheon_GrandSkyfall_Jump"]         = { charName = "Pantheon",     DangerLevel = 5, MaxDuration = 2.5, CanMove = false },

}
--[[
	Create a new instance of Interrupter
	
	@param menu | menu     | (optional) add to menu
	@param cb	| function | (optional) will called function

]]
function Interrupter:__init(menu, cb)
    self.callbacks = {}
    self.activespells = {}
    AddTickCallback(function() self:OnTick() end)
    AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
    if menu then
        self:AddToMenu(menu)
    end
    if cb then
        self:AddCallback(cb)
    end
end
--[[
	Add to menu interrupter
	
	@param menu | menu | add to menu
]]
function Interrupter:AddToMenu(menu)
    assert(menu, "Interrupter: menu can't be nil!")
    local SpellAdded = false
    local EnemyChampioncharNames = {}
    for i, enemy in ipairs(GetEnemyHeroes()) do
        table.insert(EnemyChampioncharNames, enemy.charName)
    end
    menu:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
    for spellName, data in pairs(_INTERRUPTIBLE_SPELLS) do
        if table.contains(EnemyChampioncharNames, data.charName) then
            menu:addParam(string.gsub(spellName, "_", ""), data.charName.." - "..spellName, SCRIPT_PARAM_ONOFF, true)
            SpellAdded = true
        end
    end
    if not SpellAdded then
        menu:addParam("Info", "Info", SCRIPT_PARAM_INFO, "No spell available to interrupt")
    end
    self.Menu = menu
end
--[[
	Add function be called when should be cancel dangerous spell
	
	@param cd | function | will be called function
]]
function Interrupter:AddCallback(cb)
    assert(cb and type(cb) == "function", "Interrupter: callback is invalid!")
    table.insert(self.callbacks, cb)
end
--[[
	Call the function
	
	@param unit  | Cunit | target unit
	@param spell | spell | spell data
]]
function Interrupter:TriggerCallbacks(unit, spell)
    for i, callback in ipairs(self.callbacks) do
        callback(unit, spell)
    end
end

function Interrupter:OnProcessSpell(unit, spell)
    if not self.Menu.Enabled then return end
    if unit.team ~= myHero.team then
        if _INTERRUPTIBLE_SPELLS[spell.name] then
            local SpellToInterrupt = _INTERRUPTIBLE_SPELLS[spell.name]
            if (self.Menu and self.Menu[string.gsub(spell.name, "_", "")]) or not self.Menu then
                local data = {unit = unit, DangerLevel = SpellToInterrupt.DangerLevel, endT = os.clock() + SpellToInterrupt.MaxDuration, CanMove = SpellToInterrupt.CanMove}
                table.insert(self.activespells, data)
                self:TriggerCallbacks(data.unit, data)
            end
        end
    end
end

function Interrupter:OnTick()
    for i = #self.activespells, 1, -1 do
        if self.activespells[i].endT - os.clock() > 0 then
            self:TriggerCallbacks(self.activespells[i].unit, self.activespells[i])
        else
            table.remove(self.activespells, i)
        end
    end
end


--[[

    |                .    ||   ..|'''.|                           '||                                 
   |||    .. ...   .||.  ...  .|'     '   ....   ... ...    ....   ||    ...    ....    ....  ... ..  
  |  ||    ||  ||   ||    ||  ||    .... '' .||   ||'  || .|   ''  ||  .|  '|. ||. '  .|...||  ||' '' 
 .''''|.   ||  ||   ||    ||  '|.    ||  .|' ||   ||    | ||       ||  ||   || . '|.. ||       ||     
.|.  .||. .||. ||.  '|.' .||.  ''|...'|  '|..'|'  ||...'   '|...' .||.  '|..|' |'..|'  '|...' .||.    
                                                  ||                                                  
                                                 ''''                                                 

    AntiGapcloser - Stay away please, thanks.

    Function:
		AntiGapcloser(menu, cb)
	
	Methods:
		AntiGapcloser:AddToMenu(menu)
		AntiGapcloser:AddCallback(unit, spell)
	
	Example:
		AntiGapcloser(menu):AddCallback(function(target) self:CastE(target) end)
]]
class 'AntiGapcloser'

local _GAPCLOSER_TARGETED, _GAPCLOSER_SKILLSHOT = 1, 2
--Add only very fast skillshots/targeted spells since vPrediction will handle the slow dashes that will trigger OnDash
local _GAPCLOSER_SPELLS = {
    ["AatroxQ"]              = "Aatrox",
    ["AkaliShadowDance"]     = "Akali",
    ["Headbutt"]             = "Alistar",
    ["FioraQ"]               = "Fiora",
    ["DianaTeleport"]        = "Diana",
    ["EliseSpiderQCast"]     = "Elise",
    ["FizzPiercingStrike"]   = "Fizz",
    ["GragasE"]              = "Gragas",
    ["HecarimUlt"]           = "Hecarim",
    ["JarvanIVDragonStrike"] = "JarvanIV",
    ["IreliaGatotsu"]        = "Irelia",
    ["JaxLeapStrike"]        = "Jax",
    ["KhazixE"]              = "Khazix",
    ["khazixelong"]          = "Khazix",
    ["LeblancSlide"]         = "LeBlanc",
    ["LeblancSlideM"]        = "LeBlanc",
    ["BlindMonkQTwo"]        = "LeeSin",
    ["LeonaZenithBlade"]     = "Leona",
    ["UFSlash"]              = "Malphite",
    ["Pantheon_LeapBash"]    = "Pantheon",
    ["PoppyHeroicCharge"]    = "Poppy",
    ["RenektonSliceAndDice"] = "Renekton",
    ["RivenTriCleave"]       = "Riven",
    ["SejuaniArcticAssault"] = "Sejuani",
    ["slashCast"]            = "Tryndamere",
    ["ViQ"]                  = "Vi",
    ["MonkeyKingNimbus"]     = "MonkeyKing",
    ["XenZhaoSweep"]         = "XinZhao",
    ["YasuoDashWrapper"]     = "Yasuo"
}

function AntiGapcloser:__init(menu, cb)
    self.callbacks = {}
    self.activespells = {}
    AddTickCallback(function() self:OnTick() end)
    AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
    if menu then
        self:AddToMenu(menu)
    end
    if cb then
        self:AddCallback(cb)
    end
end

function AntiGapcloser:AddToMenu(menu)
    assert(menu, "AntiGapcloser: menu can't be nil!")
    local SpellAdded = false
    local EnemyChampioncharNames = {}
    for i, enemy in ipairs(GetEnemyHeroes()) do
        table.insert(EnemyChampioncharNames, enemy.charName)
    end
    menu:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
    for spellName, charName in pairs(_GAPCLOSER_SPELLS) do
        if table.contains(EnemyChampioncharNames, charName) then
            menu:addParam(string.gsub(spellName, "_", ""), charName.." - "..spellName, SCRIPT_PARAM_ONOFF, true)
            SpellAdded = true
        end
    end
    if not SpellAdded then
        menu:addParam("Info", "Info", SCRIPT_PARAM_INFO, "No spell available to interrupt")
    end
    self.Menu = menu
	_G.srcLib.AntiGapCloserMenu = self.menu
end

function AntiGapcloser:AddCallback(cb)
    assert(cb and type(cb) == "function", "AntiGapcloser: callback is invalid!")
    table.insert(self.callbacks, cb)
end

function AntiGapcloser:TriggerCallbacks(unit, spell)
    for i, callback in ipairs(self.callbacks) do
        callback(unit, spell)
    end
end

function AntiGapcloser:OnProcessSpell(unit, spell)
    if not self.Menu.Enabled then return end
    if unit.team ~= myHero.team then
        if _GAPCLOSER_SPELLS[spell.name] then
            local Gapcloser = _GAPCLOSER_SPELLS[spell.name]
            if (self.Menu and self.Menu[string.gsub(spell.name, "_", "")]) or not self.Menu then
                local add = false
                if spell.target and spell.target.isMe then
                    add = true
                    startPos = Vector(unit.visionPos)
                    endPos = myHero
                elseif not spell.target then
                    local endPos1 = Vector(unit.visionPos) + 300 * (Vector(spell.endPos) - Vector(unit.visionPos)):normalized()
                    local endPos2 = Vector(unit.visionPos) + 100 * (Vector(spell.endPos) - Vector(unit.visionPos)):normalized()
                    --TODO check angles etc
                    if (_GetDistanceSqr(myHero.visionPos, unit.visionPos) > _GetDistanceSqr(myHero.visionPos, endPos1) or _GetDistanceSqr(myHero.visionPos, unit.visionPos) > _GetDistanceSqr(myHero.visionPos, endPos2))  then
                        add = true
                    end
                end

                if add then
                    local data = {unit = unit, spell = spell.name, startT = os.clock(), endT = os.clock() + 1, startPos = startPos, endPos = endPos}
                    table.insert(self.activespells, data)
                    self:TriggerCallbacks(data.unit, data)
                end
            end
        end
    end
end

function AntiGapcloser:OnTick()
    for i = #self.activespells, 1, -1 do
        if self.activespells[i].endT - os.clock() > 0 then
            self:TriggerCallbacks(self.activespells[i].unit, self.activespells[i])
        else
            table.remove(self.activespells, i)
        end
    end
end

--[[

.|''''|,        '||     '||      ||`         '||` '||                       '||\   /||`                                               
||    ||         ||      ||      ||           ||   ||                        ||\\.//||                                                
||    || '||''|  ||''|,  ||  /\  ||   '''|.   ||   || //`  .|''|, '||''|     ||     ||   '''|.  `||''|,   '''|.  .|''|, .|''|, '||''| 
||    ||  ||     ||  ||   \\//\\//   .|''||   ||   ||<<    ||..||  ||        ||     ||  .|''||   ||  ||  .|''||  ||  || ||..||  ||    
`|....|' .||.   .||..|'    \/  \/    `|..||. .||. .|| \\.  `|...  .||.      .||     ||. `|..||. .||  ||. `|..||. `|..|| `|...  .||.   
                                                                                                                     ||               
                                                                                                                  `..|'       

	OrbWalkManager - Simle orbwalker controler
]]
class('OrbWalkManager')
function OrbWalkManager:__init(m)
	
end

function OrbWalkManager:IsComboMode()
	return false
end

--[[
	.|'''',        '||` '||`                                 
	||              ||   ||   ''         ''                  
	||      .|''|,  ||   ||   ||  (''''  ||  .|''|, `||''|,  
	||      ||  ||  ||   ||   ||   `'')  ||  ||  ||  ||  ||  
	`|....' `|..|' .||. .||. .||. `...' .||. `|..|' .||  ||. 
															 
	collision -- easy check
	
	Function:
		Collision(range, speed, delay, width)
	
	Methods:
		Collision:GetMinionCollision(start, end)
		Collision:GetHeroCollision(start, end)
		Collision:GetCollision(start, end)
		Collision:DrawCollision()
]]
class('Collision')
HERO_ALL = 1
HERO_ENEMY = 2
HERO_ALLY = 3


function Collision:__init(sRange, projSpeed, sDelay, sWidth)
	uniqueId = uniqueId + 1
	self.uniqueId = uniqueId

	self.sRange = sRange
	self.projSpeed = projSpeed
	self.sDelay = sDelay
	self.sWidth = sWidth/2

	self.enemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_HEALTH_ASC)
	self.minionupdate = 0
end

function Collision:GetMinionCollision(pStart, pEnd)
	self.enemyMinions:update()

	local distance =  GetDistance(pStart, pEnd)
	local prediction = TargetPredictionVIP(self.sRange, self.projSpeed, self.sDelay, self.sWidth)
	local mCollision = {}

	if distance > self.sRange then
		distance = self.sRange
	end

	local V = Vector(pEnd) - Vector(pStart)
	local k = V:normalized()
	local P = V:perpendicular2():normalized()

	local t,i,u = k:unpack()
	local x,y,z = P:unpack()

	local startLeftX = pStart.x + (x *self.sWidth)
	local startLeftY = pStart.y + (y *self.sWidth)
	local startLeftZ = pStart.z + (z *self.sWidth)
	local endLeftX = pStart.x + (x * self.sWidth) + (t * distance)
	local endLeftY = pStart.y + (y * self.sWidth) + (i * distance)
	local endLeftZ = pStart.z + (z * self.sWidth) + (u * distance)
   
	local startRightX = pStart.x - (x * self.sWidth)
	local startRightY = pStart.y - (y * self.sWidth)
	local startRightZ = pStart.z - (z * self.sWidth)
	local endRightX = pStart.x - (x * self.sWidth) + (t * distance)
	local endRightY = pStart.y - (y * self.sWidth) + (i * distance)
	local endRightZ = pStart.z - (z * self.sWidth)+ (u * distance)

	local startLeft = WorldToScreen(D3DXVECTOR3(startLeftX, startLeftY, startLeftZ))
	local endLeft = WorldToScreen(D3DXVECTOR3(endLeftX, endLeftY, endLeftZ))
	local startRight = WorldToScreen(D3DXVECTOR3(startRightX, startRightY, startRightZ))
	local endRight = WorldToScreen(D3DXVECTOR3(endRightX, endRightY, endRightZ))
   
	local poly = Polygon(Point(startLeft.x, startLeft.y),  Point(endLeft.x, endLeft.y), Point(startRight.x, startRight.y),   Point(endRight.x, endRight.y))

	 for index, minion in pairs(self.enemyMinions.objects) do
		if minion ~= nil and minion.valid and not minion.dead then
			if GetDistance(pStart, minion) < distance then
				local pos, t, vec = prediction:GetPrediction(minion)
				local lineSegmentLeft = LineSegment(Point(startLeftX,startLeftZ), Point(endLeftX, endLeftZ))
				local lineSegmentRight = LineSegment(Point(startRightX,startRightZ), Point(endRightX, endRightZ))
				local toScreen, toPoint
				if pos ~= nil then
					toScreen = WorldToScreen(D3DXVECTOR3(minion.x, minion.y, minion.z))
					toPoint = Point(toScreen.x, toScreen.y)
				else
					toScreen = WorldToScreen(D3DXVECTOR3(minion.x, minion.y, minion.z))
					toPoint = Point(toScreen.x, toScreen.y)
				end


				if poly:contains(toPoint) then
					table.insert(mCollision, minion)
				else
					if pos ~= nil then
						distance1 = Point(pos.x, pos.z):distance(lineSegmentLeft)
						distance2 = Point(pos.x, pos.z):distance(lineSegmentRight)
					else
						distance1 = Point(minion.x, minion.z):distance(lineSegmentLeft)
						distance2 = Point(minion.x, minion.z):distance(lineSegmentRight)
					end
					if (distance1 < (getHitBoxRadius(minion)*2+10) or distance2 < (getHitBoxRadius(minion) *2+10)) then
						table.insert(mCollision, minion)
					end
				end
			end
		end
	end
	if #mCollision > 0 then return true, mCollision else return false, mCollision end
end

function Collision:GetHeroCollision(pStart, pEnd, mode)
	if mode == nil then mode = HERO_ENEMY end
	local heros = {}

	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if (mode == HERO_ENEMY or mode == HERO_ALL) and hero.team ~= myHero.team then
			table.insert(heros, hero)
		elseif (mode == HERO_ALLY or mode == HERO_ALL) and hero.team == myHero.team and not hero.isMe then
			table.insert(heros, hero)
		end
	end

	local distance =  GetDistance(pStart, pEnd)
	local prediction = TargetPredictionVIP(self.sRange, self.projSpeed, self.sDelay, self.sWidth)
	local hCollision = {}

	if distance > self.sRange then
		distance = self.sRange
	end

	local V = Vector(pEnd) - Vector(pStart)
	local k = V:normalized()
	local P = V:perpendicular2():normalized()

	local t,i,u = k:unpack()
	local x,y,z = P:unpack()

	local startLeftX = pStart.x + (x *self.sWidth)
	local startLeftY = pStart.y + (y *self.sWidth)
	local startLeftZ = pStart.z + (z *self.sWidth)
	local endLeftX = pStart.x + (x * self.sWidth) + (t * distance)
	local endLeftY = pStart.y + (y * self.sWidth) + (i * distance)
	local endLeftZ = pStart.z + (z * self.sWidth) + (u * distance)
   
	local startRightX = pStart.x - (x * self.sWidth)
	local startRightY = pStart.y - (y * self.sWidth)
	local startRightZ = pStart.z - (z * self.sWidth)
	local endRightX = pStart.x - (x * self.sWidth) + (t * distance)
	local endRightY = pStart.y - (y * self.sWidth) + (i * distance)
	local endRightZ = pStart.z - (z * self.sWidth)+ (u * distance)

	local startLeft = WorldToScreen(D3DXVECTOR3(startLeftX, startLeftY, startLeftZ))
	local endLeft = WorldToScreen(D3DXVECTOR3(endLeftX, endLeftY, endLeftZ))
	local startRight = WorldToScreen(D3DXVECTOR3(startRightX, startRightY, startRightZ))
	local endRight = WorldToScreen(D3DXVECTOR3(endRightX, endRightY, endRightZ))
   
	local poly = Polygon(Point(startLeft.x, startLeft.y),  Point(endLeft.x, endLeft.y), Point(startRight.x, startRight.y),   Point(endRight.x, endRight.y))

	for index, hero in pairs(heros) do
		if hero ~= nil and hero.valid and not hero.dead then
			if GetDistance(pStart, hero) < distance then
				local pos, t, vec = prediction:GetPrediction(hero)
				local lineSegmentLeft = LineSegment(Point(startLeftX,startLeftZ), Point(endLeftX, endLeftZ))
				local lineSegmentRight = LineSegment(Point(startRightX,startRightZ), Point(endRightX, endRightZ))
				local toScreen, toPoint
				if pos ~= nil then
					toScreen = WorldToScreen(D3DXVECTOR3(pos.x, hero.y, pos.z))
					toPoint = Point(toScreen.x, toScreen.y)
				else
					toScreen = WorldToScreen(D3DXVECTOR3(hero.x, hero.y, hero.z))
					toPoint = Point(toScreen.x, toScreen.y)
				end


				if poly:contains(toPoint) then
					table.insert(hCollision, hero)
				else
					if pos ~= nil then
						distance1 = Point(pos.x, pos.z):distance(lineSegmentLeft)
						distance2 = Point(pos.x, pos.z):distance(lineSegmentRight)
					else
						distance1 = Point(hero.x, hero.z):distance(lineSegmentLeft)
						distance2 = Point(hero.x, hero.z):distance(lineSegmentRight)
					end
					if (distance1 < (getHitBoxRadius(hero)*2+10) or distance2 < (getHitBoxRadius(hero) *2+10)) then
						table.insert(hCollision, hero)
					end
				end
			end
		end
	end
	if #hCollision > 0 then return true, hCollision else return false, hCollision end
end

function Collision:GetCollision(pStart, pEnd)
	local b , minions = self:GetMinionCollision(pStart, pEnd)
	local t , heros = self:GetHeroCollision(pStart, pEnd, HERO_ENEMY)

	if not b then return t, heros end
	if not t then return b, minions end

	local all = {}

	for index, hero in pairs(heros) do
		table.insert(all, hero)
	end

	for index, minion in pairs(minions) do
		table.insert(all, minion)
	end

	return true, all
end

function Collision:DrawCollision(pStart, pEnd)
   
	local distance =  GetDistance(pStart, pEnd)

	if distance > self.sRange then
		distance = self.sRange
	end

	local color = 4294967295

	local V = Vector(pEnd) - Vector(pStart)
	local k = V:normalized()
	local P = V:perpendicular2():normalized()

	local t,i,u = k:unpack()
	local x,y,z = P:unpack()

	local startLeftX = pStart.x + (x *self.sWidth)
	local startLeftY = pStart.y + (y *self.sWidth)
	local startLeftZ = pStart.z + (z *self.sWidth)
	local endLeftX = pStart.x + (x * self.sWidth) + (t * distance)
	local endLeftY = pStart.y + (y * self.sWidth) + (i * distance)
	local endLeftZ = pStart.z + (z * self.sWidth) + (u * distance)
   
	local startRightX = pStart.x - (x * self.sWidth)
	local startRightY = pStart.y - (y * self.sWidth)
	local startRightZ = pStart.z - (z * self.sWidth)
	local endRightX = pStart.x - (x * self.sWidth) + (t * distance)
	local endRightY = pStart.y - (y * self.sWidth) + (i * distance)
	local endRightZ = pStart.z - (z * self.sWidth)+ (u * distance)

	local startLeft = WorldToScreen(D3DXVECTOR3(startLeftX, startLeftY, startLeftZ))
	local endLeft = WorldToScreen(D3DXVECTOR3(endLeftX, endLeftY, endLeftZ))
	local startRight = WorldToScreen(D3DXVECTOR3(startRightX, startRightY, startRightZ))
	local endRight = WorldToScreen(D3DXVECTOR3(endRightX, endRightY, endRightZ))

	local colliton, objects = self:GetCollision(pStart, pEnd)
   
	if colliton then
		color = 4294901760
	end

	for i, object in pairs(objects) do
		DrawCircle(object.x,object.y,object.z,getHitBoxRadius(object)*2+20,4294901760)
	end

	DrawLine(startLeft.x, startLeft.y, endLeft.x, endLeft.y, 1, color)
	DrawLine(startRight.x, startRight.y, endRight.x, endRight.y, 1, color)

end

function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)/2
end
--[[

'||'  '|'   .    ||  '||  
 ||    |  .||.  ...   ||  
 ||    |   ||    ||   ||  
 ||    |   ||    ||   ||  
  '|..'    '|.' .||. .||. 

    Util - Just utils.
]]

SUMMONERS_RIFT   = { 1, 2 }
PROVING_GROUNDS  = 3
TWISTED_TREELINE = { 4, 10 }
CRYSTAL_SCAR     = 8
HOWLING_ABYSS    = 12

function IsMap(map)

    assert(map and (type(map) == "number" or type(map) == "table"), "IsMap(): map is invalid!")
    if type(map) == "number" then
        return GetGame().map.index == map
    else
        for _, id in ipairs(map) do
            if GetGame().map.index == id then return true end
        end
    end

end

function GetMapName()

    if IsMap(SUMMONERS_RIFT) then
        return "Summoners Rift"
    elseif IsMap(CRYSTAL_SCAR) then
        return "Crystal Scar"
    elseif IsMap(HOWLING_ABYSS) then
        return "Howling Abyss"
    elseif IsMap(TWISTED_TREELINE) then
        return "Twisted Treeline"
    elseif IsMap(PROVING_GROUNDS) then
        return "Proving Grounds"
    else
        return "Unknown map"
    end

end

function ProtectTable(t)

    local proxy = {}
    local mt = {
    __index = t,
    __newindex = function (t,k,v)
        error('attempt to update a read-only table', 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy

end

function _GetDistanceSqr(p1, p2)

    p2 = p2 or player
    if p1 and p1.networkID and (p1.networkID ~= 0) and p1.visionPos then p1 = p1.visionPos end
    if p2 and p2.networkID and (p2.networkID ~= 0) and p2.visionPos then p2 = p2.visionPos end
    return GetDistanceSqr(p1, p2)
    
end

function GetObjectsAround(radius, position, condition)

    radius = math.pow(radius, 2)
    position = position or player
    local objectsAround = {}
    for i = 1, objManager.maxObjects do
        local object = objManager:getObject(i)
        if object and object.valid and (condition and condition(object) == true or not condition) and _GetDistanceSqr(position, object) <= radius then
            table.insert(objectsAround, object)
        end
    end
    return objectsAround

end

function HasBuff(unit, buffname)

    for i = 1, unit.buffCount do
        local tBuff = unit:getBuff(i)
        if tBuff.valid and BuffIsValid(tBuff) and tBuff.name == buffname then
            return true
        end
    end
    return false

end

function GetSummonerSlot(name, unit)

    unit = unit or player
    if unit:GetSpellData(SUMMONER_1).name == name then return SUMMONER_1 end
    if unit:GetSpellData(SUMMONER_2).name == name then return SUMMONER_2 end

end

function GetEnemyHPBarPos(enemy)

    -- Prevent error spamming
    if not enemy.barData then
        if not _G.__sourceLib_barDataInformed then
            print("SourceLib: barData was not found, spudgy please...")
            _G.__sourceLib_barDataInformed = true
        end
        return
    end

    local barPos = GetUnitHPBarPos(enemy)
    local barPosOffset = GetUnitHPBarOffset(enemy)
    local barOffset = Point(enemy.barData.PercentageOffset.x, enemy.barData.PercentageOffset.y)
    local barPosPercentageOffset = Point(enemy.barData.PercentageOffset.x, enemy.barData.PercentageOffset.y)

    local BarPosOffsetX = 169
    local BarPosOffsetY = 47
    local CorrectionX = 16
    local CorrectionY = 4

    barPos.x = barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + CorrectionX
    barPos.y = barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY 

    local StartPos = Point(barPos.x, barPos.y)
    local EndPos = Point(barPos.x + 103, barPos.y)

    return Point(StartPos.x, StartPos.y), Point(EndPos.x, EndPos.y)

end

function CountObjectsNearPos(pos, range, radius, objects)

    local n = 0
    for i, object in ipairs(objects) do
        if _GetDistanceSqr(pos, object) <= radius * radius then
            n = n + 1
        end
    end

    return n

end

function GetBestCircularFarmPosition(range, radius, objects)

    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
        local hit = CountObjectsNearPos(object.visionPos or object, range, radius, objects)
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

function GetBestLineFarmPosition(range, width, objects)

    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
        local EndPos = Vector(myHero.visionPos) + range * (Vector(object) - Vector(myHero.visionPos)):normalized()
        local hit = CountObjectsOnLineSegment(myHero.visionPos, EndPos, width, objects)
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

function GetPredictedPositionsTable(VP, t, delay, width, range, speed, source, collision)

    local result = {}
    for i, target in ipairs(t) do
        local CastPosition, Hitchance, Position = VP:GetCircularCastPosition(target, delay, width, range, speed, source, collision) 
        table.insert(result, Position)
    end
    return result

end

function MergeTables(t1, t2)

    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1

end

function SelectUnits(units, condition)
    
    local result = {}
    for i, unit in ipairs(units) do
        if condition(unit) then
            table.insert(result, unit)
        end
    end
    return result

end

function SpellToString(id)

    if id == _Q then return "Q" end
    if id == _W then return "W" end
    if id == _E then return "E" end
    if id == _R then return "R" end

end

function TARGB(colorTable)

    assert(colorTable and type(colorTable) == "table" and #colorTable == 4, "TARGB: colorTable is invalid!")
    return ARGB(colorTable[1], colorTable[2], colorTable[3], colorTable[4])

end

function PingClient(x, y, pingType)
    Packet("R_PING", {x = x, y = y, type = pingType and pingType or PING_FALLBACK}):receive()
end

local __util_autoAttack   = { "frostarrow" }
local __util_noAutoAttack = { "shyvanadoubleattackdragon",
                              "shyvanadoubleattack",
                              "monkeykingdoubleattack" }
function IsAASpell(spell)

    if not spell or not spell.name then return end

    for _, spellName in ipairs(__util_autoAttack) do
        if spellName == spell.name:lower() then
            return true
        end
    end

    for _, spellName in ipairs(__util_noAutoAttack) do
        if spellName == spell.name:lower() then
            return false
        end
    end

    if spell.name:lower():find("attack") then
        return true
    end

    return false

end

-- Source: http://lua-users.org/wiki/CopyTable
function TableDeepCopy(orig)

    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[TableDeepCopy(orig_key)] = TableDeepCopy(orig_value)
        end
        setmetatable(copy, TableDeepCopy(getmetatable(orig)))
    elseif orig_type == "Vector" then
        copy = orig:clone()
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy

end

--[[

'||'           ||    .    ||          '||   ||                    .    ||                   
 ||  .. ...   ...  .||.  ...   ....    ||  ...  ......   ....   .||.  ...    ...   .. ...   
 ||   ||  ||   ||   ||    ||  '' .||   ||   ||  '  .|'  '' .||   ||    ||  .|  '|.  ||  ||  
 ||   ||  ||   ||   ||    ||  .|' ||   ||   ||   .|'    .|' ||   ||    ||  ||   ||  ||  ||  
.||. .||. ||. .||.  '|.' .||. '|..'|' .||. .||. ||....| '|..'|'  '|.' .||.  '|..|' .||. ||. 

]]
--(scriptName, version, host, updatePath, filePath, versionPath)
if autoUpdate then
	SimpleUpdater("[SourceLib temp fix]", _G.srcLib.version, "raw.github.com" , "/kej1191/anonym/master/Common/SourceLibk.lua" , LIB_PATH .. "SourceLib_Fix.lua" , "/kej1191/anonym/master/Common/version/SoureLibk.version" ):CheckUpdate()
end




















