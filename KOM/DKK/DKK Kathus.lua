if not VIP_USER or myHero.charName ~= "Karthus" then return end

require 'DivinePred'


AdvancedCallback:bind('OnApplyBuff', function(source, unit, buff) OnApplyBuff(source, unit, buff) end)
AdvancedCallback:bind('OnUpdateBuff', function(unit, buff, stack) OnUpdateBuff(unit, buff, stack) end)
AdvancedCallback:bind('OnRemoveBuff', function(unit, buff) OnRemoveBuff(unit, buff) end)

local Q = {name = "Lay Waste", Range = 875, IsReady = function() return myHero:CanUseSpell(_Q) == READY end,}
local W = {name = "Wall of Pain", Range = 1000, IsReady = function() return myHero:CanUseSpell(_W) == READY end,}
local E = {name = "Defile", Range = 550, Active = false, IsReady = function() return myHero:CanUseSpell(_E) == READY end,}
local R = {name = "Requiem", IsReady = function() return myHero:CanUseSpell(_R) == READY end,}

local RebornLoad, RevampedLoaded, MMALoad, SxOLoad = false, false, false, false;

local enemyTable = {}

local player = myHero

local c_red = 0xFFFF0000
local c_yellow = 0xFFFFFF00

local recall, dead = false, false
local STS = nil

local KathusQ = CircleSS(math.huge,875,200,600,math.huge)
local KathusW = CircleSS(math.huge,1000,10,160,math.huge)

function OnOrbLoad()
	if _G.MMA_LOADED then
		--AutoupdaterMsg("MMA LOAD")
		MMALoad = true
	elseif _G.AutoCarry then
		if _G.AutoCarry.Helper then
			--AutoupdaterMsg("SIDA AUTO CARRY: REBORN LOAD")
			RebornLoad = true
		else
			--AutoupdaterMsg("SIDA AUTO CARRY: REVAMPED LOAD")
			RevampedLoaded = true
		end
	elseif _G.Reborn_Loaded then
		SacLoad = true
		DelayAction(OnOrbLoad, 1)
	elseif FileExist(LIB_PATH .. "SxOrbWalk.lua") then
		--AutoupdaterMsg("SxOrbWalk Load")
		require 'SxOrbWalk'
		SxO = SxOrbWalk()
		SxOLoad = true
	end
end


function OnLoad()
	STS = SimpleTS()
	dp = DivinePred()
	OnOrbLoad()
	OnLoadMenu()
	
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team ~= myHero.team then
			info = {unit = hero, statu = "Can't", color = c_yellow,}
			table.insert(enemyTable, info)
		end
	end 
	
	if GetGame().map.shortName == "twistedTreeline" then
		JungleMobNames = {
			["SRU_MurkwolfMini2.1.3"]	= true,
			["SRU_MurkwolfMini2.1.2"]	= true,
			["SRU_MurkwolfMini8.1.3"]	= true,
			["SRU_MurkwolfMini8.1.2"]	= true,
			["SRU_BlueMini1.1.2"]		= true,
			["SRU_BlueMini7.1.2"]		= true,
			["SRU_BlueMini21.1.3"]		= true,
			["SRU_BlueMini27.1.3"]		= true,
			["SRU_RedMini10.1.2"]		= true,
			["SRU_RedMini10.1.3"]		= true,
			["SRU_RedMini4.1.2"]		= true,
			["SRU_RedMini4.1.3"]		= true,
			["SRU_KrugMini11.1.1"]		= true,
			["SRU_KrugMini5.1.1"]		= true,
			["SRU_RazorbeakMini9.1.2"]	= true,
			["SRU_RazorbeakMini9.1.3"]	= true,
			["SRU_RazorbeakMini9.1.4"]	= true,
			["SRU_RazorbeakMini3.1.2"]	= true,
			["SRU_RazorbeakMini3.1.3"]	= true,
			["SRU_RazorbeakMini3.1.4"]	= true
		}

		FocusJungleNames = {
			["SRU_Blue1.1.1"]			= true,
			["SRU_Blue7.1.1"]			= true,
			["SRU_Murkwolf2.1.1"]		= true,
			["SRU_Murkwolf8.1.1"]		= true,
			["SRU_Gromp13.1.1"]			= true,
			["SRU_Gromp14.1.1"]			= true,
			["Sru_Crab16.1.1"]			= true,
			["Sru_Crab15.1.1"]			= true,
			["SRU_Red10.1.1"]			= true,
			["SRU_Red4.1.1"]			= true,
			["SRU_Krug11.1.2"]			= true,
			["SRU_Krug5.1.2"]			= true,
			["SRU_Razorbeak9.1.1"]		= true,
			["SRU_Razorbeak3.1.1"]		= true,
			["SRU_Dragon6.1.1"]			= true,
			["SRU_Baron12.1.1"]			= true
		}
	else
		FocusJungleNames = {
			["TT_NWraith1.1.1"]			= true,
			["TT_NGolem2.1.1"]			= true,
			["TT_NWolf3.1.1"]			= true,
			["TT_NWraith4.1.1"]			= true,
			["TT_NGolem5.1.1"]			= true,
			["TT_NWolf6.1.1"]			= true,
			["TT_Spiderboss8.1.1"]		= true
		}
		JungleMobNames = {
			["TT_NWraith21.1.2"]		= true,
			["TT_NWraith21.1.3"]		= true,
			["TT_NGolem22.1.2"]			= true,
			["TT_NWolf23.1.2"]			= true,
			["TT_NWolf23.1.3"]			= true,
			["TT_NWraith24.1.2"]		= true,
			["TT_NWraith24.1.3"]		= true,
			["TT_NGolem25.1.1"]			= true,
			["TT_NWolf26.1.2"]			= true,
			["TT_NWolf26.1.3"]			= true
		}
	end
	enemyJungles = minionManager(MINION_JUNGLE, 975, myHero, MINION_SORT_MAXHEALTH_DEC)
	enemyMinions = minionManager(MINION_ENEMY, 975, myHero, MINION_SORT_MAXHEALTH_DEC)
