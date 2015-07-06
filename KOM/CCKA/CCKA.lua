if myHero.charName ~= "Azir" or not VIP_USER then return end
class('AOW')

local function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>CCKAzir:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end

local version = 1.00
local AUTO_UPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/kej1191/anonym/master/KOM/CCKA/CCKA.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH.."CCKA.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

if AUTO_UPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/kej1191//anonym/master/KOM/CCKA/CCKA.version")
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end

local SCRIPT_LIBS = {
	["SourceLib"] = "https://raw.github.com/LegendBot/Scripts/master/Common/SourceLib.lua",
}
function Initiate()
	for LIBRARY, LIBRARY_URL in pairs(SCRIPT_LIBS) do
		if FileExist(LIB_PATH..LIBRARY..".lua") then
			require(LIBRARY)
		else
			DOWNLOADING_LIBS = true
			AutoupdaterMsg("Missing Library! Downloading "..LIBRARY..". If the library doesn't download, please download it manually.")
			DownloadFile(LIBRARY_URL,LIB_PATH..LIBRARY..".lua",function() AutoupdaterMsg("Successfully downloaded "..LIBRARY) end)
		end
	end
	if DOWNLOADING_LIBS then return true end
end
if Initiate() then return end

local Q = {Range = 800, IsReady = function() return myHero:CanUseSpell(_Q) == READY end,}
local W = {Range = 450, IsReady = function() return myHero:CanUseSpell(_W) == READY end,}
local E = {Range = 1100, IsReady = function() return myHero:CanUseSpell(_E) == READY end,}
local R = {Range = 250, IsReady = function() return myHero:CanUseSpell(_R) == READY end,}
local AS = {Range = 375}

local lastAttack, lastWindUpTime, lastAttackCD = 0, 0, 0
local myTrueRange =0;
local OrbTarget = 0;

local customSAR = 0;

local AzirSoldier = {}

local RebornLoad, RevampedLoaded, MMALoad, SxOLoad = false, false, false, false;

function OnOrbLoad()
	if _G.MMA_LOADED then
		AutoupdaterMsg("MMA LOAD")
		MMALoad = true
	elseif _G.AutoCarry then
		if _G.AutoCarry.Helper then
			AutoupdaterMsg("SIDA AUTO CARRY: REBORN LOAD")
			RebornLoad = true
		else
			AutoupdaterMsg("SIDA AUTO CARRY: REVAMPED LOAD")
			RevampedLoaded = true
		end
	elseif _G.Reborn_Loaded then
		SacLoad = true
		DelayAction(OnOrbLoad, 1)
	elseif FileExist(LIB_PATH .. "SxOrbWalk.lua") then
		AutoupdaterMsg("SxOrbWalk Load")
		require 'SxOrbWalk'
		SxO = SxOrbWalk()
		SxOLoad = true
	end
end

function BlockAA(bool)
	if not bool then
		if MMALoad then
		elseif SacLoad then
			_G.AutoCarry.MyHero:AttacksEnabled(true)
			_G.AutoCarry.MyHero:MovementEnabled(true)
		elseif SxOLoad then
			SxO:EnableAttacks()
			SxO:EnableMove()
		end
	else
		if MMALoad then
		elseif SacLoad then
			_G.AutoCarry.MyHero:AttacksEnabled(false)
			_G.AutoCarry.MyHero:MovementEnabled(false)
		elseif SxOLoad then
			SxO:DisableAttacks()
			SxO:DisableMove()
		end
	end
end

function OnLoad()
	STS = SimpleTS()
	AOW = AOW()
	
	OnLoadMenu()

	myTrueRange = myHero.range + GetDistance(myHero.minBBox)
	
end

