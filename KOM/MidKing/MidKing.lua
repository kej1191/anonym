local champions = {
    ["Xerath"]          = true,
	["Karthus"]			= true,
}
if champions[myHero.charName] == nil then return end

local function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>MidKing:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end

local version = 1.01
local AUTO_UPDATE = false
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/kej1191/anonym/master/KOM/MidKing/MidKing.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH.."Karthus.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

if AUTO_UPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/kej1191/anonym/master/KOM/MidKing/MidKing.version")
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
	["DivinePred"] = "http://divinetek.rocks/divineprediction/DivinePred.lua",
	["HPrediction"] = "https://raw.githubusercontent.com/BolHTTF/BoL/master/HTTF/Common/HPrediction.lua",
	["SPrediction"] = "https://raw.githubusercontent.com/nebelwolfi/BoL/master/Common/SPrediction.lua",
	["VPrediction"] = "",
	["SourceLib"] = "https://raw.github.com/LegendBot/Scripts/master/Common/SourceLib.lua",
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
local SP = SPrediction()
local HP = HPrediction()
local dp = DivinePred()
local VP = VPrediction()
local player = myHero

local Colors = { 
    -- O R G B
    Green   =  ARGB(255, 0, 180, 0), 
    Yellow  =  ARGB(255, 255, 215, 00),
    Red     =  ARGB(255, 255, 0, 0),
    White   =  ARGB(255, 255, 255, 255),
    Blue    =  ARGB(255, 0, 0, 255),
}

local SupPred = {"H Prediction", "D Prediction", "S Prediction"}

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

function OnLoad()
	OnOrbLoad()
	if myHero.charName == "Xerath" then
		champ = Xerath()
	elseif myHero.charName == "Karthus" then
		champ = Karthus()
	end
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

function GetBestLineFarmPosition(range, width, objects)
    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
        local EndPos = Vector(myHero.pos) + range * (Vector(object) - Vector(myHero.pos)):normalized()
        local hit = CountObjectsOnLineSegment(myHero.pos, EndPos, width, objects)
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
	elseif myHero:GetSpellData(_R).level == 2 then
		self.Xerath_R = HPSkillshot({type = "DelayCircle", delay = self.R.Delay, range = 4400, speed = self.R.Speed, radius = self.R.Width*2})
	elseif myHero:GetSpellData(_R).level == 3 then
		self.Xerath_R = HPSkillshot({type = "DelayCircle", delay = self.R.Delay, range = 5600, speed = self.R.Speed, radius = self.R.Width*2})
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

	self.AAtarget = OrbTarget(450)
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
	self:GetTargets()
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
	self.Qrange = math.min(self.Q.MinRange + (self.Q.MaxRange - self.Q.MinRange) * ((os.clock() - self.Q.LastCastTime) / self.Q.TimeToStopIncrease), self.Q.MaxRange)
	if self.Config.Pred.QPred == 1 then
		self.QPos, self.QHitChance = HP:GetPredict(self.Xerath_Q, target, myHero)
		if self.Qrange ~= self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange - 200)^2 or self.Qrange == self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange)^2 then
			if self.QPos and self.QHitChance >= 1.4 then
				self:CastQ2(self.QPos)
			end
		end
	elseif self.Config.Pred.QPred == 2 then
		local Target = DPTarget(target)
		local DivineQ = LineSS(self.Q.Speed, self.Q.MaxRange, self.Q.Width, self.Q.Delay, math.huge)
		self.Qstate, self.QPos, self.Prec = dp:predict(Target, DivineQ)
		if self.Qrange ~= self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange - 200)^2 or self.Qrange == self.Q.MaxRange and GetDistanceSqr(self.QPos) < (self.Qrange)^2 then
			if self.QPos and self.Qstate == SkillShot.STATUS.SUCCESS_HIT then
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
				local Target = DPTarget(target)
				local XerathW = CircleSS(self.W.Speed, self.W.Range, 50, self.W.Delay, math.huge)
				self.Wstate, self.WPos, self.Prec = dp:predict(Target, XerathW)
				if self.WPos and self.Wstate == SkillShot.STATUS.SUCCESS_HIT then
					CastSpell(_W, self.WPos.x, self.WPos.z)
				end
			else
				local Target = DPTarget(target)
				local XerathW = CircleSS(self.W.Speed, self.W.Range, self.W.Width, self.W.Delay, math.huge)
				self.Wstate, self.WPos, self.Prec = dp:predict(Target, XerathW)
				if self.WPos and self.Wstate == SkillShot.STATUS.SUCCESS_HIT then
					CastSpell(_W, self.WPos.x, self.WPos.z)
				end
			end
		elseif self.Config.Pred.WPred == 3 then
			self.WPos, self.WHitChance = SP:PredictPos(target, self.W.Speed, self.W.Delay)
			if self.WPos and self.WHitChance >= 1.4 then
				CastSpell(_W, self.WPos.x, self.WPos.z)
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
			local Target = DPTarget(target)
			local XerathE = LineSS(self.E.Speed, self.E.Range,self.E.Width, self.E.Delay, 0)
			self.Estate, self.EPos, self.Prec = dp:predict(Target, XerathE)
			if self.EPos and self.Estate == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_E, self.EPos.x, self.EPos.z)
			end
		elseif self.Config.Pred.EPred == 3 then
			self.EPos, self.EHitChance, self.PredPos = SP:Predict(target, self.E.Range, self.E.Speed, self.E.Delay, self.E.Width*2, false, myHero)
			if self.EPos ~= nil and self.EHitChance ~= nil then
				if self.EHitChance >= 0.8 then
					CastSpell(_E, self.EPos.x, self.EPos.z)
				end
			end
		end
	end
