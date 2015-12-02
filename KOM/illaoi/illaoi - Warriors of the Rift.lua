--[[
     '||` '||`                               '||      ||`                                                           .|';      ||    '||               '||'''|,       .|';   ||    
 ''   ||   ||                  ''             ||      ||                         ''                                 ||        ||     ||                ||   ||  ''   ||     ||    
 ||   ||   ||   '''|.  .|''|,  ||     ---     ||  /\  ||   '''|.  '||''| '||''|  ||  .|''|, '||''| (''''    .|''|, '||'     ''||''   ||''|, .|''|,     ||...|'  ||  '||'  ''||''  
 ||   ||   ||  .|''||  ||  ||  ||              \\//\\//   .|''||   ||     ||     ||  ||  ||  ||     `'')    ||  ||  ||        ||     ||  || ||..||     || \\    ||   ||     ||    
.||. .||. .||. `|..||. `|..|' .||.              \/  \/    `|..||. .||.   .||.   .||. `|..|' .||.   `...'    `|..|' .||.       `|..' .||  || `|...     .||  \\. .||. .||.    `|..' 
                                                                                                                                                                                  
	
	illaoi - Warriors of the Rift by kaokaoni
	
	
	Introduction:
		use that. then you got win maybe lol
	
	Require common library:
		SourceLib rework by kaokaoni -- 
	
	Feature:
		AutoUpdater
		Cobmo Q, W, E, R
		Harass Q, W, E
		LineClear Q, W
		JungleClear Q, W
		Limit R until enemys in r range as much as you want
]]

if myHero.charName:lower() ~= "illaoi" then return end

local function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>illaoi - Warriors of the Rift:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end

local VERSION = 0.03


if FileExist(LIB_PATH .. "SourceLibk.lua") then
	require 'SourceLibk'
else
	AutoupdaterMsg("plz download SourceLibk in post")
	AutoupdaterMsg("plz download SourceLibk in post")
	AutoupdaterMsg("plz download SourceLibk in post")
	AutoupdaterMsg("plz download SourceLibk in post")
	AutoupdaterMsg("plz download SourceLibk in post")
	return
end
updater = SimpleUpdater("illaoi - Warriors of the Rift", VERSION, "raw.github.com" , "/kej1191/anonym/master/KOM/illaoi/illaoi%20-%20Warriors%20of%20the%20Rift.lua" , LIB_PATH .. "SourceLib_Fix.lua" , "/kej1191/anonym/master/KOM/illaoi/version.version" ):CheckUpdate()


function OnLoad()
	champ= illaoi()
end

function OnCreateObj(obj)
	if champ then
		champ:OnCreateObj(obj)
	end
end

function OnDeleteObj(obj)
	if champ then
		champ:OnDeleteObj(obj)
	end
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

class('illaoi')
function illaoi:__init()

	--InitializeComponent
	self.STS = SimpleTS(STS_NEARMOUSE)
	self.CBM = CallBackManager()
	OnOrbLoad()
	
	
	self.Q = {Range = 800, Width = 105, Speed = 1500, Delay = 0.733, Collision = false}
	self.W = {Range = 400}
	self.E = {Range = 949, Width = 52.5, Speed = 1841, Delay = 0.267, Collision = false}
	self.R = {Range = 400}

	self.minionTable =  minionManager(MINION_ENEMY, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	self.ghost = {}
	
	--Menu settings
	self.Config = scriptConfig("illaoi", "Illaoi")
		if SxOLoad then
			self.Config:addSubMenu("Orbwalking", "Orbwalking")
				SxO:LoadToMenu(self.Config.Orbwalking, Orbwalking)
		end
		self.Config:addSubMenu(myHero.charName.." - General Settings", "General")
			self.Config.General:addParam("On", "Script On", SCRIPT_PARAM_ONOFF, true)
			self.Config.General:addParam("OnOrbWalkerKey", "Use orbwalker key", SCRIPT_PARAM_ONOFF, true)
			self.Config.General:addParam("Bla", " - HotKey Settings -", SCRIPT_PARAM_INFO, "")
			self.Config.General:addParam("Combo",		"Combo HotKey : ", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			self.Config.General:addParam("Harass",	 	"Harass HotKey : ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
			self.Config.General:addParam("LineClear", 	"LineClear HotKey : ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
			self.Config.General:addParam("JungleClear", "JungleClear HotKey: ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
			self.Config.General:addParam("dev", " - Dev Settings -", SCRIPT_PARAM_INFO, "")
			self.Config.General:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
		
		self.Config:addSubMenu(myHero.charName .. " - SimpleTS", "STS")
			self.STS:AddToMenu(self.Config.STS)
			
		self.Config:addSubMenu(myHero.charName.." - Combo settings", "Combo")
			self.Config.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		
		self.Config:addSubMenu(myHero.charName.." - Harass settings", "Harass")
			self.Config.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
		
		self.Config:addSubMenu(myHero.charName.." - LineClear settings", "linec")
			self.Config.linec:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.linec:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		
		self.Config:addSubMenu(myHero.charName.." - JungleClear Settings", "Junglec")
			self.Config.Junglec:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Junglec:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		
		self.Config:addSubMenu(myHero.charName.." - Skillshot settings", "Settings")
			self.Config.Settings:addSubMenu("Q Settings", "Q")
			self.Config.Settings:addSubMenu("W Settings", "W")
			self.Config.Settings:addSubMenu("E Settings", "E")
			self.Config.Settings:addSubMenu("R Settings", "R")
			
		self.Config:addSubMenu(myHero.charName.." - Draw settings", "Draw")
			self.Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawQColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawWColor", "Draw W Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawEColor", "Draw E Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawRColor", "Draw R Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
	--Skillshot settings
	self.QSpell = Spell(_Q, self.Config.Settings.Q, SKILLSHOT_LINEAR, self.Q.Range, self.Q.Width, self.Q.Delay, self.Q.Speed, true)
	--self.QSpell:SetAOE(true)
	
	self.WSpell = Spell(_W, self.Config.Settings.W, SKILLSHOT_OTHER, self.W.Range)
	
	self.ESpell = Spell(_E, self.Config.Settings.E, SKILLSHOT_LINEAR, self.E.Range, self.E.Width, self.E.Delay, self.E.Speed, true)
	
	self.RSpell = Spell(_R, self.Config.Settings.R, SKILLSHOT_OTHER, self.R.Range)
	self.Config.Settings.R:addParam("limit", "use R enemy in range >= ", SCRIPT_PARAM_SLICE, 2, 0, 5)
	
	--Callback settings
	self.CBM:Tick(function() self:Tick() end)
	self.CBM:Draw(function() self:Draw() end)
	--AddTickCallback(function() self:Tick() end)
	--AddDrawCallback(function() self:Draw() end)
end

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
local function OrbTarget()
	local T
	if MMALoad then T = _G.MMA_Target end
	if RebornLoad then T = _G.AutoCarry.Crosshair.Attack_Crosshair.target end
	if RevampedLoaded then T = _G.AutoCarry.Orbwalker.target end
	if SxOLoad then T = SxO:GetTarget() end
	if SOWLoaded then T = SOW:GetTarget() end
	if T and T.type == myHero.type and ValidTarget(T, range) then
		return T
	end
end
function illaoi:Tick()
	if myHero.dead then return end
	if self.Config.General.On and orbload ~= nil then
		self.Target = self.STS:GetTarget(self.E.Range)
		--
		if not self.Config.General.OnOrbWalkerKey then
			if self.Config.General.Combo then
				self:Combo(self.Target)
			end
			if self.Config.General.Harass then
				self:Harass(self.Target)
			end
			if self.Config.General.LineClear then
				self:LineClear()
			end
			if self.Config.General.JungleClear then
				self:JungleClear()
			end
		else
			if self:IsComboPressed() then
				self:Combo(self.Target)
			end
			if self:IsHarassPressed() then
				self:Harass(self.Target)
			end
			if self:IsClearPressed() then
				self:LineClear()
			end
			if self:IsClearPressed() then
				self:JungleClear()
			end
		end
	end
end

function illaoi:Draw()
	if myHero.dead then return end

	if self.QSpell:IsReady() and self.Config.Draw.DrawQ then
		DrawCircle(myHero.x, myHero.y, myHero.z, self.Q.Range, TARGB(self.Config.Draw.DrawQColor))
	end

	if self.WSpell:IsReady() and self.Config.Draw.DrawW then
		DrawCircle(myHero.x, myHero.y, myHero.z, self.W.Range, TARGB(self.Config.Draw.DrawWColor))
	end

	if self.ESpell:IsReady() and self.Config.Draw.DrawE then
		DrawCircle(myHero.x, myHero.y, myHero.z, self.E.Range, TARGB(self.Config.Draw.DrawEColor))
	end

	if self.RSpell:IsReady() and self.Config.Draw.DrawR then
		DrawCircle(myHero.x, myHero.y, myHero.z, self.R.Range, TARGB(self.Config.Draw.DrawRColor))
	end
	
	local target = Vector(self:GetCustemBotTarget(1))
	if (target ~= nil) then
		DrawCircle(target.x, target.y, target.z, 100, 0xffff0000)
	end
end

function illaoi:OnCreateObj(object)
	if myHero.dead then return end
	if object and object.name and object.name:lower():find("bot") then
		data = {name = object.name, pos = Vector(object)}
		table.insert(self.ghost, data)
	end
end

function illaoi:OnDeleteObj(object)
	if myHero.dead then return end
	if object and object.name and object.name:lower():find("bot") then
		for i = 1, #self.ghost, 1 do
			if self.ghost[i].name == object.name then
				table.remove(self.ghost, i)
			end
		end
	end
end

function illaoi:Combo(target)
	if target ~= nil then
		if self.Config.Combo.UseQ then
			self.QSpell:Cast(target)
		end
		if self.Config.Combo.UseW then
			self.WSpell:Cast()
			self:ResetAA()
		end
		if self.Config.Combo.UseE then
			self.ESpell:Cast(target)
		end
		if self.Config.Combo.UseR and CountEnemyHeroInRange(self.R.Range) <= self.Config.Settings.R.limit then
			self.RSpell:Cast()
		end
	end
end

function illaoi:Harass(target)
	if target ~= nil then
		if self:IsManalow() then
			if self.Config.General.Debug then
				print("illaoi : Harass() : Low mana")
			end
			return
		end
		if GetDistance(target) > self.E.Range then
			if self.Config.General.Debug then
				print("illaoi : Harass() : Target is out of range")
			end
			return
		end
		if self.Config.Harass.UseE and GetDistance(target) < self.E.Range then
			self.ESpell:Cast(target)
		end
		if self:GetCustemBotTarget() ~= nil and GetDistance(Vector(target)) > 400 then
			targetPos = self:GetCustemBotTarget()
			if self.Config.Harass.UseQ and GetDistance(targetPos) < self.Q.Range then
				self.QSpell:Cast(targetPos.x, targetPos.z)
			end
			if self.Config.Harass.UseW and GetDistance(targetPos) < self.W.Range then
				CastSpell(_W)
				self:ResetAA()
			end
		else
			if self.Config.Harass.UseQ and GetDistance(target) < self.Q.Range then
				self.QSpell:Cast(target)
			end
			if self.Config.Harass.UseW and GetDistance(target) < self.W.Range then
				self.WSpell:Cast()
				self:ResetAA()
			end
		end
	else
		if self.Config.General.Debug then
			print("illaoi : Harass() : Target is nil")
		end
	end
end

function illaoi:LineClear()
	self.minionTable:update()
	if self.Config.linec.UseQ and self.QSpell:IsReady() and #self.minionTable.objects ~= 0 then
		local BestPos, BestHit, BestObj = GetBestLineFarmPosition(self.Q.Range, self.Q.Width, self.minionTable.objects)
		if BestPos ~= nil and BestHit ~= nil and BestObj ~= nil then
			CastSpell(_Q, BestPos.x, BestPos.z)
		end
	end
	if self.Config.linec.UseW and #self.minionTable.objects ~= 0 and GetDistance(self.minionTable.objects[1]) <= self.W.Range then
		CastSpell(_W)
		self:ResetAA()
	end
end

function illaoi:JungleClear()
	self.jungleTable:update()
	if self.Config.Junglec.UseQ and self.QSpell:IsReady() then
		local BestPos, BestHit, BestObj = GetBestLineFarmPosition(self.Q.Range, self.Q.Width, self.jungleTable.objects)
		if BestPos ~= nil and BestHit ~= nil and BestObj ~= nil then
			CastSpell(_Q, BestPos.x, BestPos.z)
		end
	end
	if self.Config.Junglec.UseW and #self.jungleTable.objects ~= 0 and GetDistance(self.jungleTable.objects[1]) <= self.W.Range then
		CastSpell(_W)
		self:ResetAA()
	end
end 

function illaoi:GetCustemBotTarget(n)
	table.sort(self.ghost, function(a, b) return GetDistance(Vector(a)) < GetDistance(Vector(b)) end)
	return self.ghost[n or 1]
end
--[[
	check mana low

	@param mode | string  | combo or harass
	@return		| boolean | mana is more than setting per or not
]]
function illaoi:IsManalow(mode)
	local mode = mode or "harass"
	if(mode == "combo") then
		return true
	elseif mode == "harass" then
		return ((myHero.mana / myHero.maxMana * 100) <= self.Config.Harass.ManaCheck)
	else
		print ("illaoioi : IsManalow(mode) : mode is invalid (not combo or harass)")
		return false
	end
end

function illaoi:IsComboPressed()
	if SacLoad then
		if _G.AutoCarry.Keys.AutoCarry then
			return true
		end
	elseif SxOLoad then
		if _G.SxOrb.isFight then
			return true
		end
	elseif MMALoad then
		if _G.MMA_IsOrbwalking() then
			return true
		end
	end
    return false
end

function illaoi:IsHarassPressed()
	if SacLoad then
		if _G.AutoCarry.Keys.MixedMode then
			return true
		end
	elseif SxOLoad then
		if _G.SxOrb.isHarass then
			return true
		end
	elseif MMALoad then
		if _G.MMA_IsDualCarrying() then
			return true
		end
	end
    return false
end

function illaoi:IsClearPressed()
	if SacLoad then
		if _G.AutoCarry.Keys.LaneClear then
			return true
		end
	elseif SxOLoad then
		if _G.SxOrb.isLaneClear then
			return true
		end
	elseif MMALoad then
		if _G.MMA_IsLaneClearing() then
			return true
		end
	end
    return false
end

function illaoi:IsLastHitPressed()
	if SacLoad then
		if _G.AutoCarry.Keys.LastHit then
			return true
		end
	elseif SxOLoad then
		if _G.SxOrb.isLastHit then
			return true
		end
	elseif MMALoad then
		if _G.MMA_IsLastHitting() then
			return true
		end
	end
    return false
end

function illaoi:ResetAA()
    if SacLoad then
        _G.AutoCarry.Orbwalker:ResetAttackTimer()
    elseif SxOLoad then
        _G.SxOrb:ResetAA()
    elseif MMALoad then
        _G.MMA_ResetAutoAttack()
    end
end

























