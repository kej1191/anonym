
function ScriptMsg(msg)
  print("<font color=\"#daa520\"><b>APLD Urgot:</b></font> <font color=\"#FFFFFF\">"..msg.."</font>")
end


local Author = "KaoKaoNi"
local Version = "1.0"

local SCRIPT_INFO = {
	["Name"] = "APLD Urgot",
	["Version"] = 1.0,
	["Author"] = {
		["KaoKaoNi"] = "http://forum.botoflegends.com/user/145247-"
	},
}
local SCRIPT_UPDATER = {
	["Activate"] = true,
	["Script"] = SCRIPT_PATH..GetCurrentEnv().FILE_NAME,
	["URL_HOST"] = "raw.github.com",
	["URL_PATH"] = "/kej1191/anonym/master/APLD/APLD Urgot/APLD Urgot.lua",
	["URL_VERSION"] = "/kej1191/anonym/master/APLD/APLD Urgot/version/APLD Urgot.version"
}
local SCRIPT_LIBS = {
	["SourceLib"] = "https://raw.github.com/LegendBot/Scripts/master/Common/SourceLib.lua",
	["HPrediction"] = "https://raw.githubusercontent.com/BolHTTF/BoL/master/HTTF/Common/HPrediction.lua",
	["VPrediction"] = "https://raw.githubusercontent.com/SidaBoL/Scripts/master/Common/VPrediction.lua",
}

