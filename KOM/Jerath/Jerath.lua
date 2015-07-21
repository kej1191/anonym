if myHero.charName ~= "Xerath" then return end
assert(load(Base64Decode("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"), nil, "bt", _ENV))() ScriptStatus("REHGKHLGLIF") 
local function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>Jerath:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end


local SCRIPT_INFO = {
	["Name"] = "Jerath",
	["Version"] = 1.02,
	["Author"] = {
		["KaoKaoNi"] = "http://forum.botoflegends.com/user/145247-"
	},
}
local SCRIPT_UPDATER = {
	["Activate"] = true,
	["Script"] = SCRIPT_PATH..GetCurrentEnv().FILE_NAME,
	["URL_HOST"] = "raw.github.com",
	["URL_PATH"] = "/kej1191/anonym/master/KOM/Jerath/Jerath.lua",
	["URL_VERSION"] = "/kej1191/anonym/master/KOM/Jerath/Jerath.version"
}
local SCRIPT_LIBS = {
	["SourceLib"] = "https://raw.github.com/LegendBot/Scripts/master/Common/SourceLib.lua",
	["HPrediction"] = "https://raw.githubusercontent.com/BolHTTF/BoL/master/HTTF/Common/HPrediction.lua",
	["VPrediction"] = ""
}


function Initiate()
	for LIBRARY, LIBRARY_URL in pairs(SCRIPT_LIBS) do
		if FileExist(LIB_PATH..LIBRARY..".lua") then
			require(LIBRARY)
		else
			DOWNLOADING_LIBS = true
			AutoupdaterMsg("Missing Library! Downloading "..LIBRARY..". If the library doesn't download, please download it manually.")
			DownloadFile(LIBRARY_URL,LIB_PATH..LIBRARY..".lua",function() AutoupdaterMsg("Successfully downloaded ("..LIBRARY") Thanks Use TEAM Y Teemo") end)
		end
	end
	if DOWNLOADING_LIBS then return true end
	if SCRIPT_UPDATER["Activate"] then
		SourceUpdater("<font color=\"#00A300\">"..SCRIPT_INFO["Name"].."</font>", SCRIPT_INFO["Version"], SCRIPT_UPDATER["URL_HOST"], SCRIPT_UPDATER["URL_PATH"], SCRIPT_UPDATER["Script"], SCRIPT_UPDATER["URL_VERSION"]):CheckUpdate()
	end
end
if Initiate() then return end
	
	
AdvancedCallback:bind('OnApplyBuff', function(source, unit, buff) OnApplyBuff(source, unit, buff) end)
--AdvancedCallback:bind('OnUpdateBuff', function(unit, buff, stack) OnUpdateBuff(unit, buff, stack) end)
AdvancedCallback:bind('OnRemoveBuff', function(unit, buff) OnRemoveBuff(unit, buff) end)

local STS = SimpleTS()

local Q = {}
local W = {}
local E = {}
local R = {}

local PassiveUp = false

local LastPing = 0;
local player = myHero