end

function OnLoadMenu()
	Config = scriptConfig("Your Kathus", "Kathus")
	
		Config:addSubMenu("TargetSelector", "TargetSelector")
			STS:AddToMenu(Config.TargetSelector)
		
		Config:addSubMenu("HotKey", "HotKey")
			Config.HotKey:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			Config.HotKey:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
			Config.HotKey:addParam("HarassToggle", "HarassToggle", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("G"))
			Config.HotKey:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
			Config.HotKey:addParam("Clear", "Clear", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
		
		Config:addSubMenu("Combo", "Combo")
			Config.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			Config.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			Config.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			
		Config:addSubMenu("Harass", "Harass")
			Config.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			Config.Harass:addParam("Qmana","Q mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			Config.Harass:addParam("Qinfo", "", SCRIPT_PARAM_INFO, "")
			Config.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			Config.Harass:addParam("Wmana","W mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			Config.Harass:addParam("Winfo", "", SCRIPT_PARAM_INFO, "")
			Config.Harass:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			Config.Harass:addParam("Emana","E mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			Config.Harass:addParam("Einfo", "", SCRIPT_PARAM_INFO, "")
			
		Config:addSubMenu("LineClear", "LineClear")
			Config.LineClear:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			Config.LineClear:addParam("Qmana", "Until % Q", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			Config.LineClear:addParam("Qinfo", "", SCRIPT_PARAM_INFO, "")
			Config.LineClear:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			Config.LineClear:addParam("Emana","E mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			
		Config:addSubMenu("JungleClear", "JungleClear")
			Config.JungleClear:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			Config.JungleClear:addParam("Qmana", "Until % Q", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			Config.JungleClear:addParam("Qinfo", "", SCRIPT_PARAM_INFO, "")
			Config.JungleClear:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			Config.JungleClear:addParam("Emana","E mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			
		Config:addSubMenu("Farm", "Farm")
			Config.Farm:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			Config.Farm:addParam("Qmana", "Until % Q", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
		
			
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
			Config.Draw:addParam("info4", "Other", SCRIPT_PARAM_INFO, "")
			Config.Draw:addParam("DrawKillmark","Draw KillMark", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawDmgMark", "Draw Damage Mark", SCRIPT_PARAM_ONOFF, true)
			
		Config:addSubMenu("KillMark", "KillMark")
			Config.KillMark:addParam("XPos", "X Pos", SCRIPT_PARAM_SLICE, 100, 0, WINDOW_W, 0)
			Config.KillMark:addParam("YPos", "Y Pos", SCRIPT_PARAM_SLICE, 100, 0, WINDOW_H, 0)
			
		Config:addSubMenu("["..Q.name.."] Setting", "Q")
		
		Config:addSubMenu("["..W.name.."] Setting", "W")
			Config.W:addParam("UseInQRange", "Use W in Q range", SCRIPT_PARAM_ONOFF, false)
			
		Config:addSubMenu("["..E.name.."] Setting", "E")
			Config.E:addParam("autoff", "Auto off", SCRIPT_PARAM_ONOFF, true)
			Config.E:addParam("UseEmanaSaveManager", "Use E mana Save manager", SCRIPT_PARAM_ONOFF, true)
			
		Config:addSubMenu("["..R.name.."] Setting", "R")
		
		Config:addSubMenu("Misc", "Misc")
			Config.Misc:addParam("PassiveManager", "Cast Spell when in passive time", SCRIPT_PARAM_ONOFF, true)
end

function OnTick()
	if dead then OnPassive() end
	if player.dead then return end
	if Config.HotKey.Combo then OnCombo() end
	if Config.HotKey.Harass or Config.HotKey.HarassToggle then OnHarass() end
	if Config.HotKey.Clear then OnClear() end
	if Config.HotKey.Farm then OnFarm() end
	if E.Active then if Config.E.UseEmanaSaveManager then CastSpell(_E) end end 
	checkTick()
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
	
	if Config.Draw.DrawKillmark then
		for j, unit in pairs(enemyTable) do
			DrawText(unit.unit.charName.." can kill with R? | ", 18, Config.KillMark.XPos, Config.KillMark.YPos+(j*20), unit.color)
			DrawText(unit.statu, 18, Config.KillMark.XPos+200, Config.KillMark.YPos+(j*20), unit.color)
			DrawText("Missing? | "..tostring(ValidTarget(unit.unit)), 18, Config.KillMark.XPos+300, Config.KillMark.YPos+(j*20), unit.color)
		end
	end
	
	for i, j in ipairs(GetEnemyHeroes()) do
		if GetDistance(j) < 2000 and not j.dead and Config.Draw.DrawDmgMark and ValidTarget(j) then
			local pos = GetHPBarPos(j)
			local dmg, Qdamage = GetSpellDmg(j)
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

function GetSpellDmg(enemy)
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

function OnCombo()
	local target = STS:GetTarget(Q.Range)
	if target ~= nil then
		if Config.Combo.UseQ then CastQ(target) end
		if Config.Combo.UseW then CastW(target) end
		if Config.Combo.UseE then CastE() end
	end
end

function OnHarass()
	if recall then return end
	local target = STS:GetTarget(Q.Range)
	if target ~= nil then
		if Config.Harass.UseQ then
			if player.mana > player.maxMana*(Config.Harass.Qmana*0.01) then	
				CastQ(target)
			end 
		end
		if Config.Harass.UseE then
			if player.mana > player.maxMana*(Config.Harass.Emana*0.01) then
				CastE()
			end
		end
	end
end

function OnClear()
	enemyJungles:update()
	for i, minion in pairs(enemyJungles.objects) do
		if minion ~= nil and not minion.dead and GetDistance(minion) < 975 and Config.JungleClear.UseQ and player.mana > (player.maxMana*(Config.JungleClear.Qmana*0.01)) then
			local bestpos, besthit = GetBestCircularFarmPosition(875, 200, enemyJungles.objects)
			if bestpos ~= nil then
				CastSpell(_Q, bestpos.x, bestpos.z)
			end
		end
	end
	enemyMinions:update()
	for i, minion in pairs(enemyMinions.objects) do
		if minion ~= nil and not minion.dead and GetDistance(minion) < 975 and Config.LineClear.UseQ and player.mana > (player.maxMana*(Config.LineClear.Qmana*0.01)) then
			local bestpos, besthit = GetBestCircularFarmPosition(875, 200, enemyMinions.objects)
			if bestpos ~= nil then
				CastSpell(_Q, bestpos.x, bestpos.z)
			end
		end
	end
end

function OnPassive()
	local target = STS:GetTarget(Q.Range)
	if target ~= nil and Config.Misc.PassiveManager then
		if R.IsReady() then CastSpell(_R) end
		CastQ(target)
		CastW(target)
	end
end

function OnFarm()
	enemyMinions:update()
	for i, minion in ipairs(enemyMinions.objects) do
		if GetDistance(minion) <= 875 and Q.IsReady() and Config.Farm.UseQ then
			if player.mana > player.maxMana*(Config.Farm.Qmana*0.01) then
				local bestpos, besthit = GetBestCircularFarmPosition(875, 200, enemyMinions.objects)
				if besthit == 1 then
					if getDmg("Q", minion, player) > minion.health then
						CastQ(minion)
					end
				elseif besthit > 1 then
					if getDmg("Q", minion, player)*0.5 > minion.health then
						CastQ(minion)
					end
				end
			end
		end
	end
end

function CastQ(target)
	if not Q.IsReady() then return end
	local Target = DPTarget(target)
	local state,hitPos,perc = dp:predict(Target,KathusQ)
	if state == SkillShot.STATUS.SUCCESS_HIT then
		CastSpell(_Q,hitPos.x,hitPos.z)
	end
end

function CastW(target)
	if not W.IsReady() then return end
	if Config.W.UseInQRange then if GetDistance(target, player) > 875 then return end end
	local Target = DPTarget(target)
	local state,hitPos,perc = dp:predict(Target,KathusW)
	if state == SkillShot.STATUS.SUCCESS_HIT then
		CastSpell(_W,hitPos.x,hitPos.z)
	end
end

function CastE()
	if CountEnemyHeroInRange(E.Range) >= 1 and not E.Active then
		CastSpell(_E)
	elseif CountEnemyHeroInRange(E.Range) == 0 and E.Active then
		CastSpell(_E)
	end
end


function checkTick()
	for i, unit in ipairs(enemyTable) do
		if getDmg("R", unit.unit, myHero) > unit.unit.health and not unit.unit.dead then
			unit.statu = "Can"
			unit.color = c_red
		elseif getDmg("R", unit.unit, myHero) < unit.unit.health and not unit.unit.dead then
			unit.statu = "Can't"
			unit.color = c_yellow
		elseif unit.unit.dead then
			unit.statu = "Dead"
			unit.color = c_yellow
		end
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

function OnApplyBuff(source, unit, buff)
	if unit and unit.isMe and buff.name == "KarthusDefile" then
		E.Active = true
    end
	if unit and unit.isMe and buff.name == "recall" then
		recall = true
    end
	if unit and unit.isMe and buff.name == "KarthusDeathDefiedBuff" then
		dead = true
	end
end

function OnRemoveBuff(unit, buff)
    if unit and unit.isMe and buff.name == "KarthusDefile" then
        E.Active = false
    end
	if unit and unit.isMe and buff.name == "recall" then
		recall = false
    end
	if unit and unit.isMe and buff.name == "KarthusDeathDefiedBuff" then
		dead = false
	end
end

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

function SimpleTS:__init(mode)
    self.mode = mode and mode or STS_LESS_CAST_PHYSICAL
    AddDrawCallback(function() self:OnDraw() end)
    AddMsgCallback(function(msg, key) self:OnMsg(msg, key) end)
end

function SimpleTS:IsValid(target, range, selected)
    if ValidTarget(target) and (_GetDistanceSqr(target) <= range or (self.hitboxmode and (_GetDistanceSqr(target) <= (math.sqrt(range) + self.VP:GetHitBox(myHero) + self.VP:GetHitBox(target)) ^ 2))) then
        if selected or (not (HasBuff(target, "UndyingRage") and (target.health == 1)) and not HasBuff(target, "JudicatorIntervention")) then
            return true
        end
    end
end

function SimpleTS:AddToMenu(menu)
    self.menu = menu
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

function SimpleTS:SelectedTarget()
    return self.STarget
end

function SimpleTS:GetTarget(range, n, forcemode)
    assert(range, "SimpleTS: range can't be nil")
    range = range * range
    local PosibleTargets = {}
    local selected = self:SelectedTarget()

    if self.menu then
        self.mode = STS_AVAILABLE_MODES[self.menu.mode]
        if self.menu.Selected and selected and selected.type == player.type and self:IsValid(selected, range, true) then
            return selected
        end
    end

    for i, enemy in ipairs(GetEnemyHeroes()) do
        if self:IsValid(enemy, range) then
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

function _GetDistanceSqr(p1, p2)

    p2 = p2 or player
    if p1 and p1.networkID and (p1.networkID ~= 0) and p1.visionPos then p1 = p1.visionPos end
    if p2 and p2.networkID and (p2.networkID ~= 0) and p2.visionPos then p2 = p2.visionPos end
    return GetDistanceSqr(p1, p2)
    
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

function TARGB(colorTable)
    assert(colorTable and type(colorTable) == "table" and #colorTable == 4, "TARGB: colorTable is invalid!")
    return ARGB(colorTable[1], colorTable[2], colorTable[3], colorTable[4])
end