end

function Xerath:CastIfDashing(target)
    local isDashing, canHit, position = VP:IsDashing(target, self.E.Delay + 0.07 + GetLatency() / 2000, self.E.Width, self.E.Speed, player)
    if isDashing and canHit and position ~= nil and E.IsReady() then
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
				print("1")
				self.R.Target = GetClosestTargetToMouse()
			end
            if self.R.Target and ValidTarget(self.R.Target, self.R.Range()) then
				print("-1")
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
		print("2")
        local target = _T or GetClosestTargetToMouse()
        if ValidTarget(target) and not target.isMe then
			self:CastR3(target)
        end
    end
end

function Xerath:CastR3(target)
	if target ~= nil then
		print("3")
		if self.Config.Pred.RPred == 1 then
			self.RPos, self.RHitChance = HP:GetPredict(self.Xerath_R, target, myHero)
			if self.RPos ~= nil and self.RHitChance ~= nil then
				if self.RHitChance >= 1.2 then
					CastSpell(_R, self.RPos.x, self.RPos.z)
				end
			end
		elseif self.Config.Pred.RPred == 2 then
			local Target = DPTarget(target)
			local XerathR = CircleSS(self.R.Speed, self.R.Range(), self.R.Width, self.R.Delay, math.huge)
			self.Rstate, self.RPos, self.Prec = dp:predict(Target, XerathR)
			if self.RPos and self.Rstate == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_R, self.RPos.x, self.RPos.z)
			end
		elseif self.Config.Pred.RPred == 3 then
			self.RPos, self.RHitChance = SP:PredictPos(target, self.R.Speed, self.R.Delay)
			if self.RPos and self.RHitChance >= 1.4 then
				CastSpell(_R, self.RPos.x, self.RPos.z)
			end
		end
	end
end