local RebornLoad, RevampedLoaded, MMALoad, SxOLoad = false, false, false, false;
local orbload = false

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
		elseif SacLoad then
			_G.AutoCarry.MyHero:AttacksEnabled(true)
		elseif SxOLoad then
			SxO:EnableAttacks()
		end
	elseif bool and orbload then
		if MMALoad then
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
		elseif SacLoad then
			_G.AutoCarry.MyHero:MovementEnabled(true)
		elseif SxOLoad then
			SxO:EnableMove()
		end
	elseif bool and orbload then
		if MMALoad then
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
	HPred = HPrediction()
	VP = VPrediction()
	
	Config = scriptConfig("Jerath", "Jerath")
		if SxOLoad then
			Config:addSubMenu("Orbwalking", "Orbwalking")
				SxO:LoadToMenu(Config.Orbwalking, Orbwalking)
		end
		
		Config:addSubMenu("Target selector", "STS")
			STS:AddToMenu(Config.STS)

		Config:addSubMenu("Combo", "Combo")
			Config.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
			Config.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			Config.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			Config.Combo:addParam("Erange",  "E range", SCRIPT_PARAM_SLICE, 1050, 0, 1050)
			Config.Combo:addParam("CastE", "Use E!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("O"))
			Config.Combo:addParam("Enabled", "Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			
		Config:addSubMenu("Harass", "Harass")
			Config.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
			Config.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
			Config.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
			
		Config:addSubMenu("RSnipe", "RSnipe")
			Config.RSnipe:addParam("AutoR2", "Use 1 charge (tap)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
			
			Config.RSnipe:addSubMenu("Alerter", "Alerter")
				Config.RSnipe.Alerter:addParam("Alert", "Draw \"Snipe\" on killable enemies", SCRIPT_PARAM_ONOFF , true)
				--Config.RSnipe.Alerter:addParam("Ping", "Ping if an enemy is killable", SCRIPT_PARAM_ONOFF , true)
				
			
		Config:addSubMenu("Farm", "Farm")
			Config.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, true)
			Config.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_ONOFF, false)
			Config.Farm:addParam("ManaCheck", "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
			Config.Farm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
		
		--[[Jungle farming]]
		Config:addSubMenu("JungleFarm", "JungleFarm")
			Config.JungleFarm:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			Config.JungleFarm:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			Config.JungleFarm:addParam("Enabled", "Farm jungle!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
			
		Config:addSubMenu("Draw", "Draw")
			Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawQColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawWColor", "Draw W Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawEColor", "Draw E Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
			Config.Draw:addParam("DrawRColor", "Draw R Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			
			
		Config:addSubMenu("Misc", "Misc")
			Config.Misc:addParam("WCenter", "Cast W centered", SCRIPT_PARAM_ONOFF, false)
			--Config.Misc:addParam("WMR", "Cast W at max range", SCRIPT_PARAM_ONOFF, false)
			Config.Misc:addParam("AutoEDashing", "Auto E on dashing enemies", SCRIPT_PARAM_ONOFF, true)
		
	
	Q  = { Range = 1400, MinRange = 750, MaxRange = 1400, Offset = 0, Width = 100, Delay = 0.6, Speed = math.huge, LastCastTime = 0, LastCastTime2 = 0, IsReady = function() return myHero:CanUseSpell(_Q) == READY end, Damage = function(target) return getDmg("Q", target, myHero) end, IsCharging = false, TimeToStopIncrease = 1.5 , End = 3, SentTime = 0, LastFarmCheck = 0, Sent = false}
	W  = { Range = 1100, Width = 125, Delay = 0.675, Speed = math.huge,  IsReady = function() return myHero:CanUseSpell(_W) == READY end}
	E  = { Range = 1050, Width = 60, Delay = 0.25, Speed = 1400, IsReady = function() return myHero:CanUseSpell(_E) == READY end}
	R  = { Range = function() return 2000 + 1200 * myHero:GetSpellData(_R).level end, Width = 120, Delay = 0.9, Speed = math.huge, LastCastTime = 0, LastCastTime2 = 0, Collision = false, IsReady = function() return myHero:CanUseSpell(_R) == READY end, Mana = function() return myHero:GetSpellData(_R).mana end, Damage = function(target) return getDmg("R", target, myHero) end, IsCasting = false, Stacks = 3, ResetTime = 10, MaxStacks = 3, Target = nil, SentTime = 0, Sent = false}
	
	Xerath_Q = HPSkillshot({type = "DelayLine", collisionM = false, collisionH = false, delay = Q.Delay, speed = Q.Speed, range = Q.Range, width = Q.Width*2})
	Xerath_W = HPSkillshot({type = "DelayCircle", delay = W.Delay, speed = W.Speed, range = W.Range, radius = W.Width*2})
	Xerath_E = HPSkillshot({type = "DelayLine", collisionM = true, collisionH = true, speed = E.Speed, range = E.Range, delay = E.Delay, width = E.Width*2})
	Xerath_R = HPSkillshot({type = "DelayCircle", delay = R.Delay, range = R.Range(), speed = R.Speed, radius = R.Width*2})
	
	EnemyMinions = minionManager(MINION_ENEMY, Q.MaxRange, myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, Q.MaxRange, myHero, MINION_SORT_MAXHEALTH_DEC)
end

function OnTick()
	if Config.Combo.Enabled then
		Combo()
	elseif Config.Harass.Enabled and ((myHero.mana / myHero.maxMana * 100) >= Config.Harass.ManaCheck ) then
		Harass()
	end
	if Config.RSnipe.AutoR2 and R.IsReady() then
		local target = FindBestTarget(mousePos, 500)
		CastR(target)
	end
	if Config.Combo.CastE then
		local ETarget = FindBestTarget(mousePos, 500)
		if ETarget then
			CastE(ETarget)
		end
	end
	if Config.Farm.Enabled and ((myHero.mana / myHero.maxMana * 100) >= Config.Farm.ManaCheck or Q:IsCharging()) then
		Farm()
	end

	if Config.JungleFarm.Enabled then
		JungleFarm()
	end
	
	if Config.Misc.AutoEDashing then
		for i, target in ipairs(SelectUnits(GetEnemyHeroes(), function(t) return ValidTarget(t, E.Range * 1.5) end)) do
			CastIfDashing(target)
		end
	end
	--[[
	if Config.RSnipe.Alerter.Ping and R.IsReady and (os.clock() - LastPing > 30) then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, R.MaxRange) and (enemy.health -  R.Damage(enemy) * R.Stacks) / enemy.maxHealth then
				for i = 1, 3 do
					DelayAction(function() PingSignal(PING_NORMAL, enemy.x, enemy.y, enemy.z, 2) end,  50)
				end
				LastPing = os.clock()
			end
		end
	end
	]]
	if R.IsCasting and orbload then
		BlockAA(true)
		BlockMV(true)
	elseif not R.IsCasting and orbload then
		BlockAA(false)
		BlockMV(false)
	end
end	

function Combo()
	local QTarget = STS:GetTarget(Q.MaxRange)
	local WTarget = STS:GetTarget(W.Range + W.Width)
	local ETarget = STS:GetTarget(Config.Combo.Erange)

	local AAtarget = OrbTarget(450)
	if orbload then BlockAA(true) end

	if (AAtarget and AAtarget.health < 200) or PassiveUp and orbload then
		BlockAA(false)
	end

	if WTarget and Config.Combo.UseW then
		if Config.Misc.WCenter then
			W.Width = 50
		else
			W.Width = 125
		end
		CastW(WTarget)
	end

	if ETarget and Config.Combo.UseE then
		CastE(ETarget)
	end
	
	if QTarget and Config.Combo.UseQ then
		CastQ(QTarget)
	end
end

function Harass()
	local QTarget = STS:GetTarget(Q.MaxRange)
	if QTarget and Config.Harass.UseQ then
		CastQ(QTarget)
	end
end

function Farm()
	EnemyMinions:update()
	if Config.Farm.UseQ then
		local BestPos, BestHit, BestObj = GetBestLineFarmPosition(Q.MaxRange, Q.Width, EnemyMinions.objects)
		if BestPos ~= nil and BestHit ~= nil and BestObj ~= nil then
			CastQ(BestObj)
		end		
	end

	if Config.Farm.UseW then
		local BestPos, BestHit = GetBestCircularFarmPosition(W.Range, W.Width, EnemyMinions.objects)
		if BestHit ~= nil and BestPos ~= nil then
			CastSpell(_W, BestPos.x, BestPos.z)
		end
	end
end

function JungleFarm()
	JungleMinions:update()
	if JungleMinions.objects[1] ~= nil then
		if Config.JungleFarm.UseQ and GetDistance(JungleMinions.objects[1]) <= Q.MaxRange and Q.IsReady() then
			CastQ(JungleMinions.objects[1])
		end

		if Config.JungleFarm.UseW and W.IsReady() then
			CastSpell(_W, JungleMinions.objects[1].x, JungleMinions.objects[1].z)
		end
	end
end

function OnDraw()
	if player.dead then return end
	if Q.IsReady() and Config.Draw.DrawQ then
		DrawCircle(player.x, player.y, player.z, Q.MaxRange, TARGB(Config.Draw.DrawQColor))
	end

	if W.IsReady() and Config.Draw.DrawW then
		DrawCircle(player.x, player.y, player.z, W.Range, TARGB(Config.Draw.DrawWColor))
	end

	if E.IsReady() and Config.Draw.DrawE then
		DrawCircle(player.x, player.y, player.z, Config.Combo.Erange, TARGB(Config.Draw.DrawEColor))
	end

	if R.IsReady() and Config.Draw.DrawR then
		DrawCircle(player.x, player.y, player.z, R.Range(), TARGB(Config.Draw.DrawRColor))
	end
	
	if Config.RSnipe.Alerter.Alert and myHero:GetSpellData(_R).level > 0 then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, R.range) and (enemy.health -  R.Damage(enemy) * R.Stacks) / enemy.maxHealth then
				local pos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
				DrawText("Snipe!", 17, pos.x, pos.y, ARGB(255,0,255,0))
			end
		end
	end 
end

function CastIfDashing(target)
    local isDashing, canHit, position = VP:IsDashing(target, E.Delay + 0.07 + GetLatency() / 2000, E.Width, E.Speed, player)
    if isDashing and canHit and position ~= nil and E.IsReady() then
        if not VP:CheckMinionCollision(target, position, E.Delay + 0.07 + GetLatency() / 2000, E.Width, E.Range, E.Speed, player, false, true) then
            return CastSpell(_E, position.x, position.z)
        end
	end
end

function CastQ(target)
    if Q.IsReady() and ValidTarget(target) then
		delay = math.max(GetDistance(myHero, target) - Q.MinRange, 0) / ((Q.MaxRange - Q.MinRange) / Q.TimeToStopIncrease) + Q.Delay
        if not Q.IsCharging then
            local Pos, HitChance = HPred:GetPredict(Xerath_Q, target, myHero)
            if Pos~=nil and HitChance > 1.4 and GetDistanceSqr(myHero, Pos) < Q.MaxRange * Q.MaxRange then
                CastQ1(Pos)
            end
        elseif Q.IsCharging and ValidTarget(target, Q.Range) and Q.LastCastTime + delay < os.clock() then
            local Pos, HitChance = HPred:GetPredict(Xerath_Q, target, myHero)
            if Pos~=nil and HitChance > 1.4 then
                CastQ2(Pos)
            elseif os.clock() - Q.LastCastTime >= 0.9 * Q.End and GetDistanceSqr(myHero, target) <= Q.Range * Q.Range then
                CastQ2(Pos)
            end
        end
    end
end

function CastQ1(Pos)
    if Q.IsReady() and Pos and not Q.IsCharging then
        CastSpell(_Q, Pos.x, Pos.z)
    end
end

function CastQ2(Pos)
    if Q.IsReady() and Pos and Q.IsCharging then
        local d3vector = D3DXVECTOR3(Pos.x, Pos.y, Pos.z)
        Q.Sent = true
        CastSpell2(_Q, d3vector)
        Q.Sent = false
    end
end

function CastW(target)
	if target ~= nil then
		local Pos, HitChance = HPred:GetPredict(Xerath_W, target, myHero)
		if Pos ~= nil and HitChance ~= nil then
			if HitChance >= 1.4 then
				CastSpell(_W, Pos.x, Pos.z)
			end
		end
	end
end

function CastE(target)
	if target ~= nil then
		local Pos, HitChance = HPred:GetPredict(Xerath_E, target, myHero)
		if Pos ~= nil and HitChance ~= nil then
			if HitChance >= 0.8 then
				CastSpell(_E, Pos.x, Pos.z)
			end
		end
	end
end

function CastR(target)
    if R.IsReady() and ValidTarget(target, R.Range()) then
        if not R.IsCasting then 
            CastR1()
        else
            CastR2()
        end
    end
end

function CastR1()
    if not R.IsCasting and R.IsReady() then 
		CastSpell(_R) 
	end
end

function CastR2()
    if R.IsCasting and R.IsReady() then
        local target = nil
		target = FindBestTarget(mousePos, 500)
        if ValidTarget(target) then
            local Pos, HitChance = HPred:GetPredict(Xerath_R, target, myHero)
			if Pos ~= nil and HitChance >= 2 then
				CastSpell(_R, Pos.x, Pos.z)
			end
        end
    end
end

function FindBestTarget(from, range)
    local bestTarget = nil
    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, R.Range()) and GetDistanceSqr(from, enemy) <= range * range then
            if bestTarget == nil then
                bestTarget = enemy
            end
			if (enemy.health -  R.Damage(enemy) * R.Stacks) / enemy.maxHealth < (bestTarget.health - R.Damage(bestTarget) * R.Stacks) / bestTarget.maxHealth  then
                bestTarget = enemy
            end
        end
    end
    return bestTarget
end

function OnApplyBuff(source, unit, buff)
	if unit.isMe and buff.name == "xerathascended2onhit" then
		PassiveUp = true
	end
end

function OnRemoveBuff(unit, buff)
	if unit.isMe and buff.name == "xerathascended2onhit" then
		PassiveUp = false
	end
end


function OnCreateObj(obj)
	if obj and obj.name:lower():find("xerath") and obj.name:lower():find("_q") and obj.name:lower():find("_cas") and obj.name:lower():find("_charge") then
		Q.IsCharging = true
	end
end

function OnDeleteObj(obj)
	if obj and obj.name:lower():find("xerath") and obj.name:lower():find("_q") and obj.name:lower():find("_cas") and obj.name:lower():find("_charge") then
		Q.IsCharging = false
	end
end

function OnProcessSpell(unit, spell)
	if myHero.dead or Config == nil or unit == nil or not unit.isMe then return end
	if spell.name:lower():find("xeratharcanopulsechargeup") then 
		Q.LastCastTime = os.clock()
		Q.IsCharging = true
	elseif spell.name:lower():find("xeratharcanopulse2") then 
		Q.LastCastTime2 = os.clock()
		Q.IsCharging = false
	elseif spell.name:lower():find("xerathlocusofpower2") then 
        R.LastCastTime = os.clock()
        R.IsCasting = true
        R.LastCastTime2 = os.clock()
		DelayAction(function() R.Stacks = R.MaxStacks R.Target = nil R.IsCasting = false end, R.ResetTime)
    elseif spell.name:lower():find("xerathrmissilewrapper") then 
	elseif spell.name:lower():find("xerathlocuspulse") then
		R.LastCastTime2 = os.clock()
		R.Stacks = R.Stacks - 1
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