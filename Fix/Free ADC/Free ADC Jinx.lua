local version = "1.16"
--[[

Free Jinx!

by Dienofail

Changelog:

v0.01 - release

v0.02 - Draw other Q circles added. Temporary solution to R overkill problems. 

v0.03 - Added collision for R, added min W slider.

v0.04 - now defaults to fishbones if no enemies around.

v0.05 - Small fixes to default Q swapping

v0.06 - reverted to v0.04 for now until issues are resolved. 

v0.07 - small fixes

v0.08 - Added toggle for R overkill checks

v0.09 - Fixed typo

v0.10 - R fixes. 

v0.11 - Deleted orbwalker check. 

v0.12 - Typo fix

v0.13 - Fixed draw options

v1.00 - added option to auto E immobile/stunned/gapclosing enemies (vpred math, not custom math). Swapped colors back again, and added checks for last
waypoints in E mode. Added lag free circles. 

v1.01 - Now defaults to pow pow when farming

v1.02 - Fixed pow pow farm 

v1.03 - Added farm press requirement for pow pow

v1.04 - Github

v1.05 - Fixes to Q swapping

v1.06 - Fixes to bugs in Q swapping introduced in v1.05

v1.07 - Added mana manager and increased activation delay for auto E

v1.08 - Adjusted W issues. 

v1.09 - Autoupdate issues

v1.10 - Finally updated variable Jinx ult speed :D

v1.11 - Separate mana managers for harass

v1.12 - Now reverts back to minigun if enemy out of range in harass mode

v1.13 - Typo fix

v1.14 - SoW integration

v1.15 - Prod 1.1/1.0 integration

v1.16 - Draw fixes
]]

if not VIP_USER or myHero.charName ~= "Jinx" then return end

require 'VPrediction'
require 'Collision'
require 'Prodiction'
local ProdOneLoaded = false
local ProdFile = LIB_PATH .. "Prodiction.lua"
local fh = io.open(ProdFile, 'r')
if fh ~= nil then
  local line = fh:read()
  local Version = string.match(line, "%d+.%d+")
  if Version == nil or tonumber(Version) == nil then
    ProdOneLoaded = false
  elseif tonumber(Version) > 0.8 then
    ProdOneLoaded = true
  end
  if ProdOneLoaded then
    require 'Prodiction'
    print("<font color=\"#FF0000\">Prodiction 1.0 Loaded for DienoJinx, 1.0 option is usable</font>")
  else
    print("<font color=\"#FF0000\">Prodiction 1.0 not detected for DienoJinx, 1.0 is not usable (will cause errors if checked)</font>")
  end
else
  print("<font color=\"#FF0000\">No Prodiction.lua detected, using only VPRED</font>")
end

--Honda7
local AUTOUPDATE = true
local UPDATE_SCRIPT_NAME = "Free ADC Jinx"
local UPDATE_NAME = "Jinx"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/kej1191/anonym/master/Fix/Free ADC/Free ADC Jinx.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>"..UPDATE_NAME..":</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH, "", 5)
	if ServerData then
		local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
		ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
		if ServerVersion then
			ServerVersion = tonumber(ServerVersion)
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)	 
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end

if VIP_USER then
 	AdvancedCallback:bind('OnApplyBuff', function(source, unit, buff) OnApplyBuff(source, unit, buff) end)
	AdvancedCallback:bind('OnUpdateBuff', function(unit, buff, stack) OnUpdateBuff(unit, buff, stack) end)
	AdvancedCallback:bind('OnRemoveBuff', function(unit, buff) OnRemoveBuff(unit, buff) end)
end

local Config = nil
local VP = VPrediction()
local Col = Collision(3000, 1700, 0.316, 140)
local SpellW = {Speed = 3300, Range = 1500, Delay = 0.600, Width = 60}
local SpellE = {Speed = 1750, Delay = 0.5 + 0.2658, Range = 900, Width = 120}
local SpellR = {Speed = 1700, Delay = 0.066 + 0.250, Range = 25750, Width = 140}
local QReady, WReady, EReady, RReady = nil, nil, nil, nil 
local QObject = nil
local QEndPos = nil
local LastDistance = nil
local TargetQPos = nil
local isFishBones = true
local FishStacks = 0
local Walking = false
local QRange



function OnLoad()
	DelayAction(checkOrbwalker, 3)
	DelayAction(Menu,5)
	DelayAction(Init,5)
