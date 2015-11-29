--[[
		 /.\      '||` '||`         '||                 
		// \\      ||   ||           ||             ''  
	   //...\\     ||   ||   '''|.   ||''|, .|''|,  ||  
	  //     \\    ||   ||  .|''||   ||  || ||  ||  ||  
	.//       \\. .||. .||. `|..||. .||  || `|..|' .||. 
	
	Allahoi - Allahu Akbar by kaokaoni
	
	
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

require 'SourceLib_Fix'
local VERSION = 0.01
local function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>Allahoi:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end

function OnLoad()
	champ= Allah()
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

class('Allah')
function Allah:__init()
	--Updater
	--[[
	
	ToUpdate = {}
	ToUpdate.Host = "raw.githubusercontent.com"
	ToUpdate.VersionPath = "/kej1191/anonym/master/KOM/MidKing/MidKing.version"
	ToUpdate.ScriptPath =  "/kej1191/anonym/master/KOM/MidKing/MidKing.lua"
	ToUpdate.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
	ToUpdate.CallbackUpdate = function(NewVersion, OldVersion) print("<font color=\"#00FA9A\"><b>[Allahoi] </b></font> <font color=\"#6699ff\">Updated to "..NewVersion..". </b></font>") end
	ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#00FA9A\"><b>[Allahoi] </b></font> <font color=\"#6699ff\">You have lastest version ("..OldVersion..")</b></font>") end
	ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#00FA9A\"><b>[Allahoi] </b></font> <font color=\"#6699ff\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
	ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#00FA9A\"><b>[Allahoi] </b></font> <font color=\"#6699ff\">Error while Downloading. Please try again.</b></font>") end
	self.updater = SourceUpdater(VERSION, true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
	

	]]
	--InitializeComponent
	self.STS = SimpleTS()
	OnOrbLoad()
	
	
	self.Q = {Range = 800, Width = 100, Speed = 1500, Delay = 0.251, Collision = false}
	self.W = {Range = 400}
	self.E = {Range = 949, Width = 50, Speed = 1841, Delay = 0.267, Collision = false}
	self.R = {Range = 400}

	self.minionTable =  minionManager(MINION_ENEMY, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, self.Q.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	self.ghost = {}
	
	--Menu settings
	self.Config = scriptConfig("Allahoi", "Illaoi")
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
	self.QSpell:SetAOE(true)
	
	self.WSpell = Spell(_W, self.Config.Settings.W, SKILLSHOT_OTHER, self.W.Range)
	self.Config.Settings.W:addParam("limit", "use w tentacle in range >= ", SCRIPT_PARAM_SLICE, 1, 0, 3)
	
	self.ESpell = Spell(_E, self.Config.Settings.E, SKILLSHOT_LINEAR, self.E.Range, self.E.Width, self.E.Delay, self.E.Speed, false)
	self.ESpell:SetAOE(true)
	
	self.RSpell = Spell(_R, self.Config.Settings.R, SKILLSHOT_OTHER, self.R.Range)
	self.Config.Settings.R:addParam("limit", "use R enemy in range >= ", SCRIPT_PARAM_SLICE, 2, 0, 5)
	
	--Callback settings
	AddTickCallback(function() self:Tick() end)
	AddDrawCallback(function() self:Draw() end)
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
function Allah:Tick()
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

function Allah:Draw()
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

function Allah:OnCreateObj(object)
	if myHero.dead then return end
	if object and object.name and object.name:lower():find("bot") then
		data = {name = object.name, pos = Vector(object)}
		print(data.name)
		table.insert(self.ghost, data)
	end
end

function Allah:OnDeleteObj(object)
	if myHero.dead then return end
	if object and object.name and object.name:lower():find("bot") then
		for i = 1, #self.ghost, 1 do
			if bot[i].name == object.name then
				table.remove(self.ghost, i)
			end
		end
	end
end

function Allah:Combo(target)
	if target ~= nil then
		if self.Config.Combo.UseQ then
			self.QSpell:Cast(target.x, target.z)
		end
		if self.Config.Combo.UseW and GetDistance(target) < self.W.Range then
			self.WSpell:Cast()
			self:ResetAA()
		end
		if self.Config.Combo.UseE then
			self.ESpell:Cast(target.x, target.z)
		end
		if self.Config.Combo.UseR and GetDistance(target) < self.R.Range and CountEnemyHeroInRange(self.R.Range) <= self.Config.Skillshot.R.limit then
			self.RSpell:Cast()
		end
	end
end

function Allah:Harass(target)
	if target ~= nil then
		if self:IsManalow() then
			if self.Config.General.Debug then
				print("Allah : Harass() : Low mana")
			end
			return
		end
		if GetDistance(target) > self.E.Range then
			if self.Config.General.Debug then
				print("Allah : Harass() : Target is out of range")
			end
			return
		end
		if self.Config.Harass.UseE then
			self.ESpell:Cast(target.x, target.z)
		end
		if self:GetCustemBotTarget() ~= nil and GetDistance(Vector(target)) > 400 then
			target = Vector(self:GetCustemBotTarget())
			if self.Config.Harass.UseQ then
				CastSpell(_Q,target.x, target.z)
			end
			if self.Config.Harass.UseW then
				CastSpell(_W)
				self:ResetAA()
			end
		else
			if self.Config.Harass.UseQ then
				self.QSpell:Cast(target.x, target.z)
			end
			if self.Config.Harass.UseW then
				self.WSpell:Cast()
				self:ResetAA()
			end
		end
	else
		if self.Config.General.Debug then
			print("Allah : Harass() : Target is nil")
		end
	end
end

function Allah:LineClear()
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

function Allah:JungleClear()
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

function Allah:GetCustemBotTarget(n)
	local bots = {}
	for i = 1, objManager.iCount, 1 do
        local obj = objManager:getObject(i)
        if obj and obj.name ~= nil and obj.name:lower():find("bot") then
			table.insert(bots, obj)
		end
	end
	table.sort(bots, function(a, b) return GetDistance(Vector(a)) < GetDistance(Vector(b)) end)
	return bots[n or 1]
end
--[[
	check mana low

	@param mode | string  | combo or harass
	@return		| boolean | mana is more than setting per or not
]]
function Allah:IsManalow(mode)
	local mode = mode or "harass"
	if(mode == "combo") then
		return true
	elseif mode == "harass" then
		return ((myHero.mana / myHero.maxMana * 100) <= self.Config.Harass.ManaCheck)
	else
		print ("Allahoi : IsManalow(mode) : mode is invalid (not combo or harass)")
		return false
	end
end

function Allah:IsComboPressed()
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

function Allah:IsHarassPressed()
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

function Allah:IsClearPressed()
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

function Allah:IsLastHitPressed()
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

function Allah:ResetAA()
    if SacLoad then
        _G.AutoCarry.Orbwalker:ResetAttackTimer()
    elseif SxOLoad then
        _G.SxOrb:ResetAA()
    elseif MMALoad then
        _G.MMA_ResetAutoAttack()
    end
end

