function OnLoadMenu()
	Config = scriptConfig("CokCokKingAzir", "CCKA")
	
		Config:addSubMenu("AzirOrb", "AzirOrb")
			AOW:LoadMenu(Config.AzirOrb);
			
		Config:addSubMenu("HotKey", "HotKey")
			Config.HotKey:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			Config.HotKey:addParam("Harass", "Harass", SCRIPT_PARAM_ONOFF, false, string.byte('V'))
			Config.HotKey:addParam("Escape", "Escape", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('G'))
			
		Config:addSubMenu("Combo", "Combo")
			Config.Combo:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			Config.Combo:addParam("UseW", "UseW", SCRIPT_PARAM_ONOFF, true)
		
		Config:addSubMenu("Harass", "Harass")
			Config.Harass:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			Config.Harass:addParam("UseW", "UseW", SCRIPT_PARAM_ONOFF, true)
		
		Config:addSubMenu("[Conquering Sands] Setting", "Q")
			Config.Q:addParam("MinNum", "Use Q can under attack number", SCRIPT_PARAM_SLICE, 1, 1, 3, 0)
			
		Config:addSubMenu("[Arise] Setting", "W")
			Config.W:addParam("Keep", "Keep soldier number", SCRIPT_PARAM_SLICE, 1, 1, 3, 0)
			Config.W:addParam("SoldierAR", "Custom Soldier AA range", SCRIPT_PARAM_SLICE, AS.Range, 300, 400, 0)
		
		Config:addSubMenu("Draw", "Draw")
			Config.Draw:addParam("info0", "Draw Range", SCRIPT_PARAM_INFO, "")
			Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawQColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			Config.Draw:addParam("info1", "", SCRIPT_PARAM_INFO, "")
			Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawWColor", "Draw W Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			Config.Draw:addParam("info2", "", SCRIPT_PARAM_INFO, "")
			Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawEColor", "Draw E Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			Config.Draw:addParam("info3", "", SCRIPT_PARAM_INFO, "")
			Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawRColor", "Draw R Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			Config.Draw:addParam("info4", "", SCRIPT_PARAM_INFO, "")
			Config.Draw:addParam("DrawS", "Draw Soldier Range", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawSColor", "Draw Soldier Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
end

function OnTick()
	if Config.HotKey.Combo then 
		OnCombo()
		BlockAA(true)
	else
		BlockAA(false)
	end
	if Config.HotKey.Escape then Dash() end
	customSAR = Config.W.SoldierAR
end

function OnDraw()
	if player.dead then return end
	if Q.IsReady() and Config.Draw.DrawQ then
		DrawCircle(player.x, player.y, player.z, Q.Range, TARGB(Config.Draw.DrawQColor))
	end

	if W.IsReady() and Config.Draw.DrawW then
		DrawCircle(player.x, player.y, player.z, W.Range, TARGB(Config.Draw.DrawWColor))
	end

	if E.IsReady() and Config.Draw.DrawE then
		DrawCircle(player.x, player.y, player.z, E.Range, TARGB(Config.Draw.DrawEColor))
	end
	
	if R.IsReady() and Config.Draw.DrawR then
		DrawCircle(player.x, player.y, player.z, R.Range, TARGB(Config.Draw.DrawRColor))
	end
	
	for unit, azir in ipairs(AzirSoldier) do	
		DrawCircle(azir.x, azir.y, azir.z, customSAR, TARGB(Config.Draw.DrawSColor))
	end
end

function OnCombo()
	local t = STS:GetTarget(myTrueRange+customSAR)
	if t ~= nil then
		if ClosetSoldier(t) <= Config.Q.MinNum and Q.IsReady() and Config.Combo.UseQ then
			CastQ(t)
		end
		if W.IsReady() and Config.Combo.UseW then CastW(t) end
	end
end

function OnHarass()
	local t = STS:GetTarget(myTrueRange+customSAR)
	if t ~= nil then
		if ClosetSoldier(t) <= Config.Q.MinNum and Q.IsReady() and Config.Harass.UseQ then
			CastQ(t)
		end
		if W.IsReady() and Config.Harass.UseW then CastW(t) end
	end
end

function Dash()
	if W.IsReady() then
		CastW(mousePos)
	end
	if Q.IsReady() and #AzirSoldier ~= 0 then
		CastQ(mousePos)
		CastE(mousePos)
	end
end

function CastQ(Pos)
	CastSpell(_Q, Pos.x, Pos.z)
end

function CastW(Pos)
	CastSpell(_W, Pos.x, Pos.z)
end

function CastE(Pos)
	CastSpell(_E, Pos.x, Pos.z)
end

function CastR(Pos)
	CastSpell(_R, Pos.x, Pos.z)
end

function ClosetSoldier(target)
	local CanAANum = 0
	for unit, soldier in pairs(AzirSoldier) do
		if GetDistance(soldier, target) < customSAR then
			CanAANum = CanAANum + 1
		end
	end
	return CanAANum
end


function OnCreateObj(obj)
	if obj ~= nil then
		if obj.name == "AzirSoldier" then
			print("Create")
			table.insert(AzirSoldier, obj)
		end
	end
end

function OnDeleteObj(obj)
	if obj ~= nil then
		if obj.name == "AzirSoldier" then
			for unit, sold in pairs(AzirSoldier) do
				if sold == obj then
					table.remove(AzirSoldier, unit)
				end
			end
		end
	end
end


function AOW:__init()
end

function AOW:LoadMenu(menu)
	if menu then
		self.menu = menu
	else
		self.menu = scriptConfig("Azir OrbWalk", "AOW")
	end
	
	self.menu:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	self.menu:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
		
	AddTickCallback(function() self:OrbWalk() end)
	AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
end

function AOW:OnProcessSpell(unit, spell)
	if unit == myHero then
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
		end
	end
end

function AOW:OrbWalk()
	if self.menu.Combo or self.menu.Harass then
		OrbTarget = STS:GetTarget(myTrueRange+customSAR)
		if OrbTarget ~= nil then
			if self.tiemToShoot() then
				if #AzirSoldier ~= 0 then
					for i, j in pairs(AzirSoldier) do 
						if GetDistance(j) < customSAR+myTrueRange then
							myHero:Attack(OrbTarget);
							break;
						end
					end
				else
					if GetDistance(j) < myTrueRange then
						myHero:Attack(OrbTarget);
					end
				end
			elseif self.heroCanMove() then
				self.moveToCursor()
			end
		else
			self.moveToCursor()
		end
	end
end

function AOW:tiemToShoot()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end

function AOW:heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end

function AOW:moveToCursor()
	if GetDistance(mousePos) > 10 then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*250
		myHero:MoveTo(moveToPos.x, moveToPos.z)
	end
end