end

function checkOrbwalker()
    if _G.MMA_Loaded ~= nil and _G.MMA_Loaded then
        IsMMALoaded = true
        print('MMA detected')
    elseif _G.Reborn_Loaded then
        IsSACLoaded = true
        print('SAC detected')
    elseif FileExist(LIB_PATH .."SOW.lua") then
        require "SOW"
        SOWi = SOW(VP)
        IsSowLoaded = true
        SOWi:RegisterAfterAttackCallback(AutoAttackReset)
        print('SOW loaded')
    else
        print('Please use SAC, MMA, or SOW for your orbwalker')
    end
end


function Init()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1575, DAMAGE_PHYSICAL)
	ts.name = "Ranged Main"
	Config:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 1100, myHero, MINION_SORT_MAXHEALTH_DEC)
    print('Dienofail Jinx ' .. tostring(version) .. ' Fixed by KaoKaoNi loaded!')
    initDone = true
end


function Menu()
	Config = scriptConfig("Jinx", "Jinx")
	Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
	Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
	Config:addSubMenu("Combo options", "ComboSub")
	Config:addSubMenu("Harass options", "HarassSub")
	Config:addSubMenu("KS", "KS")
	Config:addSubMenu("Extra Config", "Extras")
	Config:addSubMenu("Draw", "Draw")

	--Combo
	Config.ComboSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("mManager", "Mana Slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
	--Harass
	Config.HarassSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("mManager", "Mana Slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)	
	--Draw 
	Config.Draw:addParam("DrawOtherQ", "Draw Other Q", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
	
	--KS
	Config.KS:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.KS:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	--Extras
	Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("RRange", "Max R Range", SCRIPT_PARAM_SLICE, 1700, 0, 3575, 0)
	Config.Extras:addParam("WRange", "Min W Range", SCRIPT_PARAM_SLICE, 300, 0, 1450, 0)
	Config.Extras:addParam("MinRRange", "Min R Range", SCRIPT_PARAM_SLICE, 300, 0, 1800, 0)
	Config.Extras:addParam("REnemies", "Min Enemies for Auto R", SCRIPT_PARAM_SLICE, 4, 1, 5, 0)
	Config.Extras:addParam("ROverkill", "Check R Overkill", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("EStun", "Auto E Stunned", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("EGapcloser", "Auto E Gapclosers", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("EAutoCast", "Auto E Slow/Immobile/Dash", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("SwapThree", "Swap Q at three fishbone stacks", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("SwapDistance", "Swap Q for Distance", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("SwapAOE", "Swap Q for AoE", SCRIPT_PARAM_ONOFF, true)
	if ProdOneLoaded then
		Config.Extras:addParam("Prodiction", "Use Prodiction 1.0 instead of VPred", SCRIPT_PARAM_ONOFF, false)
	end	
	Config:addParam("INFO", "", SCRIPT_PARAM_INFO, "")
	Config:addParam("Fixer", "Fixer", SCRIPT_PARAM_INFO, "KaoKaoNi")
	Config:addParam("Team", "Team", SCRIPT_PARAM_INFO, "Your")
	
	--Permashow
	Config:permaShow("Combo")
	Config:permaShow("Harass")
	if IsSowLoaded then
        Config:addSubMenu("Orbwalker", "SOWiorb")
        SOWi:LoadToMenu(Config.SOWiorb)
    end
end

function IsMyManaLow()
    if myHero.mana < (myHero.maxMana * ( Config.ComboSub.mManager / 100)) then
        return true
    else
        return false
    end
end

function IsMyManaLowHarass()
    if myHero.mana < (myHero.maxMana * ( Config.HarassSub.mManager / 100)) then
        return true
    else
        return false
    end
end

--Credit Trees
function GetCustomTarget()
	ts:update()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
    return ts.target
end
--End Credit Trees

function OnTick()
	if initDone then
		EnemyMinions:update()
		Check()
		local target = GetCustomTarget()
		local Wtarget = ts.target

		if Config.Combo and target ~= nil then
			Combo(target)
		elseif Config.Combo and Wtarget ~= nil then
			Combo(Wtarget)
		end

		if Config.Harass and target ~= nil then
			Harass(target)
		elseif Config.Harass and Wtarget ~= nil then
			Harass(Wtarget)
		elseif Config.Harass and Wtarget == nil and not isFishBones then
			CastSpell(_Q)
		end

		if Config.Farm then
			if not isFishBones then
				CastSpell(_Q)
			end
		end

		if Config.Extras.EStun then
			CheckImmobile()
		end

		if Config.Extras.EGapcloser then
			CheckDashes()
		end
		KS()

		if target == nil and Wtarget == nil and not isFishBones and QReady and Config.Farm then
			CastSpell(_Q)
		end
	end
end

function Combo(Target)
		-- if Config.Extras.Debug then
		-- 	print('Combo called')
		-- end	
	if GetDistance(Target) < 1575 and Config.ComboSub.useW and not IsMyManaLow() then
		CastW(Target)
	end

	if EReady and Config.ComboSub.useE and not IsMyManaLow() then
		CastE(Target)
	end

	if EReady and Config.Extras.EAutoCast and not IsMyManaLow()then
		AutoCastE(Target)
	end

	if QReady and Config.ComboSub.useQ and not IsMyManaLow() then
		-- if Config.Extras.Debug then
		-- 	print('Cast Q called')
		-- end	
		Swap(Target)
	end

	if RReady and Config.ComboSub.useR and not IsMyManaLow() then
		CastR(Target)
	end
end


function Swap(Target)
	if Target ~= nil and not Target.dead and ValidTarget(Target) and QReady then
		local PredictedPos, HitChance = CombinedPos(Target, 0.25, math.huge, myHero, false)
		if PredictedPos ~= nil and HitChance ~= nil then
			if isFishBones then
				if Config.Extras.SwapThree and FishStacks == 3 and GetDistance(PredictedPos) < QRange then
					CastSpell(_Q)
				end
				if Config.Extras.SwapDistance and GetDistance(Target) > 600 + VP:GetHitBox(Target) and GetDistance(PredictedPos) > 600 + VP:GetHitBox(Target) and GetDistance(PredictedPos) < QRange + VP:GetHitBox(Target) then
					CastSpell(_Q)
				end
				if Config.Extras.SwapAOE and CountEnemyNearPerson(Target, 150) > 1 and FishStacks > 2 then 
					CastSpell(_Q)
				end
			else
				if Config.Extras.SwapAOE and CountEnemyNearPerson(Target, 150) > 1 then 
					return
				end
				if Config.Extras.SwapThree and FishStacks < 3 and GetDistance(PredictedPos) < 575 + VP:GetHitBox(Target) and GetDistance(Target) < 600 + VP:GetHitBox(Target) then
					CastSpell(_Q)
				end
				if Config.Extras.SwapDistance and GetDistance(PredictedPos) < 575 + VP:GetHitBox(Target) and GetDistance(Target) < 600 + VP:GetHitBox(Target) then
					CastSpell(_Q)
				end
				if IsMyManaLow() and GetDistance(Target) < 600 + VP:GetHitBox(Target) then
					CastSpell(_Q)
				end 
				if Config.Harass and GetDistance(Target) > 600 + VP:GetHitBox(Target) + 50 then
					CastSpell(_Q)
				end
			end
		end
	end
end


function Harass(Target)
	if WReady and Config.HarassSub.useW and not IsMyManaLowHarass() then
		CastW(Target)
	end

	if QReady and Config.HarassSub.useQ  and not IsMyManaLowHarass() then
		Swap(Target)
	end

	if EReady and Config.HarassSub.useE and not IsMyManaLowHarass() then
		CastE(Target)
	end
end


function CastE(Target)
	if EReady and GetDistance(Target) < 1100 then
		GetWallCollision(Target)
	end
end

function CastW(Target)
	local CastPosition, HitChance, Pos = CombinedPredict(Target, SpellW.Delay, SpellW.Width, SpellW.Range, SpellW.Speed, myHero, true)
	
	if CastPosition ~= nil and HitChance ~= nil then
		if GetDistance(Target) < 600 and WReady and Reset(Target) and HitChance >= 1.4 and GetDistance(Target) > Config.Extras.WRange then
			CastSpell(_W, CastPosition.x, CastPosition.z)
		elseif GetDistance(Target) > 600 and HitChance >= 1.4 and GetDistance(Target) > Config.Extras.WRange then
			CastSpell(_W, CastPosition.x, CastPosition.z)
		end
	end
end

function CastR(Target)
	if Target ~= nil and GetDistance(Target) < Config.Extras.RRange and RReady then
		if CountEnemyNearPerson(Target, 250) > Config.Extras.REnemies then
			local CurrentRSpeed = JinxUltSpeed(Target)
			local RAoEPosition, RHitchance, NumHit = VP:GetCircularAOECastPosition(Target, SpellR.Delay, SpellR.Width, SpellR.Range, CurrentRSpeed, myHero)
			if RHitchance >= 2 and RAoEPosition ~= nil and GetDistance(RAoEPosition) < Config.Extras.RRange then
				CastSpell(_R, RAoEPosition.x, RAoEPosition.z)
			end
		end
		if GetDistance(Target) > Config.Extras.MinRRange and Config.Extras.ROverkill and GetDistance(Target) < Config.Extras.RRange then 
			local RDamage = getDmg("R", Target, myHero)
			local ADamage = getDmg("AD", Target, myHero)
			if Target.health < ADamage * 3.5 then 
				return
			elseif Target.health < RDamage then
				local CurrentRSpeed = JinxUltSpeed(Target)
				local RPosition, HitChance, Pos = CombinedPredict(Target, SpellR.Delay, SpellR.Width, Config.Extras.RRange, CurrentRSpeed, myHero, false)
				if RPosition ~= nil and HitChance ~= nil then
					if HitChance >= 2 then
						CastSpell(_R, RPosition.x, RPosition.z)
					end
				end
			end
		elseif GetDistance(Target) < Config.Extras.RRange then
			local RDamage = getDmg("R", Target, myHero)
			local ADamage = getDmg("AD", Target, myHero)
			if Target.health < RDamage then
				local CurrentRSpeed = JinxUltSpeed(Target)
				local RPosition, HitChance, Pos = CombinedPredict(Target, SpellR.Delay, SpellR.Width, Config.Extras.RRange, CurrentRSpeed, myHero, false)
				if RPosition ~= nil and HitChance ~= nil then
					if HitChance >= 2 then
						CastSpell(_R, RPosition.x, RPosition.z)
					end
				end
			end
		end
	end
end


function KS()
	local Enemies = GetEnemyHeroes()
	for idx, enemy in ipairs(Enemies) do
		if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < Config.Extras.RRange and Config.KS.useR then
			if getDmg("R", enemy, myHero) > enemy.health then
				CastR(enemy)
			end
		elseif  not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellW.Range and Config.KS.useW then
			if getDmg("W", enemy, myHero) > enemy.health then
				CastW(enemy)
			end
		end
	end
end

function CheckImmobile()
	local Enemies = GetEnemyHeroes()
	for idx, enemy in ipairs(Enemies) do
		if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellW.Range and Config.Extras.EStun then
			local IsImmobile, pos = VP:IsImmobile(enemy, 0.605, SpellE.Width, SpellW.Speed, myHero)
			if IsImmobile and GetDistance(pos) < SpellE.Range and EReady then
				CastSpell(_E, pos.x, pos.z)
			end
		end
	end
end

function CheckDashes()
	local Enemies = GetEnemyHeroes()
	for idx, enemy in ipairs(Enemies) do
		if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellW.Range and Config.Extras.EStun then
			local IsDashing, CanHit, Position = VP:IsDashing(enemy, 0.250, 10, math.huge, myHero)
			if IsDashing and CanHit and GetDistance(Position) < SpellE.Range and EReady then
				local DashVector = Vector(Vector(Position) - Vector(enemy)):normalized()*((SpellE.Delay - 0.250)*enemy.ms)
				local CastPosition = Position + DashVector
				if GetDistance(CastPosition) < SpellE.Range then
					CastSpell(_E, CastPosition.x, CastPosition.z)
				end
			end
		end
	end
end

function Reset(Target)
	if GetDistance(Target) > 580 then
		return true
	elseif _G.MMA_Loaded and _G.MMA_NextAttackAvailability < 0.6 then
		return true
	elseif _G.AutoCarry and (_G.AutoCarry.shotFired or _G.AutoCarry.Orbwalker:IsAfterAttack()) then 
		-- if Config.Extras.Debug then
		-- 	print('SAC shot fired')
		-- end
		return true
	else
		return false
	end
end

function AutoCastE(Target) 
	if Target ~= nil and not Target.dead and ValidTarget(Target, 1500) then
		local CastPosition, HitChance, Position = VP:GetCircularCastPosition(Target, SpellE.Delay+0.2, 60, SpellE.Range, SpellE.Speed, myHero, false)
		if HitChance >= 3 and EReady and GetDistance(CastPosition) < SpellE.Range then
			CastSpell(_E, CastPosition.x, CastPosition.z)
		end
	end
end


function OnDraw()
	if initDone then
		if Config.Extras.Debug then
			DrawText3D("Current FishBones status is " .. tostring(isFishBones), myHero.x+200, myHero.y, myHero.z+200, 25,  ARGB(255,255,0,0), true)
			DrawText3D("Current FishBones stacks is " .. tostring(FishStacks), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
			if Wtarget ~= nil then
				DrawCircle2(Wtarget.x, Wtarget.y, Wtarget.z, 150, ARGB(255, 0, 255, 255))
			end
		end

		if Config.Draw.DrawW then
			DrawCircle2(myHero.x, myHero.y, myHero.z, SpellW.Range, ARGB(255, 0, 255, 255))
		end

		if Config.Draw.DrawE then
			DrawCircle2(myHero.x, myHero.y, myHero.z, SpellE.Range, ARGB(255, 0, 255, 255))
		end

		if Config.Draw.DrawR then
			DrawCircle2(myHero.x, myHero.y, myHero.z, Config.Extras.RRange, ARGB(255, 0, 255, 255))
		end

		if Config.Draw.DrawOtherQ then
			if isFishBones then
				DrawCircle2(myHero.x, myHero.y, myHero.z, 600,ARGB(255, 255, 0, 0))
			else
				DrawCircle2(myHero.x, myHero.y, myHero.z, QRange, ARGB(255, 255, 0, 0))
			end
		end
	end
end

function OrbwalkToPosition(position)
	if position ~= nil then
		if _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(position)
		elseif _G.MMA_Loaded then 
			moveToCursor(position.x, position.z)
		end
	else
		if _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(nil)
		elseif _G.MMA_Loaded then 
			moveToCursor()
		end
	end
end

function OnApplyBuff(source, unit, buff)
	if unit then
		if unit.isMe and buff.name == 'JinxQ' then
			isFishBones = false
		end

		if unit.isMe and buff.name == 'jinxqramp' then
			FishStacks = 1
		end
	end
end

function OnUpdateBuff(unit, buff, stack)
	if unit then
		if unit.isMe and buff.name == 'jinxqramp' then
			FishStacks = stack
		end
	end
end

function OnRemoveBuff(unit, buff)
	if unit then
		if unit.isMe and buff.name == 'JinxQ' then
			isFishBones = true
		end

		if unit.isMe and buff.name == 'jinxqramp' then
			FishStacks = 0
		end
	end
end


function Check()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	if QObject == nil and not QReady then
		QEndPos = nil
		LastDistance = nil
	end
	QRange = myHero:GetSpellData(_Q).level*25 + 50 + 600
end

function GenerateWallVector(pos)
	local WallDisplacement = 120
	local HeroToWallVector = Vector(Vector(pos) - Vector(myHero)):normalized()
	local RotatedVec1 = HeroToWallVector:perpendicular()
	local RotatedVec2 = HeroToWallVector:perpendicular2()
	local EndPoint1 = Vector(pos) + Vector(RotatedVec1)*WallDisplacement
	local EndPoint2 = Vector(pos) + Vector(RotatedVec2)*WallDisplacement
	local DiffVector = Vector(EndPoint2 - EndPoint1):normalized()
	return EndPoint1, EndPoint2, DiffVector
end

function GetWallCollision(Target)
	local TargetDestination, HitChance = CombinedPos(Target, 1.000, math.huge, myHero, false)
	local TargetDestination2, HitChance2 = CombinedPos(Target, 0.250, math.huge, myHero, false)
	if TargetDestination == nil or TargetDestination2 == nil then return end
	local TargetWaypoints = VP:GetCurrentWayPoints(Target)
	local Destination1 = TargetWaypoints[#TargetWaypoints]
	local Destination2 = TargetWaypoints[1]
	local Destination13D = {x=Destination1.x, y=myHero.y, z=Destination1.y}
	if TargetDestination ~= nil and HitChance >= 1 and HitChance2 >= 2 and GetDistance(Destination1, Destination2) > 100 then 
		if GetDistance(TargetDestination, Target) > 5 then
			local UnitVector = Vector(Vector(TargetDestination) - Vector(Target)):normalized()
			Endpoint1, Endpoint2, Diffunitvector = GenerateWallVector(Destination13D)
			local DisplacedVector = Vector(Target) + Vector(Vector(Destination13D) - Vector(Target)):normalized()*((Target.ms)*SpellE.Delay+110)
			local angle = UnitVector:angle(Diffunitvector)
			if angle ~= nil then
				--print('Angle Generated!' .. tostring(angle*57.2957795))
				if angle*57.2957795 < 105 and angle*57.2957795 > 75 and GetDistance(DisplacedVector, myHero) < SpellE.Range and EReady then
					CastSpell(_E, DisplacedVector.x, DisplacedVector.z)
				end
			end
		end
	elseif EReady and GetDistance(Destination2) < SpellE.Range and GetDistance(Destination1, Destination2) < 50 and GetDistance(TargetDestination, Destination13D) < 100 and VP:CountWaypoints(Target.networkID, os.clock() - 0.5) == 0 then
		CastSpell(_E, Destination13D.x, Destination13D.z)
	end
end

function JinxUltSpeed(Target)
	if Target ~= nil and ValidTarget(Target) then
		local Distance = GetDistance(Target)
		local Speed = (Distance > 1350 and (1350*1700+((Distance-1350)*2200))/Distance or 1700)
		return Speed
	end
end


--Credit Xetrok
function CountEnemyNearPerson(person,vrange)
    count = 0
    for i=1, heroManager.iCount do
        currentEnemy = heroManager:GetHero(i)
        if currentEnemy.team ~= myHero.team then
            if GetDistance(currentEnemy, person) <= vrange and not currentEnemy.dead then count = count + 1 end
        end
    end
    return count
end
--End Credit Xetrok

--Credit 

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8, round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
	quality = 2 * math.pi / quality
	radius = radius * .92
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

function DrawCircle2(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))

	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 100) 
	end
end


function CombinedPredict(Target, Delay, Width, Range, Speed, myHero, boolean)
  if Target == nil or Target.dead or not ValidTarget(Target) then return end
  if not ProdOneLoaded or not Config.Extras.Prodiction then
    local CastPosition, Hitchance, Position = VP:GetLineCastPosition(Target, Delay, Width, Range, Speed, myHero, boolean)
    if CastPosition ~= nil and Hitchance >= 1 then 
      return CastPosition, Hitchance+1, Position
    end
  elseif ProdOneLoaded and Config.Extras.Prodiction then
    local CastPosition, info = Prodiction.GetPrediction(Target, Range, Speed, Delay, Width, myHero)
    local isCol = false
    if info ~= nil and info.mCollision() ~= nil then
       isCol, _ = info.mCollision()
	    if Config.Extras.Debug and CastPosition ~= nil then
	    	print(CastPosition)
	    	print(isCol)
	    end
    end
    if info ~= nil and info.hitchance ~= nil and CastPosition ~= nil and isCol and boolean then
        return CastPosition, 0, CastPosition
    elseif info ~= nil and info.hitchance ~= nil and CastPosition ~= nil then 
        Hitchance = info.hitchance
        return CastPosition, Hitchance, CastPosition
    end
  end
end


function CombinedPos(Target, Delay, Speed, myHero, boolean)
  if Target == nil or Target.dead or not ValidTarget(Target) then return end

  if Collision == nil then Collision = false end
    if not ProdOneLoaded or not Config.Extras.Prodiction then
      local PredictedPos, HitChance = VP:GetPredictedPos(Target, Delay, Speed, myHero, boolean)
      return PredictedPos, HitChance
    elseif ProdOneLoaded and Config.Extras.Prodiction then
      local PredictedPos, info = Prodiction.GetPrediction(Target, 5000, Speed, Delay, 10, myHero)
      local isCol = false
      local hitchance = 0
      if info ~= nil and info.mCollision() ~= nil then
        isCol, _ = info.mCollision()
        hitchance = info.hitchance 
      end
      if PredictedPos ~= nil and info ~= nil and isCol and boolean then
        return PredictedPos, 0
      elseif PredictedPos ~= nil and info ~= nil and hitchance~= nil then
        return PredictedPos, hitchance
      end
    end
  end