function Xerath:Draw()
	if myHero.dead then return end
	if self.Q.IsReady() and self.Config.Draw.DrawQ then
		DrawCircle(player.x, player.y, player.z, self.Q.MaxRange, TARGB(self.Config.Draw.DrawQColor))
	end

	if self.W.IsReady() and self.Config.Draw.DrawW then
		DrawCircle(player.x, player.y, player.z, self.W.Range, TARGB(self.Config.Draw.DrawWColor))
	end

	if self.E.IsReady() and self.Config.Draw.DrawE then
		DrawCircle(player.x, player.y, player.z, self.Config.Combo.Erange, TARGB(self.Config.Draw.DrawEColor))
	end

	if self.R.IsReady() and self.Config.Draw.DrawR then
		DrawCircle(player.x, player.y, player.z, self.R.Range(), TARGB(self.Config.Draw.DrawRColor))
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
		DrawCircle(self.R.Target.x, self.R.Target.y, self.R.Target.z, 100, Colors.Blue)
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
	
	if self.Qstate ~= nil then
		if self.Qstate == SkillShot.STATUS.MINION_HIT then
			self.Qcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		elseif self.Qstate == SkillShot.STATUS.HERO_HIT then
			self.Qcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.Qstate == SkillShot.STATUS.SUCCESS_HIT then
			self.Qcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
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
	
	if self.Wstate ~= nil then
		if self.Wstate == SkillShot.STATUS.MINION_HIT then
			self.Wcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		elseif self.Wstate == SkillShot.STATUS.HERO_HIT then
			self.Wcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.Wstate == SkillShot.STATUS.SUCCESS_HIT then
			self.Wcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
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
	
	if self.Rstate ~= nil then
		if self.Rstate == SkillShot.STATUS.MINION_HIT then
			self.Rcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		elseif self.Rstate == SkillShot.STATUS.HERO_HIT then
			self.Rcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.Rstate == SkillShot.STATUS.SUCCESS_HIT then
			self.Rcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
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
	
	self.DivineQ = CircleSS(math.huge,875,200,600,math.huge)
	self.DivineW = LineSS(math.huge,1000,10,160,math.huge)
	
	self.minionTable =  minionManager(MINION_ENEMY, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	
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
	
	if self.Target and self.Target.team ~= myHero.team and self.Target.type == myHero.type and ValidTarget(self.Target, self.Q.Range) then
		self.QTarget = self.Target
	else
		self.QTS:update()
		self.QTarget = self.QTS.target
	end
	
	if self.Target and self.Target.team ~= myHero.team and self.Target.type == myHero.type and ValidTarget(self.Target, self.W.Range) then
		self.WTarget = self.Target
	else
		self.WTS:update()
		self.WTarget = self.WTS.target
	end
end

function Karthus:Combo()
	self:GetTargets()
	
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
	self:GetTargets()
	
	if self.Q.IsReady() and self.Config.Harass.UseQ then
		self:CastQ(self.QTarget)
	end
	
	if self.W.IsReady() and self.Config.Harass.UseW then
		self:CastW(self.WTarget)
	end
	
	if self.E.IsReady() and self.Config.Harass.UseE then
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
				local bestpos, besthit = GetBestCircularFarmPosition(875, 200, self.minionTable.objects)
				if besthit == 1 then
					if getDmg("Q", minion, player) > minion.health then
						self:CastQ(minion)
					end
				elseif besthit > 1 then
					if getDmg("Q", minion, player)*0.5 > minion.health then
						self:CastQ(minion)
					end
				end
			end
		end
	end
end

function Karthus:Passive()
	self:GetTargets()
	if self.QTarget ~= nil and self.Config.Misc.PassiveManager then
		CastQ(self.QTarget)
	end
	if self.WTarget ~= nil and self.Config.Misc.PassiveManager then
		CastW(self.WTarget)
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
			local Target = DPTarget(target)
			self.Qstate, self.QPos, self.Prec = dp:predict(Target, self.DivineQ)
			if self.QPos and self.Qstate == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_Q, self.QPos.x, self.QPos.z)
			end
		elseif self.Config.Pred.QPred == 3 then
			self.QPos, self.QHitChance, self.PredPos = SP:PredictPos(target, math.huge, self.Q.Delay)
			if self.QPos and self.QHitChance >= 0.8 then
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
			local Target = DPTarget(target)
			self.Wstate, self.WPos, self.Prec = dp:predict(Target, self.DivineW)
			if self.WPos and self.Wstate == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_W, self.WPos.x, self.WPos.z)
			end
		elseif self.Config.Pred.WPred == 3 then
			self.WPos, self.WHitChance = SP:PredictPos(target, self.W.Speed, self.W.Delay)
			if self.WPos and self.WHitChance >= 1.4 then
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
		DrawCircle(player.x, player.y, player.z, self.Q.Range, TARGB(self.Config.Draw.DrawQColor))
	end

	if self.W.IsReady() and self.Config.Draw.DrawW then
		DrawCircle(player.x, player.y, player.z, self.W.Range, TARGB(self.Config.Draw.DrawWColor))
	end

	if self.E.IsReady() and self.Config.Draw.DrawE then
		DrawCircle(player.x, player.y, player.z, self.E.Range, TARGB(self.Config.Draw.DrawEColor))
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
	
	if self.Qstate ~= nil then
		if self.Qstate == SkillShot.STATUS.MINION_HIT then
			self.Qcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		elseif self.Qstate == SkillShot.STATUS.HERO_HIT then
			self.Qcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.Qstate == SkillShot.STATUS.SUCCESS_HIT then
			self.Qcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
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
	
	if self.Wstate ~= nil then
		if self.Wstate == SkillShot.STATUS.MINION_HIT then
			self.Wcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		elseif self.Wstate == SkillShot.STATUS.HERO_HIT then
			self.Wcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.Wstate == SkillShot.STATUS.SUCCESS_HIT then
			self.Wcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
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

























