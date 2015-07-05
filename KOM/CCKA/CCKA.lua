

class('AOW')
require 'sourceLib'

local Q = {Range = 800, IsReady = function() return myHero:CanUseSpell(_Q) == READY end,}
local W = {Range = 450, IsReady = function() return myHero:CanUseSpell(_W) == READY end,}
local E = {Range = 1100, IsReady = function() return myHero:CanUseSpell(_E) == READY end,}
local R = {Range = 250, IsReady = function() return myHero:CanUseSpell(_R) == READY end,}
local AS = {Range = 375}

local lastAttack, lastWindUpTime, lastAttackCD = 0, 0, 0
local myTrueRange =0;
local OrbTarget = 0;

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
			--Config.HotKey:addParam("Harass", "Harass", SCRIPT_PARAM_ONOFF, false, string.byte('V'))
			Config.HotKey:addParam("Escape", "Escape", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('G'))
			
		Config:addSubMenu("Combo", "Combo")
			Config.Combo:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			Config.Combo:addParam("UseW", "UseW", SCRIPT_PARAM_ONOFF, true)
		
		Config:addSubMenu("Harass", "Harass")
			Config.Harass:addParam("UseQ", "UseQ", SCRIPT_PARAM_ONOFF, true)
			Config.Harass:addParam("UseW", "UseW", SCRIPT_PARAM_ONOFF, true)
		
		Config:addSubMenu("Q", "Q")
			Config.Q:addParam("MinNum", "Use Q can under attack number", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
		
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
		DrawCircle(azir.x, azir.y, azir.z, AS.Range, TARGB(Config.Draw.DrawSColor))
	end
end

function OnCombo()
	local t = STS:GetTarget(myTrueRange+AS.Range)
	if t ~= nil then
		if GetDistance(t) > AS.Range and Q.IsReady() and Config.Combo.UseQ then
			if Config.Q.MinNum <= ClosetSoldier(t) then
				CastQ(t)
			end
		end
		if W.IsReady() and Config.Combo.UseW then CastW(t) end
	end
end

function OnHarass()
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
		if GetDistance(soldier, target) < AS.Range then
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
		
	AddTickCallback(function() self:OrbWalk() end)
	AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
end

function AOW:OnProcessSpell(unit, spell)
	if unit == myHero then
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime+1000
			lastAttackCD = spell.animationTime+1000
		end
	end
end

function AOW:OrbWalk()
	if self.menu.Combo then
		OrbTarget = STS:GetTarget(myTrueRange+AS.Range)
		if OrbTarget ~= nil then
			if self.tiemToShoot() then
				if #AzirSoldier ~= 0 then
					for i, j in pairs(AzirSoldier) do 
						if GetDistance(j) < AS.Range+myTrueRange then
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

--[[
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
end]]