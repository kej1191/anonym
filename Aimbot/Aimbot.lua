local Author = "KaoKaoNi"
local Version = "1.0"

function ScriptMsg(msg)
  print("<font color=\"#daa520\"><b>Aimbot:</b></font> <font color=\"#FFFFFF\">"..msg.."</font>")
end

local SCRIPT_INFO = {
	["Name"] = "AimBot",
	["Version"] = 1.0,
	["Author"] = {
		["Your"] = "http://forum.botoflegends.com/user/145247-"
	},
}
local SCRIPT_UPDATER = {
	["Activate"] = true,
	["Script"] = SCRIPT_PATH..GetCurrentEnv().FILE_NAME,
	["URL_HOST"] = "raw.github.com",
	["URL_PATH"] = "/kej1191/anonym/master/Aimbot/Aimbot.lua",
	["URL_VERSION"] = "/kej1191/anonym/master/Aimbot/version/Aimbot.version"
}
local SCRIPT_LIBS = {
	["HPrediction"] = "https://raw.githubusercontent.com/BolHTTF/BoL/master/HTTF/Common/HPrediction.lua"
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

local Spell_Q = {
	['Aatrox'] = {Type = "PromptCircle", Name = "Dark Flight", Range = 600, Delay = 0.25, Speed = 1800, Width = 280, CollisionM = false, CollisionH = false},
	['Ahri'] = {Type = "DelayLine", Name = "Orb of Deception", Range = 840, Delay = 0.25, Speed = 1600, Width = 90, CollisionM = false, CollisionH = false},
	['Amumu'] = {Type = "DelayLine",Name = "Bandage Toss", Range = 1100, Delay = 0.25, Speed = 2000, Width = 80, CollisionM = true, CollisionH = true},
	['Anivia'] = {Type = "DelayLine",Name = "Flash Frost", Range = 1100, Delay = 0.25, Speed = 850, Width = 150,CollisionM = false, CollisionH = false},
	['Azir'] = {Type = "DelayLine", Name = "Shifting Sands", Range = 800, Delay = 0.25, Speed = 500, Width = 100,CollisionM = false, CollisionH = false,},
	['Bard'] = {Type = "DelayLine", Name = "Cosmic Binding", Range = 850, Delay = 0.25, Speed = 1100, Width = 108,CollisionM = true, CollisionH = false,},
	['Blitzcrank'] = {Type = "DelayLine", Name = "Rocket Grab", Range = 1050, Delay = 0.25, Speed = 1800, Width = 70,CollisionM = true, CollisionH = true,},
	['Brand'] = {Type = "DelayLine", Name = "Sear", Range = 1050, Delay = 0.5, Speed = 1200, Width = 80,CollisionM = true, CollisionH = true,},
	['Braum'] = {Type = "DelayLine", Name = "Winters Bite", Range = 950, Delay = 0.25, Speed = 1700, Width = 100,CollisionM = true, CollisionH = true,},
}

local Spell_W = {
	['Anivia'] = {Type = "PromptLine", Name = "Crystallize", Range = 1000, Delay = 0.5, Speed = math.huge, Width = 10, CollisionM = false, CollisionH = false},
	--['Ashe'] = {Type = "DelayLine", Name = "Volley", Range = 1200, Delay = 0.25, Speed = 2000, Width = 50,CollisionM = true,CollisionH = true,},
	['Brand'] = {Type = "DelayCircle", Name = "Pilla of Flame", Range = 1050, Delay = 0.25, Speed = 900, Width = 275,CollisionM = false, CollisionH = false,},
	
}

local Spell_E = {
	['Aatrox'] = {Type = "DelayLine", Name = "Blades of Torment", Range = 975, Delay = 0.25, Speed =1200 , Width = 80, CollisionM = false, CollisionH = false},
	['Ahri'] = {Type = "DelayLine", Name = "Charm", Range = 975, Delay = 0.25, Speed = 1500, Width = 100, CollisionM = false, CollisionH = false},
}

local Spell_R = {
	['Anivia'] = {Type = "DelayLine", Name = "Glacial Storm", Range = 625, Delay = 0.25, Speed = math.huge, Width = 210, CollisionM = false, CollisionH = false},
	['Ashe'] = {Type = "DelayLine", Name = "Enchanted Crystal Arrow", Range = math.huge, Delay = 0.25, Speed = 1600, Width = 130, CollisionM = false, CollisionH = true},
}

local Chargingspell = {}

--[''] = {Type = "", Name = "", Range = , Delay = , Speed = , Width = ,CollisionM = , CollisionH = ,},

local Champ = myHero.charName
local player = myHero
local UseQ, UseW, UseE, UseR = nil, nil, nil, nil
local STS

function OnLoad()
	HPred = HPrediction()
	
	STS = SimpleTS(STS_NEARMOUSE)
	ScriptMsg(Champ.." Load. Good Luck To You")
	if Spell_Q[Champ] ~= nil then
		Q = Spell_Q[Champ]
		UseQ = Q.Name
		if Q.Type:find("Line") then
			HPred:AddSpell("Q", Champ,{type = Q.Type, delay = Q.Delay, range = Q.Range, speed = Q.Speed, width = Q.Width*2, collisionM = Q.collisionM, collisionH = Q.collisionH})
		elseif Q.Type:find("Circle") then
			HPred:AddSpell("Q", Champ,{type = Q.Type, delay = Q.Delay, range = Q.Range, speed = Q.Speed, radius = Q.Width*2, collisionM = Q.collisionM, collisionH = Q.collisionH})
		end
	end
	if Spell_W[Champ] ~= nil then
		W = Spell_W[Champ]
		UseW = Spell_W[Champ].Name
		if W.Type:find("Line") then
			HPred:AddSpell("W", Champ,{type = W.Type, delay = W.Delay, range = W.Range, speed = W.Speed, width = W.Width*2, collisionM = W.collisionM, collisionH = W.collisionH})
		elseif W.Type:find("Circle") then
			HPred:AddSpell("W", Champ,{type = W.Type, delay = W.Delay, range = W.Range, speed = W.Speed, radius = W.Width*2, collisionM = W.collisionM, collisionH = W.collisionH})
		end
	end
	if Spell_E[Champ] ~= nil then
		E = Spell_E[Champ]
		UseE = Spell_E[Champ].Name
		if E.Type:find("Line") then
			HPred:AddSpell("E", Champ,{type = E.Type, delay = E.Delay, range = E.Range, speed = E.Speed, width = E.Width*2, collisionM = E.collisionM, collisionH = E.collisionH})
		elseif E.Type:find("Circle") then
			HPred:AddSpell("E", Champ,{type = E.Type, delay = E.Delay, range = E.Range, speed = E.Speed, radius = E.Width*2, collisionM = E.collisionM, collisionH = E.collisionH})
		end
	end
	if Spell_R[Champ] ~= nil then
		R = Spell_R[Champ]
		UseR = Spell_R[Champ].Name
		if R.Type:find("Line") then
			HPred:AddSpell("R", Champ,{type = R.Type, delay = R.Delay, range = R.Range, speed = R.Speed, width = R.Width*2, collisionM = R.collisionM, collisionH = R.collisionH})
		elseif R.Type:find("Circle") then
			HPred:AddSpell("R", Champ,{type = R.Type, delay = R.Delay, range = R.Range, speed = R.Speed, radius = R.Width*2, collisionM = R.collisionM, collisionH = R.collisionH})
		end
	end
	
	LoadMenu()
end

function OnTick()
	local target = STS:GetTarget(2000)
	if target ~= nil then
		if UseQ ~= nil and Config.Q.CastQ then CastQ(target) end
		if UseW ~= nil and Config.W.CastW then CastW(target) end
		if UseE ~= nil and Config.E.CastE then CastE(target) end
		if UseR ~= nil and Config.R.CastR then CastR(target) end
	end
end

function LoadMenu()
	Config = scriptConfig("["..Champ.."] AimBot", "["..Champ.."] AimBot")
	
		Config:addSubMenu("TargetSelector", "TargetSelector")
			STS:AddToMenu(Config.TargetSelector)
		
		--Config:addSubMenu("General", "General")
			--Config.General:addParam("FullCombo", "FullCombo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			--Config.General:addParam("UseFullCombo", "Use FullCombo", SCRIPT_PARAM_ONOFF, true)
			--Config.General:addParam("FirstSpell", "First Spell", SCRIPT_PARAM_LIST, 1, {"Q", "W", "E", "R"})
			--Config.General:addParam("SecondSpell", "Second Spell", SCRIPT_PARAM_LIST, 2, {"Q", "W", "E", "R"})
			--Config.General:addParam("thirdSpell", "third Spell", SCRIPT_PARAM_LIST, 3, {"Q", "W", "E", "R"})
			--Config.General:addParam("FourthSpell", "Fourth Spell", SCRIPT_PARAM_LIST, 4, {"Q", "W", "E", "R"})
		if UseQ ~= nil then
			Config:addSubMenu("["..Champ.."] "..UseQ, "Q")
				Config.Q:addParam("INFO", "Spell Slot", SCRIPT_PARAM_INFO, "Q")
				Config.Q:addParam("CastQ", "CastQ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Q"))
				Config.Q:addParam("HitChance", "HitChance", SCRIPT_PARAM_SLICE, 1, 0, 3, 2)
		end
		if UseW ~= nil then
			Config:addSubMenu("["..Champ.."] "..UseW, "W")
				Config.W:addParam("INFO", "Spell Slot", SCRIPT_PARAM_INFO, "W")
				Config.W:addParam("CastW", "CastW", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("W"))
				Config.W:addParam("HitChance", "HitChance", SCRIPT_PARAM_SLICE, 1, 0, 3, 2)
		end
		if UseE ~= nil then
			Config:addSubMenu("["..Champ.."] "..UseE, "E")
				Config.E:addParam("INFO", "Spell Slot", SCRIPT_PARAM_INFO, "E")
				Config.E:addParam("CastE", "CastE", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("E"))
				Config.E:addParam("HitChance", "HitChance", SCRIPT_PARAM_SLICE, 1, 0, 3, 2)
		end
		if UseR ~= nil then
			Config:addSubMenu("["..Champ.."] "..UseR, "R")
				Config.R:addParam("INFO", "Spell Slot", SCRIPT_PARAM_INFO, "R")
				Config.R:addParam("CastR", "CastR", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("R"))
				Config.R:addParam("HitChance", "HitChance", SCRIPT_PARAM_SLICE, 1, 0, 3, 2)
		end
end

function FullCombo()
end

function CastQ(target)
	local Pos, HitChance = HPred:GetPredict("Q", target, player)
	if HitChance >= Config.Q.HitChance then
		CastSpell(_Q, Pos.x, Pos.z)
	end
end

function CastW(target)
	local Pos, HitChance = HPred:GetPredict("W", target, player)
	if HitChance >= Config.W.HitChance then
		CastSpell(_W, Pos.x, Pos.z)
	end
end

function CastE(target)
	local Pos, HitChance = HPred:GetPredict("E", target, player)
	if HitChance >= Config.E.HitChance then
		CastSpell(_E, Pos.x, Pos.z)
	end
end

function CastR(target)
	local Pos, HitChance = HPred:GetPredict("R", target, player)
	if HitChance >= Config.R.HitChance then
		CastSpell(_R, Pos.x, Pos.z)
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