--{ Initiate Script (Checks for updates)
function Initiate()
	for LIBRARY, LIBRARY_URL in pairs(SCRIPT_LIBS) do
		if FileExist(LIB_PATH..LIBRARY..".lua") then
			require(LIBRARY)
		else
			DOWNLOADING_LIBS = true
			ScriptMsg("Missing Library! Downloading "..LIBRARY..". If the library doesn't download, please download it manually.")
			DownloadFile(LIBRARY_URL,LIB_PATH..LIBRARY..".lua",function() ScriptMsg("Successfully downloaded ("..LIBRARY") Thanks Use TEAM Y Teemo") end)
		end
	end
	if DOWNLOADING_LIBS then return true end
	if SCRIPT_UPDATER["Activate"] then
		SourceUpdater("<font color=\"#00A300\">"..SCRIPT_INFO["Name"].."</font>", SCRIPT_INFO["Version"], SCRIPT_UPDATER["URL_HOST"], SCRIPT_UPDATER["URL_PATH"], SCRIPT_UPDATER["Script"], SCRIPT_UPDATER["URL_VERSION"]):CheckUpdate()
	end
end
if Initiate() then return end


local player = myHero
local Q = {Range = 1200, Delay = 0.5, Width = 75, Speed = 1500, IsReady = function() return player:CanUseSpell(_Q) == READY end,}
local W = {IsReady = function() return player:CanUseSpell(_W) == READY end,}
local E = {Range = 900, Delay = 0.8, Radius = 300, Speed = 1500, IsReady = function() return player:CanUseSpell(_E) == READY end,}

function OnOrbLoad()
	if _G.MMA_LOADED then
		ScriptMsg("MMA LOAD")
		MMALoad = true
		orbload = true
	elseif _G.AutoCarry then
		if _G.AutoCarry.Helper then
			ScriptMsg("SIDA AUTO CARRY: REBORN LOAD")
			RebornLoad = true
			orbload = true
		else
			ScriptMsg("SIDA AUTO CARRY: REVAMPED LOAD")
			RevampedLoaded = true
			orbload = true
		end
	elseif _G.Reborn_Loaded then
		SacLoad = true
		DelayAction(OnOrbLoad, 1)
	elseif FileExist(LIB_PATH .. "SxOrbWalk.lua") then
		ScriptMsg("SxOrbWalk Load")
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
	OnOrbLoad()
	HPred = HPrediction()
	VP = VPrediction()
	STS = SimpleTS()

	LoadMenu()
	
	Spell_Q = HPSkillshot({type = "DelayLine", delay = Q.Delay, speed = Q.Speed, range = Q.Range, width = Q.Width*2})
	Spell_E = HPSkillshot({type = "PromptCircle", delay = E.Delay, speed = E.Delay, radius = E.Radius, range = E.Range})
	
	enemyMinions = minionManager(MINION_ENEMY, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
end

function OnTick()
	if Config.Hotkey.Farm then farm() end
	if Config.Hotkey.Combo then Combo() end
	if Config.Hotkey.Harass then harass() end
end

function OnDraw()
	if Config.draw.qrance then DrawCircle(myHero.x, myHero.y, myHero.z, 1100, 0x111111) end
	if Config.draw.erance then DrawCircle(myHero.x, myHero.y, myHero.z, 900, 0x111111) end
end

function LoadMenu()
	Config = scriptConfig("APLD Urgot", "APLD Urgot")

	Config:addSubMenu("Hotkey", "Hotkey")
		Config.Hotkey:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Config.Hotkey:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Config.Hotkey:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
		
		
	Config:addSubMenu("combo", "combo")
		Config.combo:addParam("useq", "USE Q", SCRIPT_PARAM_ONOFF, true)
		Config.combo:addParam("usew", "USE W", SCRIPT_PARAM_ONOFF, true)
		Config.combo:addParam("usee", "USE E", SCRIPT_PARAM_ONOFF, true)

	Config:addSubMenu("harass", "harass")
		Config.harass:addParam("useq", "USE Q", SCRIPT_PARAM_ONOFF, true)
		Config.harass:addParam("usee", "USE E", SCRIPT_PARAM_ONOFF, true)
		Config.harass:addParam("harassper", "Until % use Harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

	Config:addSubMenu("farm", "farm")
		Config.farm:addParam("useq", "USE Q", SCRIPT_PARAM_ONOFF, true)
		Config.farm:addParam("farmper", "Until % use Farm", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

	Config:addSubMenu("ads", "ads")
		Config.ads:addParam("autoq", "Auto Q hit E enemy", SCRIPT_PARAM_ONOFF, true)

	Config:addSubMenu("draw", "draw")
		Config.draw:addParam("qrance", "Draw Q rance", SCRIPT_PARAM_ONOFF, true)
		Config.draw:addParam("erance", "Draw E rance", SCRIPT_PARAM_ONOFF, true)
end

function farm()
	if myHero.mana > (myHero.maxMana*(Config.farm.farmper*0.01)) then
		enemyMinions:update()
		for i, minion in ipairs(enemyMinions.objects) do
			if ValidTarget(minion) and GetDistance(minion) <= 1200 and Q.IsReady() and getDmg("Q", minion, myHero) > minion.health and Config.farm.useq then
				local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(minion, 0.5, 75, 1200, 1500, myHero, true)
				if HitChance >= 2 and GetDistance(CastPosition) < 1200 then
					CastSpell(_Q, CastPosition.x, CastPosition.z)
				end
			end
		end
	end
end

function Combo()
		local target = OrbTarget(1100)
		if Config.combo.usee and E.IsReady() then
			local Pos, HitChance = HPred:GetPredict(Spell_E, target, myHero)
			if HitChance >= 2 and GetDistance(Pos) < 900 then
				CastSpell(_E, Pos.x, Pos.z)
			end
		end

		if target ~= nil then
			if Config.combo.useq and Q.IsReady() and GetDistance(target) < 1200 then
				if Config.combo.usew and W.IsReady() and GetDistance(target, myHero) < 1200 then
					CastSpell(_W)
				end
				if Ehit(target) then
					local Pos, HitChance = HPred:GetPredict(Spell_Q, target, myHero)
					if Pos and HitChance >= 2 and GetDistance(Pos) < 1200 and target.dead == false then
							CastSpell(_Q, Pos.x, Pos.z)
					end
				else
					local Pos, HitChance = HPred:GetPredict(Spell_Q, target, myHero)
					if HitChance >= 2 and GetDistance(Pos) < 1100 then
						CastSpell(_Q, Pos.x, Pos.z)
					end
				end
			end
		end
end

function harass()
	if myHero.mana > (myHero.maxMana*(Config.harass.harassper*0.01)) then
		local target = OrbTarget(1100)
		if Config.harass.usee and E.IsReady() and target ~= nil then
			local Pos, HitChance = HPred:GetPredict(Spell_E, target, myHero)
			if HitChance >= 2 and GetDistance(Pos) < 900 then
				CastSpell(_E, Pos.x, Pos.z)
			end
		end

		if target ~= nil and Ehit(target) then
			if Config.harass.useq and Q.IsReady() and GetDistance(target) <1200 then
				CastSpell(_Q, target)
			end
		end
	end
end

function Ehit(target)
	return TargetHaveBuff("urgotcorrosivedebuff", target)
end