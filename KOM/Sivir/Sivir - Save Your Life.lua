if myHero.charName ~= "Sivir" then return end
local function AutoupdaterMsg(msg) print("<font color=\"##7D26CD\"><b>Sivir - Save Your Life:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
--require 'HPrediction'
--require 'SPrediction'
--require 'VPrediction'
VERSION = 1.01
local SupPred = {"H Prediction", "V Prediction", "S Prediction"}
local SCRIPT_LIBS = {
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
			AutoupdaterMsg("Missing Library! Downloading "..LIBRARY..". If the library doesn't download, please download it manually.")
			DownloadFile(LIBRARY_URL,LIB_PATH..LIBRARY..".lua",function() AutoupdaterMsg("Successfully downloaded "..LIBRARY) end)
		end
	end
	if DOWNLOADING_LIBS then return true end
end
if Initiate() then return end
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

function OnLoad()
	ToUpdate = {}
	ToUpdate.Host = "raw.githubusercontent.com"
	ToUpdate.VersionPath = "/kej1191/anonym/master/KOM/Sivir/Sivir%20-%20Save%20Your%20Life.version"
	ToUpdate.ScriptPath =  "/kej1191/anonym/master/KOM/Sivir/Sivir%20-%20Save%20Your%20Life.lua"
	ToUpdate.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
	ToUpdate.CallbackUpdate = function(NewVersion, OldVersion) print("<font color=\"##7D26CD\"><b>Sivir - Save Your Life </b></font> <font color=\"#FFFFFF\">Updated to "..NewVersion..". </b></font>") end
	ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"##7D26CD\"><b>Sivir - Save Your Life </b></font> <font color=\"#FFFFFF\">You have lastest version ("..OldVersion..")</b></font>") end
	ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"##7D26CD\"><b>Sivir - Save Your Life </b></font> <font color=\"#FFFFFF\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
	ToUpdate.CallbackError = function(NewVersion) print("<font color=\"##7D26CD\"><b>Sivir - Save Your Life </b></font> <font color=\"#FFFFFF\">Error while Downloading. Please try again.</b></font>") end
	ScriptUpdate(VERSION, true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
	champ = Sivir()
	AS = AutoShield()
	ez = Awareness()
end


class "Sivir"
function Sivir:__init()
	OnOrbLoad()
	self.Walking = false
	self.TargetQPos = nil
	self.LastDistance = nil
	
	self.Q = {Speed = 1350, Range = 1075, Delay = 0.250, Width = 85, EndPos = nil, Object = nil, IsReady = function() return myHero:CanUseSpell(_Q) == READY end}
	self.Q2 = {Speed = 1350, Range = 1100, Delay = 1.04, Width = 90}
	
	self.HP_Q = HPSkillshot({type = "DelayLine", delay = self.Q.Delay, speed = self.Q.Speed, range = self.Q.Range, width = self.Q.Width})
	self.HP_Q2 = HPSkillshot({type = "DelayLine", delay = self.Q2.Delay, speed = self.Q2.Speed, range = self.Q2.Range, width = self.Q2.Width})

	self.W = {IsReady = function() return myHero:CanUseSpell(_W) == READY end}
	self.ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100, DAMAGE_PHYSICAL)
	self.ts.name = "Ranged Main"
	self.EnemyMinions = minionManager(MINION_ENEMY, 1100, myHero, MINION_SORT_MAXHEALTH_DEC)
		
	self.Config = scriptConfig("Sivir", "Sivir")
		if SxOLoad then
			self.Config:addSubMenu(myHero.charName.." - Orbwalking", "Orbwalking")
				SxO:LoadToMenu(self.Config.Orbwalking, Orbwalking)
		end
		self.Config:addSubMenu(myHero.charName.." - AutoShield settings", "AutoShield")
			AutoShield(self.Config.AutoShield)
			
		self.Config:addSubMenu(myHero.charName.." - Combo settings", "Combo")
			self.Config.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("useW", "Use W for aa cansle", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("MaxQRange", "Max Q Range", SCRIPT_PARAM_SLICE, 1075, 100, 1075, 0)
			self.Config.Combo:addParam("OrbWalk", "orbwalk to Q best pos", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("considerbackq", "Consider q back", SCRIPT_PARAM_ONOFF, false)
			self.Config.Combo:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		
		self.Config:addSubMenu(myHero.charName.." - Harass settings", "Harass")
			self.Config.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("MaxQRange", "Max Q Range", SCRIPT_PARAM_SLICE, 1075, 100, 1075, 0)
			self.Config.Harass:addParam("OrbWalk", "orbwalk to Q best pos", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
		
		self.Config:addSubMenu(myHero.charName.." - Farm settings", "Farm")
			self.Config.Farm:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Farm:addParam("useW", "Use W for aa cansle", SCRIPT_PARAM_ONOFF, true)
			self.Config.Farm:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
		self.Config:addSubMenu(myHero.charName.." - Extra settings", "Extras")
			self.Config.Extras:addParam("Debug", "Dev Debug", SCRIPT_PARAM_ONOFF, false)
			self.Config.Extras:addParam("OrbwalkDistance", "orbWalk to Q max cursor distance", SCRIPT_PARAM_SLICE, 600, 0, 1000, 0)
			self.Config.Extras:addParam("OrbwalkAngle", "Orbwalk to Q Max Cursor Angle", SCRIPT_PARAM_SLICE, 60, 1, 180, 0)
			self.Config.Extras:addParam("MaxAngle", "Max Angle for Q Check",  SCRIPT_PARAM_SLICE, 15, 1, 90, 0)
			self.Config.Extras:addParam("AngleIncrement", "Increment Angle Degree",  SCRIPT_PARAM_SLICE, 2, 1, 90, 0)
			self.Config.Extras:addParam("DoubleQ", "Check Double Q", SCRIPT_PARAM_ONOFF, true)
		self.Config:addSubMenu(myHero.charName.." - Draw settings", "Draw")
			self.Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawQCalculations", "Draw Q Calculations", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawMouse", "Draw Mouse Orbwalk Distance Circle", SCRIPT_PARAM_ONOFF, false)
		self.Config:addSubMenu(myHero.charName.." - Pred Setting", "Pred")
			self.Config.Pred:addParam("QPred", "Q Prediction", SCRIPT_PARAM_LIST,1, SupPred)
			
	
	AddTickCallback(function() self:Tick() end)
	AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
	--AddRemoveBuffCallback(function(unit, buff) self:OnRemoveBuff(unit, buff) end)	
	AddDrawCallback(function() self:Draw() end)
end
function Sivir:Tick()
	self.EnemyMinions:update()
	self.ts:update()
	local target = GetCustomTarget() or self.ts.target
	if self.Config.Combo.Combo and target then
		self:Combo(target)
	elseif self.Config.Harass.Harass and target then
		self:Harass(target)
	elseif self.Config.Farm.Farm then
		self:Farm(target)
	end
	if self.Q.Object == nil and not self.Q.IsReady() then
		self.Q.EndPos = nil
		self.LastDistance = nil
		self:OrbwalkToPosition(nil)
	end
end
function Sivir:Draw()
	if self.Config.Extras.Debug and self.Q.Object ~= nil then
		DrawText3D("Current IsReturning status is " .. tostring(IsReturning()), myHero.x+200, myHero.y, myHero.z+200, 25,  ARGB(255,255,0,0), true)
	end

	if self.Config.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, self.Q.Range, 1,  ARGB(255, 0, 255, 255))
		if self.Q.Object ~= nil then
			DrawCircle3D(self.Q.Object.x, self.Q.Object.y, self.Q.Object.z, self.Q.Width, 1, ARGB(255, 0, 255, 255))
		end
		if self.Q.EndPos ~= nil then
			DrawCircle3D(self.Q.EndPos.x, self.Q.EndPos.y, self.Q.EndPos.z, self.Q.Width, 1, ARGB(255, 255, 0, 0))
		end
	end

	if self.Config.Draw.DrawQCalculations then
		if self.TargetQPos ~= nil and self.Q.EndPos ~= nil and mousePos ~= nil then
			if Walking then
				DrawCircle3D(self.TargetQPos.x, self.TargetQPos.y, self.TargetQPos.z, 100, 1,  ARGB(255, 255, 0, 0))
				DrawLine3D(myHero.x, myHero.y, myHero.z, self.TargetQPos.x, self.TargetQPos.y, self.TargetQPos.z,  1, ARGB(255, 255, 0, 0))
				DrawLine3D(self.Q.EndPos.x, self.Q.EndPos.y, self.Q.EndPos.z, self.TargetQPos.x, self.TargetQPos.y, self.TargetQPos.z, 1, ARGB(255, 255, 0, 0))
			else
				DrawCircle3D(self.TargetQPos.x, self.TargetQPos.y, self.TargetQPos.z, 100, 1,  ARGB(255, 0, 255, 0))
				DrawLine3D(myHero.x, myHero.y, myHero.z, self.TargetQPos.x, self.TargetQPos.y, self.TargetQPos.z,  1, ARGB(255, 0, 255, 0))
				DrawLine3D(self.Q.EndPos.x, self.Q.EndPos.y, self.Q.EndPos.z, self.TargetQPos.x, self.TargetQPos.y, self.TargetQPos.z, 1, ARGB(255, 0, 255, 0))
			end
		end
	end

	if self.Config.Draw.DrawMouse then
		DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, self.Config.Extras.OrbwalkDistance, 1, ARGB(255, 255, 0, 0))
	end
end
function Sivir:Combo(Target)
	if self.Config.Extras.Debug then
		print('Combo called')
	end	

	if self.Q.IsReady() and self.Config.Combo.useQ and GetDistance(Target) < self.Config.Combo.MaxQRange then
		if self.Config.Extras.Debug then
			print('Cast Q called')
		end	
		self:CastQ(Target)
	end

	if self.Q.Object ~= nil and self.Config.Combo.Orbwalk then
		self:OrbwalkQ(Target)
	end

	if GetDistance(Target) < 600 and self.Config.Combo.useW then
		self:CastW()
	end

	self:KS(Target)

end
function Sivir:Harass(Target)
	if self.Q.IsReady() and self.Config.Harass.useQ and GetDistance(Target) < self.Config.Harass.MaxQRange then
		self:CastQ(Target)
	end

	if self.Q.Object ~= nil and self.Config.HarassSub.Orbwalk then
		self:OrbwalkQ(Target)
	end
end
function Sivir:KS(Target)
	if self.Q.IsReady() and getDmg("Q", Target, myHero) > Target.health then
		self:CastQ(Target)
	end
end
function Sivir:Farm()
	if self.Config.Farm.useQ then
		self:FarmQ()
	end
	if self.W.IsReady() and #self.EnemyMinions.objects > 3 and self.Config.Farm.useW then
		CastSpell(_W)
	end
end
function Sivir:FarmQ()
	for _, minion in pairs(self.EnemyMinions.objects) do
		if self.Q.IsReady() and #self.EnemyMinions.objects > 0 then
			local bestpos, besthit = GetBestLineFarmPosition(self.Q.Range, self.Q.Width, self.EnemyMinions.objects, myHero)
			if bestpos then
				CastSpell(_Q, bestpos.x, bestpos.z)
			end
		end
	end
end
function Sivir:CastQ(Target)
	if self.Config.Extras.Debug then
		print(CountEnemyNearPerson(Target,800))
		print(ValidTarget(Target, 1300))
	end	
	if self.Config.Combo.considerbackq then
		if ValidTarget(Target, 1300) and not Target.dead and CountEnemyNearPerson(Target,800) > 1 then
			if self.Config.Pred.QPred == 1 then
				self.QPos, self.QHitChance = HP:GetPredict(self.HP_Q, Target, myHero)
				if self.QPos and self.QHitChance >= 0.8 then
					CastSpell(_Q, self.QPos.x, self.QPos.z)
				end
			elseif self.Config.Pred.QPred == 2 then
				self.QPos, self.QHitChance = VP:GetLineAOECastPosition(Target, self.Q.Delay, self.Q.Width, self.Q.Range, self.Q.Speed, myHero)
				if self.QPos and self.QHitChance >= 0.8 then
					CastSpell(_Q, self.QPos.x, self.QPos.z)
				end
			elseif self.Config.Pred.QPred == 3 then
				self.QPos, self.QHitChance, self.PredPos = SP:Predict(Target, self.Q.Range, self.Q.Speed, self.Q.Delay, self.Q.Width, false, myHero)
				if self.QPos and self.QHitChance >= 0.8 then
					CastSpell(_Q, self.QPos.x, self.QPos.z)
				end
			end
			if self.Config.Extras.Debug then
				print('Returning CastQ2')
			end	
		elseif  ValidTarget(Target, 1300) and not Target.dead then
			if self.Config.Extras.Debug then
				print('Returning CastQ1')
			end		
			
			if self.Config.Pred.QPred == 1 then
				self.QPos, self.QHitChance = HP:GetPredict(self.HP_Q, Target, myHero)
				_, self.QHitChance2 = HP:GetPredict(self.HP_Q2, Target, myHero)
				if self.QHitChance >= 0.8 and (self.QHitChance2 >= 0.4 and self.Config.Extras.DoubleQ) and GetDistance(self.QPos) < self.Q.Range + 10 then
					CastSpell(_Q, self.QPos.x, self.QPos.z)
				end
			elseif self.Config.Pred.QPred == 2 then
				self.QPos, self.QHitChance = VP:GetLineCastPosition(Target, self.Q.Delay, self.Q.Width, self.Q.Range, self.Q.Speed, myHero, false)
				_, QHitChance2, _ = VP:GetLineCastPosition(Target, self.Q2.Delay, self.Q2.Width, self.Q2.Range, self.Q2.Speed, myHero, false)
				if self.QHitChance >= 0.8 and (self.QHitChance2 >= 0.4 and self.Config.Extras.DoubleQ) and GetDistance(self.QPos) < self.Q.Range + 10 then
					CastSpell(_Q, self.QPos.x, self.QPos.z)
				end
			elseif self.Config.Pred.QPred == 3 then
				self.QPos, self.QHitChance, self.PredPos = SP:Predict(Target, self.Q.Range, self.Q.Speed, self.Q.Delay, self.Q.Width, false, myHero)
				_, self.QHitChance2, _ = SP:Predict(Target, self.Q2.Range, self.Q2.Speed, self.Q2.Delay, self.Q2.Width, false, myHero)
				if self.QHitChance >= 0.8 and (self.QHitChance2 >= 0.4 and self.Config.Extras.DoubleQ) and GetDistance(self.QPos) < self.Q.Range + 10 then
					CastSpell(_Q, self.QPos.x, self.QPos.z)
				end
			end
		end
	else
		if self.Config.Pred.QPred == 1 then
			self.QPos, self.QHitChance = HP:GetPredict(self.HP_Q, Target, myHero)
			if self.QPos and self.QHitChance >= 0.8 then
				CastSpell(_Q, self.QPos.x, self.QPos.z)
			end
		elseif self.Config.Pred.QPred == 2 then
			self.QPos, self.QHitChance = VP:GetLineAOECastPosition(Target, self.Q.Delay, self.Q.Width, self.Q.Range, self.Q.Speed, myHero)
			if self.QPos and self.QHitChance >= 0.8 then
				CastSpell(_Q, self.QPos.x, self.QPos.z)
			end
		elseif self.Config.Pred.QPred == 3 then
			self.QPos, self.QHitChance, self.PredPos = SP:Predict(Target, self.Q.Range, self.Q.Speed, self.Q.Delay, self.Q.Width, false, myHero)
			if self.QPos and self.QHitChance >= 0.8 then
				CastSpell(_Q, self.QPos.x, self.QPos.z)
			end
		end
	end
end
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
function Sivir:OrbwalkQ(Target)
	if self.Config.Extras.Debug then
		print('Q Orbwalking calling')
	end		
	if GetDistance(Target) < 1400 then
		if self.Config.Extras.Debug then
			print('Q Orbwalking called')
		end		
		MouseVector = Vector(Vector(mousePos) - Vector(myHero)):normalized()
		local HitChance, Position = nil, nil 
		local TimeLeft = nil
		local Intersect = nil
		if IsReturning() then
			local Delay = GetDistance(self.Q.Object, Target)/self.Q.Speed
			_, HitChance, Position = VP:GetLineCastPosition(Target, self.Q.Delay, self.Q.Width, self.Q.Range, self.Q.Speed, myHero, false)
			TimeLeft = GetDistance(self.Q.Object, Position)/self.Q.Speed
			temp = VectorIntersection(Vector(self.Q.Object), Vector(Position), Vector(myHero), Vector(mousePos))
			if GetDistance(self.Q.Object) > GetDistance(Position) then
				Intersect = temp
			end
		else
			local Delay = GetDistance(self.Q.Object, self.Q.EndPos)/self.Q.Speed + GetDistance(self.Q.EndPos, Target)/self.Q.Speed
			_, HitChance, Position = VP:GetLineCastPosition(Target, Delay, self.Q.Width, self.Q.Range, self.Q.Speed, myHero, false)
			TimeLeft = GetDistance(self.Q.Object, self.Q.EndPos)/self.Q.Speed + GetDistance(self.Q.EndPos, Position)/self.Q.Speed
			Intersect= VectorIntersection(Vector(self.Q.EndPos), Vector(Position), Vector(myHero), Vector(mousePos))
		end
		-- if Config.Extras.Debug then
		-- 	print('self.Q.EndPos')
		-- 	print(Vector(self.Q.EndPos))
		-- 	print('Pos')
		-- 	print(Vector(Position))
		-- 	print('myHero')
		-- 	print(Vector(myHero))
		-- 	print('mousePos')
		-- 	print(Vector(mousePos))
		-- end	
		if Intersect ~= nil then
			local Intersect3D = {x=Intersect.x, y=myHero.y, z=Intersect.y}
			if self.Config.Extras.Debug then
				print(Intersect3D)
			end	
			--Calculate distance and angle between intersect point and my hero
			local AngleVec1 = Vector(Vector(Intersect3D) - Vector(myHero)):normalized()
			local RealAngle = AngleVec1:angle(MouseVector)*57.2957795
			self.TargetQPos = Intersect3D
			local DistanceToIntersect = GetDistance(Intersect3D)/myHero.ms < TimeLeft
			if GetDistance(Intersect3D, mousePos) < self.Config.Extras.OrbwalkDistance and GetDistance(Intersect3D) < 750 and RealAngle < self.Config.Extras.OrbwalkAngle and GetDistance(Intersect3D)/myHero.ms < TimeLeft-0.05 then
				self:OrbwalkToPosition(Intersect3D)
				self.Walking = true
			else
				self:OrbwalkToPosition(nil)
				self.Walking = false
			end
		end
	else
		self.Walking = false
		self.TargetQPos = nil
		MouseVector = nil
	end
end
function Sivir:IsReturning()
	if self.LastDistance == nil and self.Q.Object ~= nil then
		self.LastDistance = GetDistance(self.Q.Object, self.Q.EndPos)
		return false
	elseif self.Q.Object ~= nil then
		if GetDistance(self.Q.Object, self.Q.EndPos) >= self.LastDistance then
			self.LastDistance = GetDistance(self.Q.Object, self.Q.EndPos)
			return true
		else
			self.LastDistance = GetDistance(self.Q.Object, self.Q.EndPos)
			return false
		end
	else 
		return false
	end
end
function Sivir:OrbwalkToPosition(position)
	if position ~= nil then
		if _G.MMA_Loaded then
			_G.moveToCursor(position.x, position.z)
		elseif _G.AutoCarry and _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(position)
		end
	else
		if _G.MMA_Loaded then
			return
		elseif _G.AutoCarry and _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(nil)
		end
	end
end
function Sivir:CastW()
	if self:WReset() and self.W.IsReady() then
		CastSpell(_W)
	end
end
function Sivir:WReset()
	if self.Config.Combo.useWReset then
		if _G.MMA_Target ~= nil and _G.MMA_AbleToMove and not _G.MMA_AttackAvailable then
			return true
		elseif _G.AutoCarry and (_G.AutoCarry.shotFired or _G.AutoCarry.Orbwalker:IsAfterAttack()) then 
			if self.Config.Extras.Debug then
				print('SAC shot fired')
			end
			return true
		else
			return false
		end
	else
		return true
	end
end
function Sivir:OnProcessSpell(unit, spell)
	if unit.isMe and spell.name == 'SivirQ' then
		QTempEndPos = {x=spell.endPos.x, y=myHero.y, z=spell.endPos.z}
		self.Q.EndPos = Vector(myHero) + Vector(Vector(QTempEndPos) - Vector(myHero)):normalized()*self.Q.Range
		--print(QEndPos)
	end
end
function Sivir:OnCreateObj(obj)
	if obj.name == "Sivir_Base_Q_mis.troy" and  obj.team ~= TEAM_ENEMY then
		self.Q.Object = obj
	end
end
function Sivir:OnDeleteObj(obj)
	if obj.name == "Sivir_Base_Q_mis.troy" and  obj.team ~= TEAM_ENEMY then
		self.Q.Object = obj
	end
end
function OnCreateObj(obj)
	if champ and myHero.charName == "Sivir" then
		champ:OnCreateObj(obj)
	end
end
function OnDeleteObj(obj)
	if champ and myHero.charName == "Sivir" then
		champ:OnDeleteObj(obj)
	end
end

	
class ('AutoShield')
function AutoShield:__init(m)
	self.buffer = .07+GetLatency()/2000
	self.IsRecall = false
	self.LastCheck = os.clock()
	self.object = {}
	self.RecallTime = os.clock()
	self.Spears = nil
  
  self.EnemyHeroes = GetEnemyHeroes()
  self.enemyMinion = minionManager(MINION_ALLY, 2000, myHero, MINION_SORT_MAXHEALTH_DEC)
  self.jungleMob = minionManager(MINION_JUNGLE, 2000, myHero, MINION_SORT_MAXHEALTH_DEC)
  self.otherMob = minionManager(MINION_OTHER, 2000, myHero, MINION_SORT_MAXHEALTH_DEC)
  --[[
  DelayLine
  
  delay
  speed
  width
  
  PromptLine
  
  delay
  width
  
  DelayCircle
  
  delay
  speed
  radius
  
  PromptCircle
  
  delay
  radius
  ]]
	
  self.DangerousSpells =
  {
    {owner = "Brand", name = "BrandWildfire"}, --R
    {owner = "Chogath", name = "Feast", prompt = true}, --R
    {owner = "Darius", name = "DariusExecute", prompt = true}, --R
    {owner = "FiddleSticks", name = "Terrify", prompt = true}, --Q
    {owner = "FiddleSticks", name = "FiddlesticksDarkWind", prompt = true}, --E
    {owner = "Garen", name = "GarenR", prompt = true}, --R
    {owner = "Leesin", name = "BlindMonkRKick", prompt = true}, --R
    {owner = "Leona", name = "LeonaShieldOfDaybreakAttack", prompt = true}, --Q
    {owner = "Lissandra", name = "LissandraR", prompt = true}, --R
    {owner = "Malzahar", name = "AlZaharNetherGrasp", prompt = true, off = true}, --R
    {owner = "Morgana", name = "SoulShackles", prompt = true}, --R
    {owner = "Nasus", name = "NasusQAttack", prompt = true}, --Q
    {owner = "Nasus", name = "NasusW", prompt = true}, --W
    {owner = "Nunu", name = "IceBlast"}, --E
    {owner = "Rammus", name = "PuncturingTaunt", prompt = true}, --E
    {owner = "Ryze", name = "RyzeW", prompt = true}, --W
    {owner = "Skarner", name = "SkarnerImpale", prompt = true}, --R
    {owner = "Syndra", name = "SyndraR"}, --R
    {owner = "Taric", name = "Dazzle"}, --E
    {owner = "Teemo", name = "BlindingDart"}, --Q
    {owner = "Tristana", name = "TristanaR"}, --R
    {owner = "TwistedFate", name = "goldcardpreattack"}, --W
    {owner = "Urgot", name = "UrgotSwap2", prompt = true}, --R
    {owner = "Veigar", name = "VeigarPrimordialBurst"}, --R
    {owner = "Warwick", name = "InfiniteDuress", prompt = true}, --R
    
    {owner = "Blitzcrank", name = "RocketGrab", type = "DelayLine", delay = 0.25, speed = 1800, width = 140}, --Q
    {owner = "Blitzcrank", name = "RocketGrabMissile", type = "DelayLine", delay = 0.25, speed = 1800, width = 140}, --Q
	
    {owner = "Lux", name = "LuxLightBinding", type = "DelayLine", delay = 0.25, speed = 1200, width = 160}, --Q
    {owner = "Lux", name = "LuxMaliceCannonMis", type = "PromptLine", delay = 1.012, width = 380}, --R
    {owner = "Nasus", name = "NasusE"}, --E
	--skillshot
	--{owner = "Nidalee", name = "JavelinToss", type = "DelayLine", delay = 0.125, speed = 1300, range =1500, width = 60, col = true,},
	--{owner = "Amumu", name = "BandageToss", type = "DelayLine", delay = 0.25, speed = 2000, range = 1100, width = 80, col = true},
	--{owner = "LeeSin", name = "BlindMonkQOne", type = "DelayLine", delay = 0.25, speed = 1800, range = 1100, width = 70, col = true},
	--{owner = "Morgana", name = "DarkBindingMissile", type = "DelayLine", delay = 0.25, speed = 1200, range = 1300, with = 80, col = true},
	--{owner = "Sejuani", name = "SejuaniGlacialPrisonCast", type = "DelayLine", delay = 0.25, speed = 1600, range = 1200, radius = 110, col = true},
	--{owner = "Sona", name = "SonaCrescendo", type = "DelayLine", delay = 0.25, speed = 2400, range = 1000, width = 160, col = false},
	--{owner = "Malphite", name = "UFSlash", type = "PromptCircle", delay = 0, speed = 550, range = 1000, radius = 300},
	--{owner = "Ahri", name = "AhriSeduce", type = "DelayLine", delay = 0.25, speed = 1000, range = 1000, width = 60, col = true},
	--{owner = "Leona", name = "LeonaZenithBlade", type = "DelayLine", delay = 0.25, speed = 2000, range = 950, width = 110, col = true},
	--{owner = "Leona", name = "LeonaSolarFlare", type = "DelayCircle", delay = 0.25, speed = 1500, range = 1200, radius = 300},
	--{owner = "Chogath", name = "Rupture", type = "PromptCircle", delay = 0, speed = 950, range = 950, radius = 250},
	--{owner = "Anivia", name = "FlashFrostSpell", type = "DelayLine", delay = 0.25, speed = 850, range = 1100, width = 110, col = false},
	--{owner = "Zyra", name = "ZyraGraspingRoots", type = "DelayLine", delay = 0.25, speed = 1150, range = 1150, width = 70, col = false},
	--{owner = "Zyra", name = "ZyraQFissure", type = "DelayCircle", delay = 1, speed = 0, range = 800, radius = 250},
	--{owner = "Nautilus", name = "NautilusAnchorDrag", type = "DelayLine", delay = 0.25, speed = 2000, range = 1080, width = 80, col = true},
	--{owner = "Caitlyn", name = "CaitlynEntrapment", type = "DelayLine", delay = 0.15, speed = 2000, range = 950, width = 80, col = true},
	--{owner = "Mundo", name = "InfectedCleaverMissile", type = "DelayLine", delay = 0.25, speed = 2000, range = 1050, with = 75, col = true},
	--{owner = "Brand", name = "BrandBlaze", type = "DelayLine", delay = 0.25, speed = 1600, range = 1100, width = 80, col = true},
	
  }
  
  self.Spells =
  {
    {owner = "Annie", name = "Disintegrate"}, --Q
    {owner = "Diana", name = "DianaTeleport"}, --R
    {owner = "Garen", name = "GarenQAttack", prompt = true}, --Q
    {owner = "MissFortune", name = "MissFortuneRicochetShot"}, --Q
    {owner = "Warwick", name = "HungeringStrike", prompt = true}, --Q
    {owner = "Zilean", name = "ZileanQ"}, --Q
    
    {owner = "Annie", name = "Incinerate"}, --W
    --{owner = "Lux", name = "luxlightstriketoggle", type = "PromptCircle", delay = 0, radius = 350}, --E
    
    {owner = "MissFortune", name = "MissFortuneScattershot"}, --E
    {owner = "Nasus", name = "NasusE"}, --E
    {owner = "Soraka", name = "SorakaQ"}, --Q
    {owner = "Zyra", name = "ZyraQFissure"}, --Q
	--[[
	--skillshots
	{owner = "Lux", name = "LuxLightStrikeKugel", type = "DelayCircle", delay = 0.25, speed = 1300, range = 1100, radius = 270}, --E
	{owner = "Kennen", name = "KennenShurikenHurlMissile1", type = "DelayLine", delay = 0.18, speed = 1700, range = 1050, width = 80, col = true},
	{owner = "Gragas", name = "GragasBarrelRoll", type = "DelayCircle", delay = 0.25, speed = 1000, range = 1115, radius = 180},
	{owner = "Gragas", name = "GragasBarrelRollMissile", type = "PromptCircle", delay = 0, speed = 1000, range = 1115, radius = 180},
	{owner = "Syndra", name = "SyndraQ", type = "DelayCircle", delay = 0.25, speed = 500, range = 825, radius = 175},
	{owner = "Syndra", name = "syndrawcast", type = "DelayLine", delay = 0.25, speed = 500, range = 950, witdh = 200, col = false},
	{owner = "Ezreal", name = "EzrealMysticShot", type = "DelayLine", delay = 0.25, speed = 2000, range = 1200, width = 80, col = true},
	{owner = "Ezreal", name = "EzrealEssenceFlux", type = "DelayLine", delay = 0.25, speed = 1500, range = 1050, width = 80, col = false},
	{owner = "Ezreal", name = "EzrealTrueshotBarrage", type = "DelayLine", delay = 1, speed = 2000, range = 20000, width = 160, col = false},
	{owner = "Ahri", name = "AhriOrbofDeception", type = "DelayLine", delay = 0.25, speed = 2500, range = 900, width = 100, col = false},
	{owner = "Ahri", name = "AhriOrbofDeceptionherpityderp", type = "DelayLine", delay = 0.61, speed = 915, range = 900, width = 100, col = false},
	{owner = "Olaf", name = "OlafAxeThrow", type = "DelayLine", delay = 0.25, speed = 1600, range = 1000, width = 90, col = false},
	{owner = "Karthus", name = "KarthusLayWasteA", type = "DelayCircle", delay = 0.25, speed = 20, range = 875, witdh = 450},
	{owner = "Zyra", name = "zyrapassivedeathmanager", type = "DelayLine", delay = 0.5, speed = 2000, range = 1474, width = 60, col = false},
	{owner = "Caitlyn", name = "CaitlynPiltoverPeacemaker", type = "DelayLine", delay = 0.625, speed = 2200, range = 1300, width = 90, col = false},
	{owner = "Brand", name = "BrandFissure", type = "DelayCircle", delay = 0.25, speed = 900, range = 1100, radius = 240},]]
  }
  self.champions2 = {
	["Lux"]                      = {charName = "Lux", skillshots = {
		["Light Binding"]           = {name = "LightBinding", 				spellName = "LuxLightBinding", 						spellDelay = 250, 	projectileName = "LuxLightBinding_mis.troy", 			projectileSpeed = 1200, 	range = 1300, radius = 80, 	type = "line", 		cc = "true", 	collision = "false", shieldnow = "true"},
		["Lux LightStrike Kugel"]   = {name = "LuxLightStrikeKugel", 	spellName = "LuxLightStrikeKugel", 				spellDelay = 250, 	projectileName = "LuxLightstrike_mis.troy", 			projectileSpeed = 1400, 	range = 1100, radius = 275, type = "circle", 	cc = "false", collision = "false", shieldnow = "false"},
		["Lux Malice Cannon"]       = {name = "LuxMaliceCannon", 			spellName = "LuxMaliceCannon", 						spellDelay = 1375, 	projectileName = "LuxMaliceCannon_cas.troy", 			projectileSpeed = 50000, 	range = 3500, radius = 190, type = "line", 		cc = "true", 	collision = "false", shieldnow = "true"}}},
	["Nidalee"]                  = {charName = "Nidalee", skillshots = {			
		["Javelin Toss"]            = {name = "JavelinToss", 					spellName = "JavelinToss", 								spellDelay = 125, 	projectileName = "nidalee_javelinToss_mis.troy", 	projectileSpeed = 1300, 	range = 1500, radius = 60, 	type = "line", 		cc = "true", 	collision = "true", shieldnow = "true"}}},
	["Kennen"]                   = {charName = "Kennen", skillshots = {
		["Thundering Shuriken"]     = {name = "ThunderingShuriken", 	spellName = "KennenShurikenHurlMissile1", spellDelay = 180, 	projectileName = "kennen_ts_mis.troy", 						projectileSpeed = 1700, 	range = 1050, radius = 50, 	type = "line", 		cc = "false", collision = "true", shieldnow = "true"}}},
	["Amumu"]                    = {charName = "Amumu", skillshots = {
		["Bandage Toss"]            = {name = "BandageToss", 					spellName = "BandageToss", 								spellDelay = 250, 	projectileName = "Bandage_beam.troy", 						projectileSpeed = 2000, 	range = 1100, radius = 80, 	type = "line", 		cc = "true", 	collision = "true", shieldnow = "true"}}},
	["Lee Sin"]                  = {charName = "LeeSin", skillshots = {
		["Sonic Wave"]              = {name = "SonicWave", 						spellName = "BlindMonkQOne", 							spellDelay = 250, 	projectileName = "blindMonk_Q_mis_01.troy", 			projectileSpeed = 1800, 	range = 1100, radius = 70, type = "line", 		cc = "true", 	collision = "true", shieldnow = "true"}}},
	["Morgana"]                  = {charName = "Morgana", skillshots = {
		["Dark Binding Missile"]    = {name = "DarkBinding", 					spellName = "DarkBindingMissile", spellDelay = 250, projectileName = "DarkBinding_mis.troy", projectileSpeed = 1200, range = 1300, radius = 80, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Sejuani"]                  = {charName = "Sejuani", skillshots = {
		["SejuaniR"]                = {name = "SejuaniR", 						spellName = "SejuaniGlacialPrisonCast", spellDelay = 250, projectileName = "Sejuani_R_mis.troy", projectileSpeed = 1600, range = 1200, radius = 110, type="line", cc = "true", collision = "false", shieldnow = "true"}}},
	["Sona"]                     = {charName = "Sona", skillshots = {
		["Crescendo"]               = {name = "Crescendo", 						spellName = "SonaCrescendo", spellDelay = 240, projectileName = "SonaCrescendo_mis.troy", projectileSpeed = 2400, range = 1000, radius = 160, type = "line", cc = "true", collision = "false", shieldnow = "true"}}},
	["Gragas"]                   = {charName = "Gragas", skillshots = {
		["Barrel Roll"]             = {name = "BarrelRoll", 					spellName = "GragasBarrelRoll", spellDelay = 250, projectileName = "gragas_barrelroll_mis.troy", projectileSpeed = 1000, range = 1115, radius = 180, type = "circle", cc = "false", collision = "false", shieldnow = "false"},
		["Barrel Roll Missile"]     = {name = "BarrelRollMissile", 		spellName = "GragasBarrelRollMissile", spellDelay = 0, projectileName = "gragas_barrelroll_mis.troy", projectileSpeed = 1000, range = 1115, radius = 180, type = "circle", cc = "false", collision = "false", shieldnow = "false"}}},
	["Syndra"]                   = {charName = "Syndra", skillshots = {
		["Q"]                       = {name = "Q", 										spellName = "SyndraQ", spellDelay = 250, projectileName = "Syndra_Q_fall.troy", projectileSpeed = 500, range = 825, radius = 175, type = "circular", cc = "false", collision = "false", shieldnow = "true"},
		["W"]                       = {name = "W", 										spellName = "syndrawcast", spellDelay = 250, projectileName = "Syndra_W_fall.troy", projectileSpeed = 500, range = 950, radius = 200, type = "circular", cc = "false", collision = "false", shieldnow = "true"}}},
	["Malphite"]                 = {charName = "Malphite", skillshots = {
		["UFSlash"]                 = {name = "UFSlash", 							spellName = "UFSlash", spellDelay = 0, projectileName = "UnstoppableForce_cas.troy", projectileSpeed = 550, range = 1000, radius = 300, type="circular", cc = "true", collision = "false", shieldnow = "true"}}},
	["Ezreal"]                   = {charName = "Ezreal", skillshots = {
		["Mystic Shot"]             = {name = "MysticShot",      			spellName = "EzrealMysticShot",      spellDelay = 250, projectileName = "Ezreal_bow.troy",  projectileSpeed = 2000, range = 1200,  radius = 80,  type = "line", cc = "false", collision = "true", shieldnow = "true"},
		["Essence Flux"]            = {name = "EssenceFlux",     			spellName = "EzrealEssenceFlux",     spellDelay = 250, projectileName = "Ezreal_essenceflux_mis.troy", projectileSpeed = 1500, range = 1050,  radius = 80,  type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["Mystic Shot (Pulsefire)"] = {name = "MysticShot",      			spellName = "EzrealMysticShotPulse", spellDelay = 250, projectileName = "Ezreal_mysticshot_mis.troy",  projectileSpeed = 2000, range = 1200,  radius = 80,  type = "line", cc = "false", collision = "true", shieldnow = "true"},
		["Trueshot Barrage"]        = {name = "TrueshotBarrage", 			spellName = "EzrealTrueshotBarrage", spellDelay = 1000, projectileName = "Ezreal_TrueShot_mis.troy",    projectileSpeed = 2000, range = 20000, radius = 160, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Ahri"]                     = {charName = "Ahri", skillshots = {
		["Orb of Deception"]        = {name = "OrbofDeception", 			spellName = "AhriOrbofDeception", spellDelay = 250, projectileName = "Ahri_Orb_mis.troy", projectileSpeed = 2500, range = 900, radius = 100, type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["Orb of Deception Back"]   = {name = "OrbofDeceptionBack", 	spellName = "AhriOrbofDeceptionherpityderp", spellDelay = 250+360, projectileName = "Ahri_Orb_mis_02.troy", projectileSpeed = 915, range = 900, radius = 100, type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["Charm"]                   = {name = "Charm", 								spellName = "AhriSeduce", spellDelay = 250, projectileName = "Ahri_Charm_mis.troy", projectileSpeed = 1000, range = 1000, radius = 60, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Olaf"]                     = {charName = "Olaf", skillshots = {
		["Undertow"]                = {name = "Undertow", 						spellName = "OlafAxeThrow", spellDelay = 250, projectileName = "olaf_axe_mis.troy", projectileSpeed = 1600, range = 1000, radius = 90, type = "line", cc = "true", collision = "false", shieldnow = "true"}}},
	["Leona"]                    = {charName = "Leona", skillshots = {
		["Zenith Blade"]            = {name = "LeonaZenithBlade", 		spellName = "LeonaZenithBlade", spellDelay = 250, projectileName = "Leona_ZenithBlade_mis.troy", projectileSpeed = 2000, range = 950, radius = 110, type = "line", cc = "true", collision = "false", shieldnow = "true"},
		["Leona Solar Flare"]       = {name = "LeonaSolarFlare", 			spellName = "LeonaSolarFlare", spellDelay = 250, projectileName = "Leona_SolarFlare_cas.troy", projectileSpeed = 1500, range = 1200, radius = 300, type = "circular", cc = "true", collision = "false", shieldnow = "true"}}},
	["Karthus"]                  = {charName = "Karthus", skillshots = {
		["Lay Waste"]               = {name = "LayWaste", 						spellName = "KarthusLayWasteA", spellDelay = 250, projectileName = "Karthus_Base_Q_Point_red.troy", projectileSpeed = 20, range = 875, radius = 450, type = "circular", cc = "false", collision = "false", shieldnow = "true"}}},
	["Chogath"]                  = {charName = "Chogath", skillshots = {
		["Rupture"]                 = {name = "Rupture", 							spellName = "Rupture", spellDelay = 0, projectileName = "rupture_cas_01_red_team.troy", projectileSpeed = 950, range = 950, radius = 250, type = "circular", cc = "true", collision = "false", shieldnow = "true"}}},
	["Blitzcrank"]               = {charName = "Blitzcrank", skillshots = {
		["Rocket Grab"]             = {name = "RocketGrab", 					spellName = "RocketGrabMissile", spellDelay = 250, projectileName = "FistGrab_mis.troy", projectileSpeed = 1800, range = 1050, radius = 70, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Anivia"]                   = {charName = "Anivia", skillshots = {
		["Flash Frost"]             = {name = "FlashFrost", 					spellName = "FlashFrostSpell", spellDelay = 250, projectileName = "cryo_FlashFrost_mis.troy", projectileSpeed = 850, range = 1100, radius = 110, type = "line", cc = "true", collision = "false", shieldnow = "true"}}},
	["Zyra"]                     = {charName = "Zyra", skillshots = {
		["Grasping Roots"]          = {name = "GraspingRoots", 				spellName = "ZyraGraspingRoots", spellDelay = 250, projectileName = "Zyra_E_sequence_impact.troy", projectileSpeed = 1150, range = 1150, radius = 70,  type = "line", cc = "true", collision = "false", shieldnow = "true"},
		["Zyra Passive Death"]      = {name = "ZyraPassive", 					spellName = "zyrapassivedeathmanager", spellDelay = 500, projectileName = "zyra_passive_plant_mis.troy", projectileSpeed = 2000, range = 1474, radius = 60,  type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["Deadly Bloom"]            = {name = "DeadlyBloom", 					spellName = "ZyraQFissure", spellDelay = 1000, projectileName = "Zyra_Q_cas.troy", projectileSpeed = 0, range = 800, radius = 250, type = "circular", cc = "false", collision = "false", shieldnow = "true"}}},
	["Nautilus"]                 = {charName = "Nautilus", skillshots = {
		["Dredge Line"]             = {name = "DredgeLine", 					spellName = "NautilusAnchorDrag", spellDelay = 250, projectileName = "Nautilus_Q_mis.troy", projectileSpeed = 2000, range = 1080, radius = 80, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Caitlyn"]                  = {charName = "Caitlyn", skillshots = {
		["Piltover Peacemaker"]     = {name = "PiltoverPeacemaker", 	spellName = "CaitlynPiltoverPeacemaker", spellDelay = 625, projectileName = "caitlyn_Q_mis.troy", projectileSpeed = 2200, range = 1300, radius = 90, type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["Caitlyn Entrapment"]      = {name = "CaitlynEntrapment", 		spellName = "CaitlynEntrapment", spellDelay = 150, projectileName = "caitlyn_entrapment_mis.troy", projectileSpeed = 2000, range = 950, radius = 80, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Mundo"]                    = {charName = "DrMundo", skillshots = {
		["Infected Cleaver"]        = {name = "InfectedCleaver", 			spellName = "InfectedCleaverMissile", spellDelay = 250, projectileName = "dr_mundo_infected_cleaver_mis.troy", projectileSpeed = 2000, range = 1050, radius = 75, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Brand"]                    = {charName = "Brand", skillshots = {
		["BrandBlaze"]              = {name = "BrandBlaze", 					spellName = "BrandBlaze", spellDelay = 250, projectileName = "BrandBlaze_mis.troy", projectileSpeed = 1600, range = 1100, radius = 80, type = "line", cc = "true", collision = "true", shieldnow = "true"},
		["Pillar of Flame"]         = {name = "PillarofFlame", 				spellName = "BrandFissure", spellDelay = 250, projectileName = "BrandPOF_tar_green.troy", projectileSpeed = 900, range = 1100, radius = 240, type = "circular", cc = "false", collision = "false", shieldnow = "true"}}},
	["Corki"]                    = {charName = "Corki", skillshots = {
		["Missile Barrage"]         = {name = "MissileBarrage", 			spellName = "MissileBarrage", spellDelay = 250, projectileName = "corki_MissleBarrage_mis.troy", projectileSpeed = 2000, range = 1300, radius = 40, type = "line", cc = "false", collision = "true", shieldnow = "true"},
		["Missile Barrage big"]     = {name = "MissileBarragebig", 		spellName = "MissileBarrage!", spellDelay = 250, projectileName = "Corki_MissleBarrage_DD_mis.troy", projectileSpeed = 2000, range = 1300, radius = 40, type = "line", cc = "false", collision = "true", shieldnow = "true"}}},
	["TwistedFate"]              = {charName = "TwistedFate", skillshots = {
		["Loaded Dice"]             = {name = "LoadedDice", 					spellName = "WildCards", spellDelay = 250, projectileName = "Roulette_mis.troy", projectileSpeed = 1000, range = 1450, radius = 40, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Swain"]                    = {charName = "Swain", skillshots = {
		["Nevermove"]               = {name = "Nevermove", 						spellName = "SwainShadowGrasp", spellDelay = 250, projectileName = "swain_shadowGrasp_transform.troy", projectileSpeed = 1000, range = 900, radius = 180, type = "circular", cc = "true", collision = "false", shieldnow = "true"}}},
	["Cassiopeia"]               = {charName = "Cassiopeia", skillshots = {
		["Noxious Blast"]           = {name = "NoxiousBlast", 				spellName = "CassiopeiaNoxiousBlast", spellDelay = 250, projectileName = "CassNoxiousSnakePlane_green.troy", projectileSpeed = 500, range = 850, radius = 130, type = "circular", cc = "false", collision = "false", shieldnow = "true"}}},
	["Sivir"]                    = {charName = "Sivir", skillshots = {
		["Boomerang Blade"]         = {name = "BoomerangBlade", 			spellName = "SivirQ", spellDelay = 250, projectileName = "Sivir_Base_Q_mis.troy", projectileSpeed = 1350, range = 1150, radius = 101, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Ashe"]                     = {charName = "Ashe", skillshots = {
		["Enchanted Arrow"]         = {name = "EnchantedArrow", 			spellName = "EnchantedCrystalArrow", spellDelay = 250, projectileName = "Ashe_Base_R_mis.troy", projectileSpeed = 1600, range = 25000, radius = 120, type = "line", cc = "true", collision = "false", shieldnow = "true"}}},
	["KogMaw"]                   = {charName = "KogMaw", skillshots = {
		["Living Artillery"]        = {name = "LivingArtillery", 			spellName = "KogMawLivingArtillery", spellDelay = 250, projectileName = "KogMawLivingArtillery_mis.troy", projectileSpeed = 1050, range = 2200, radius = 225, type = "circular", cc = "false", collision = "false", shieldnow = "true"}}},
	["Khazix"]                   = {charName = "Khazix", skillshots = {
		["KhazixW"]                 = {name = "KhazixW", 							spellName = "KhazixW", spellDelay = 250, projectileName = "Khazix_W_mis_enhanced.troy", projectileSpeed = 1700, range = 1025, radius = 70, type = "line", cc = "true", collision = "true", shieldnow = "true"},
		["khazixwlong"]             = {name = "khazixwlong", 					spellName = "khazixwlong", spellDelay = 250, projectileName = "Khazix_W_mis_enhanced.troy", projectileSpeed = 1700, range = 1025, radius = 70, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Zed"]                      = {charName = "Zed", skillshots = {
		["ZedShuriken"]             = {name = "ZedShuriken", 					spellName = "ZedShuriken", spellDelay = 250, projectileName = "Zed_Q_Mis.troy", projectileSpeed = 1700, range = 925, radius = 50, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Leblanc"]                  = {charName = "Leblanc", skillshots = {
		["Ethereal Chains"]         = {name = "EtherealChains", 			spellName = "LeblancSoulShackle", spellDelay = 250, projectileName = "leBlanc_shackle_mis.troy", projectileSpeed = 1600, range = 960, radius = 70, type = "line", cc = "true", collision = "true", shieldnow = "true"},
		["Ethereal Chains R"]       = {name = "EtherealChainsR", 			spellName = "LeblancSoulShackleM", spellDelay = 250, projectileName = "leBlanc_shackle_mis_ult.troy", projectileSpeed = 1600, range = 960, radius = 70, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Draven"]                   = {charName = "Draven", skillshots = {
		["Stand Aside"]             = {name = "StandAside", 					spellName = "DravenDoubleShot", spellDelay = 250, projectileName = "Draven_E_mis.troy", projectileSpeed = 1400, range = 1100, radius = 130, type = "line", cc = "true", collision = "false", shieldnow = "true"},
		["DravenR"]                 = {name = "DravenR", 							spellName = "DravenRCast", spellDelay = 500, projectileName = "Draven_R_mis!.troy", projectileSpeed = 2000, range = 25000, radius = 160, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Elise"]                    = {charName = "Elise", skillshots = {
		["Cocoon"]                  = {name = "Cocoon", 							spellName = "EliseHumanE", spellDelay = 250, projectileName = "Elise_human_E_mis.troy", projectileSpeed = 1450, range = 1100, radius = 70, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Lulu"]                     = {charName = "Lulu", skillshots = {
		["LuluQ"]                   = {name = "LuluQ", 								spellName = "LuluQ", spellDelay = 250, projectileName = "Lulu_Q_Mis.troy", projectileSpeed = 1450, range = 1000, radius = 50, type = "line", cc = "true", collision = "false", shieldnow = "true"}}},
	["Thresh"]                   = {charName = "Thresh", skillshots = {
		["ThreshQ"]                 = {name = "ThreshQ", 							spellName = "ThreshQ", spellDelay = 500, projectileName = "Thresh_Q_whip_beam.troy", projectileSpeed = 1900, range = 1100, radius = 65, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Shen"]                     = {charName = "Shen", skillshots = {
		["ShadowDash"]              = {name = "ShadowDash", 					spellName = "ShenShadowDash", spellDelay = 0, projectileName = "shen_shadowDash_mis.troy", projectileSpeed = 3000, range = 575, radius = 50, type = "line", cc = "true", collision = "false", shieldnow = "true"}}},
	["Quinn"]                    = {charName = "Quinn", skillshots = {
		["QuinnQ"]                  = {name = "QuinnQ", 							spellName = "QuinnQ", spellDelay = 250, projectileName = "Quinn_Q_missile.troy", projectileSpeed = 1550, range = 1050, radius = 80, type = "line", cc = "false", collision = "true", shieldnow = "true"}}},
	["Veigar"]                   = {charName = "Veigar", skillshots = {
		["Dark Matter"]             = {name = "VeigarDarkMatter", 		spellName = "VeigarDarkMatter", spellDelay = 250, projectileName = "!", projectileSpeed = 900, range = 900, radius = 225, type = "circular", cc = "false", collision = "false", shieldnow = "true"}}},
	["Jayce"]                    = {charName = "Jayce", skillshots = {
		["JayceShockBlast"]         = {name = "JayceShockBlast", 			spellName = "jayceshockblast", spellDelay = 250, projectileName = "JayceOrbLightning.troy", projectileSpeed = 1450, range = 1050, radius = 70, type = "line", cc = "false", collision = "true", shieldnow = "true"},
		["JayceShockBlastCharged"]  = {name = "JayceShockBlastCharged", spellName = "jayceshockblast", spellDelay = 250, projectileName = "JayceOrbLightningCharged.troy", projectileSpeed = 2350, range = 1600, radius = 70, type = "line", cc = "false", collision = "true", shieldnow = "true"}}},
	["Nami"]                     = {charName = "Nami", skillshots = {
		["NamiQ"]                   = {name = "NamiQ", 								spellName = "NamiQ", spellDelay = 250, projectileName = "Nami_Q_mis.troy", projectileSpeed = 1500, range = 1625, radius = 225, type = "circle", cc = "true", collision = "false", shieldnow = "true"}}},
	["Fizz"]                     = {charName = "Fizz", skillshots = {
		["Fizz Ultimate"]           = {name = "FizzULT", 							spellName = "FizzMarinerDoom", spellDelay = 250, projectileName = "Fizz_UltimateMissile.troy", projectileSpeed = 1350, range = 1275, radius = 80, type = "line", cc = "true", collision = "false", shieldnow = "true"}}},
	["Varus"]                    = {charName = "Varus", skillshots = {
		["Varus Q Missile"]         = {name = "VarusQMissile", 				spellName = "somerandomspellnamethatwillnevergetcalled", spellDelay = 0, projectileName = "VarusQ_mis.troy", projectileSpeed = 1900, range = 1600, radius = 70, type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["VarusR"]                  = {name = "VarusR", 							spellName = "VarusR", spellDelay = 250, projectileName = "VarusRMissile.troy", projectileSpeed = 1950, range = 1250, radius = 100, type = "line", cc = "true", collision = "false", shieldnow = "true"}}},
	["Karma"]                    = {charName = "Karma", skillshots = {
		["KarmaQ"]                  = {name = "KarmaQ", 							spellName = "KarmaQ", spellDelay = 250, projectileName = "TEMP_KarmaQMis.troy", projectileSpeed = 1700, range = 1050, radius = 90, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
	["Aatrox"]                   = {charName = "Aatrox", skillshots = {
		["Blade of Torment"]        = {name = "BladeofTorment", 			spellName = "AatroxE", spellDelay = 250, projectileName = "AatroxBladeofTorment_mis.troy", projectileSpeed = 1200, range = 1075, radius = 75, type = "line", cc = "true", collision = "false", shieldnow = "true"},
		["AatroxQ"]                 = {name = "AatroxQ", 							spellName = "AatroxQ", spellDelay = 250, projectileName = "AatroxQ.troy", projectileSpeed = 450, range = 650, radius = 145, type = "circle", cc = "true", collision = "false", shieldnow = "true"}}},
	["Xerath"]                   = {charName = "Xerath", skillshots = {
		["Xerath Arcanopulse"]      = {name = "xeratharcanopulse21", 	spellName = "xeratharcanopulse2", spellDelay = 400, projectileName = "hiu", projectileSpeed = 25000, range = 0, radius = 100, type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["XerathArcaneBarrage2"]    = {name = "XerathArcaneBarrage2", spellName = "XerathArcaneBarrage2", spellDelay = 500, projectileName = "Xerath_Base_W_cas.troy", projectileSpeed = 0, range = 1100, radius = 325, type = "circular", cc = "true", collision = "false", shieldnow = "true"},
		["XerathMageSpear"]         = {name = "XerathMageSpear", 			spellName = "XerathMageSpear", spellDelay = 250, projectileName = "Xerath_Base_E_mis.troy", projectileSpeed = 1600, range = 1050, radius = 125, type = "line", cc = "true", collision = "true", shieldnow = "true"},
		["xerathlocuspulse"]        = {name = "xerathlocuspulse", 		spellName = "xerathlocuspulse", spellDelay = 250, projectileName = "Xerath_Base_R_mis.troy", projectileSpeed = 300, range = 5600, radius = 265, type = "circular", cc = "false", collision = "false", shieldnow = "true"}}},
	["Lucian"]                   = {charName = "Lucian", skillshots = {
		["LucianQ"]                 = {name = "LucianQ", 							spellName = "LucianQ", spellDelay = 350, projectileName = "Lucian_Q_laser.troy", projectileSpeed = 25000, range = 570*2, radius = 65, type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["LucianW"]                 = {name = "LucianW", 							spellName = "LucianW", spellDelay = 300, projectileName = "Lucian_W_mis.troy", projectileSpeed = 1600, range = 1000, radius = 80, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Viktor"]                   = {charName = "Viktor", skillshots = {
		["ViktorDeathRay1"]         = {name = "ViktorDeathRay1", 			spellName = "ViktorDeathRay!", spellDelay = 500, projectileName = "Viktor_DeathRay_Fix_Mis.troy", projectileSpeed = 780, range = 700, radius = 80, type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["ViktorDeathRay2"]         = {name = "ViktorDeathRay2", 			spellName = "ViktorDeathRay!", spellDelay = 500, projectileName = "Viktor_DeathRay_Fix_Mis_Augmented.troy", projectileSpeed = 780, range = 700, radius = 80, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Rumble"]                   = {charName = "Rumble", skillshots = {
		["RumbleGrenade"]           = {name = "RumbleGrenade", 				spellName = "RumbleGrenade", spellDelay = 250, projectileName = "rumble_taze_mis.troy", projectileSpeed = 2000, range = 950, radius = 90, type = "line", cc = "true", collision = "true", shieldnow = "true"}}},
		["Nocturne"]               = {charName = "Nocturne", skillshots = {
		["NocturneDuskbringer"]     = {name = "NocturneDuskbringer", 	spellName = "NocturneDuskbringer", spellDelay = 250, projectileName = "NocturneDuskbringer_mis.troy", projectileSpeed = 1400, range = 1125, radius = 60, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Yasuo"]                    = {charName = "Yasuo", skillshots = {
		["yasuoq3"]                 = {name = "yasuoq3", 							spellName = "yasuoq3w", spellDelay = 250, projectileName = "Yasuo_Q_wind_mis.troy", projectileSpeed = 1200, range = 1000, radius = 80, type = "line", cc = "true", collision = "false", shieldnow = "true"},
		["yasuoq1"]                 = {name = "yasuoq1", 							spellName = "yasuoQW", spellDelay = 250, projectileName = "Yasuo_Q_WindStrike.troy", projectileSpeed = 25000, range = 475, radius = 40, type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["yasuoq2"]                 = {name = "yasuoq2", 							spellName = "yasuoq2w", spellDelay = 250, projectileName = "Yasuo_Q_windstrike_02.troy", projectileSpeed = 25000, range = 475, radius = 40, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Orianna"]                  = {charName = "Orianna", skillshots = {
		["OrianaIzunaCommand"]      = {name = "OrianaIzunaCommand", 	spellName = "OrianaIzunaCommand", spellDelay = 0, projectileName = "Oriana_Ghost_mis.troy", projectileSpeed = 1300, range = 800, radius = 80, type = "line", cc = "true", collision = "false", shieldnow = "true"},
		["OrianaDetonateCommand"]   = {name = "OrianaDetonateCommand", spellName = "OrianaDetonateCommand", spellDelay = 100, projectileName = "Oriana_Shockwave_nova.troy", projectileSpeed = 400, range = 2000, radius = 400, type = "circular", cc = "true", collision = "false", shieldnow = "true"}}},
	["Ziggs"]                    = {charName = "Ziggs", skillshots = {
		["ZiggsQ"]                  = {name = "ZiggsQ", 							spellName = "ZiggsQ", spellDelay = 250, projectileName = "ZiggsQ.troy", projectileSpeed = 1700, range = 1400, radius = 155, type = "line", cc = "false", collision = "true", shieldnow = "true"}}},
	["Annie"]                    = {charName = "Annie", skillshots = {
		["AnnieR"]                  = {name = "AnnieR", spellName = "InfernalGuardian", spellDelay = 100, projectileName = "nothing", projectileSpeed = 0, range = 600, radius = 300, type = "circular", cc = "true", collision = "false", shieldnow = "true"}}},
	["Galio"]                    = {charName = "Galio", skillshots = {
		["GalioResoluteSmite"]      = {name = "GalioResoluteSmite", spellName = "GalioResoluteSmite", spellDelay = 250, projectileName = "galio_concussiveBlast_mis.troy", projectileSpeed = 850, range = 2000, radius = 200, type = "circle", cc = "true", collision = "false", shieldnow = "true"}}},
	["Jinx"]                     = {charName = "Jinx", skillshots = {
		["W"]                       = {name = "Zap", 									spellName = "JinxW", spellDelay = 600, projectileName = "Jinx_W_Beam.troy", projectileSpeed = 3300, range = 1450, radius = 70, type = "line", cc = "true", collision = "true", shieldnow = "true"},
		["R"]                       = {name = "SuperMegaDeathRocket", spellName = "JinxRWrapper", spellDelay = 600, projectileName = "Jinx_R_Mis.troy", projectileSpeed = 1700, range = 20000, radius = 120, type = "line", cc = "false", collision = "false", shieldnow = "true"}}},
	["Velkoz"]                   = {charName = "Velkoz", skillshots = {
		["PlasmaFission"]           = {name = "PlasmaFission", 				spellName = "VelKozQ", spellDelay = 250, projectileName = "Velkoz_Base_Q_mis.troy", projectileSpeed = 1200, range = 1050, radius = 120, type = "line", cc = "true", collision = "true", shieldnow = "true"},
		["Plasma Fission Split"]    = {name = "VelKozQSplit", 				spellName = "VelKozQ", spellDelay = 250, projectileName = "Velkoz_Base_Q_Split_mis.troy", projectileSpeed = 1200, range = 1050, radius = 120, type = "line", cc = "true", collision = "true", shieldnow = "true"},
		["Void Rift"]               = {name = "VelkozW", spellName = "VelkozW", spellDelay = 250, projectileName = "Velkoz_Base_W_Turret.troy", projectileSpeed = 1200, range = 1050, radius = 125, type = "line", cc = "false", collision = "false", shieldnow = "true"},
		["Tectonic Disruption"]     = {name = "VelkozE", spellName = "VelkozE", spellDelay = 250, projectileName = "DarkBinding_mis.troy", projectileSpeed = 1200, range = 800, radius = 225, type = "circular", cc = "true", collision = "false", shieldnow = "true"}}}, 
	["Heimerdinger"]             = {charName = "Heimerdinger", skillshots = {
	--["Micro-Rockets"]           = {name = "MicroRockets", spellName = "HeimerdingerW1", spellDelay = 500, projectileName = "Heimerdinger_Base_w_Mis.troy", projectileSpeed = 902, range = 1325, radius = 100, type = "line", cc = "false", collision = "true", shieldnow = "true"},
	--["Storm Grenade"]           = {name = "StormGrenade", spellName = "HeimerdingerE", spellDelay = 250, projectileName = "Heimerdinger_Base_E_Mis.troy", projectileSpeed = 2500, range = 970, radius = 180, type = "circular", cc = "true", collision = "false", shieldnow = "true"},
	--["Micro-RocketsUlt"]        = {name = "MicroRocketsUlt", spellName = "HeimerdingerW2", spellDelay = 500, projectileName = "Heimerdinger_Base_W_Mis_Ult.troy", projectileSpeed = 902, range = 1325, radius = 100, type = "line", cc = "false", collision = "true", shieldnow = "true"},
	--["Storm Grenade"]           = {name = "StormGrenade", spellName = "HeimerdingerE2", spellDelay = 250, projectileName = "Heimerdinger_Base_E_Mis_Ult.troy", projectileSpeed = 2500, range = 970, radius = 180, type = "line", cc = "true", collision = "false", shieldnow = "true"},
	}},
	["Malzahar"]                 = {charName = "Malzahar", skillshots = {
		["Call Of The Void"]        = {name = "CallOfTheVoid", 				spellName ="AlZaharCalloftheVoid1", spellDelay = 0, projectileName = "AlzaharCallofthevoid_mis.troy", projectileSpeed = 1600, range = 450, radius = 100, type = "line", cc = "true", collision = "false", shieldnow = "true"}}}	,
	["Janna"]                    = {charName = "Janna", skillshots = {
		["Howling Gale"]            = {name = "HowlingGale", 					spellName ="HowlingGale", spellDelay = 0, projectileName = "HowlingGale_mis.troy", projectileSpeed = 500, range = 0, radius = 100, type = "line", cc = "true", collision = "false", shieldnow = "true"}}},
	["Braum"]                    = {charName = "Braum", skillshots = {
		["Winters Bite"]            = {name = "WintersBite", 					spellName = "BraumQ", spellDelay = 225, projectileName = "Braum_Base_Q_mis.troy", projectileSpeed = 1600, range = 1000, radius = 100, type = "line", cc = "false", collision = "true", shieldnow = "true"},
		["Glacial Fissure"]         = {name = "GlacialFissure", 			spellName = "BraumRWrapper", spellDelay = 500, projectileName = "Braum_Base_R_mis.troy", projectileSpeed = 1250, range = 1250, radius = 100, type = "line", cc = "false", collision = "true", shieldnow = "true"}}},
	["Ekko"]					 = {charName = "Ekko", skillshots = {
		["Timewinder"]				= {name = "Timewinder", spellName = "EkkoQ", spellDelay = 250, projectileName = "Ekko_Base_Q_Aoe_Dilation.troy", projectileSpeed = 1650, range = 950, radius = 60, type = "line", cc = "false", collision = "true", shieldnow = "true"},
		["Parallel Convergence"]	= {name = "Parallel Convergence", spellName = "EkkoW", spellDelay = 3750, projectileName = "Ekko_Base_W_Branch_Timeline.troy", projectileSpeed = 1650, radius = 373, type = "circular", cc = "false", collision = "false", shieldnow = "false"},
	}}
	}
  self.Ignore =
  {
    {owner = "Jax", name = "JaxRelentlessAttack"}, --Passive
    {owner = "Nunu", name = "Consume"}, --Q
    {owner = "Warwick", name = "infiniteduresschannel"}, --R
  }
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team ~= myHero.team then -- hero.team ~= myHero.team
			for i, owner in pairs(self.champions2) do
				if owner.charName == hero.charName then
					for i, spell in pairs(owner.skillshots) do
						name = tostring(spell.name)
						name2 = tostring(spell.name)
						col = false
						delay = 0
						_charName = owner.charName
						if spell.type:find("circular") then
							if spell.spellDelay == 0 then
								type = "PromptCircle"
							else
								type = "DelayCircle"
								delay = spell.spellDelay * 0.001
							end
							spell = {owner = owner.charName, name = spell.spellName, objname = spell.projectileName, range = spell.range, type = type, speed = spell.projectileSpeed, delay = delay, radius = spell.radius, col}
							if spell.cc == "true" then
								table.insert(self.DangerousSpells, spell)
							else
								table.insert(self.Spells, spell)
							end
						elseif spell.type:find("line") then
						
							if spell.spellDelay == 0 then
								type = "PromptLine"
							else
								type = "DelayLine"
								delay = spell.spellDelay * 0.001
								col = true
							end
							spell = {owner = owner.charName, name = spell.spellName, objname = spell.projectileName, type = type, range = spell.range, speed = spell.projectileSpeed, delay = delay, width = spell.radius, col = col}
							if spell.cc == "true" then
								table.insert(self.DangerousSpells, spell)
							else
								table.insert(self.Spells, spell)
							end
						end
					end
				end
			end
		end
	end
	
	self.Menu = m or scriptConfig("AutoShield", "AutoShield")
	local thefirst = true
	local registered = false
  
	for j, enemy in ipairs(self.EnemyHeroes) do
  
		local first = true
		local spells = 0
		
		for i=1, #self.DangerousSpells do
		
			if spells < 4 and self.DangerousSpells[i].owner == enemy.charName then
		  
				if not registered then
					self.Menu:addSubMenu("Dangerous Spells", "Dangerous")
					registered = true
				end
			
				if not thefirst and first then
					self.Menu.Dangerous:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
				end
			
				self.Menu.Dangerous:addParam(self.DangerousSpells[i].name, enemy.charName.." "..self.DangerousSpells[i].name, SCRIPT_PARAM_ONOFF, not self.DangerousSpells[i].off)
				thefirst = false
				first = false
				spells = spells+1
			end
		end
	end
  
  local thefirst = true
  local registered = false
  
	for j, enemy in ipairs(self.EnemyHeroes) do
  
		local first = true
		local spells = 0
    
		for i=1, #self.Spells do
    
			if spells < 4 and self.Spells[i].owner == enemy.charName then
      
				if not registered then
					self.Menu:addSubMenu("Normal Spells", "Normal")
					registered = true
				end
        
				if not thefirst and first then
					self.Menu.Normal:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
				end
        
				self.Menu.Normal:addParam(self.Spells[i].name, enemy.charName.." "..self.Spells[i].name, SCRIPT_PARAM_ONOFF, not self.Spells[i].off)
				thefirst = false
				first = false
				spells = spells+1
			end
		end
	end
    self.Menu:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
	self.Menu:addParam("Delay", "Delay", SCRIPT_PARAM_SLICE, 250, 0, 1000)
	self.Menu:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	self.Menu:addParam("OnlyDangerous", "Block only dangerous spells", SCRIPT_PARAM_ONOFF, false)
	
	AddTickCallback(function() self:ObjectShield() end)
	AddAnimationCallback(function(unit, animation) self:OnAnimation(unit, animation) end)
	AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
	AddRemoveBuffCallback(function(unit, buff) self:OnRemoveBuff(unit, buff) end)
	AddUpdateBuffCallback(function(unit, buff, stacks) self:OnUpdateBuff(unit, buff, stacks) end)
	AddDrawCallback(function() self:Draw() end)
end
function AutoShield:Draw()
	if self.Menu.Debug then
		DrawText(tostring(self.buffer), 13, 100, 100,ARGB(255, 0, 0, 0))
		for i, spells in pairs(self.Spells) do
			DrawText(spells.objname, 13, 100, 100+(39*i), ARGB(255, 0, 0, 0))
			DrawText("--------------------", 13, 100, 100+(39*i)+26, ARGB(255, 0, 0, 0))
		end
	end
	for _, object in pairs(self.object) do
		if object.type == "DelayLine" then
			local objPos = Vector(self:skillshotPosition(object))
			local from = object.endPos
			local to = object.startPos
			local From = from+(from-to):normalized()*myHero.boundingRadius
			local FromL = From+(to-from):perpendicular():normalized()*(object.width/2+myHero.boundingRadius)
			local FromR = From+(to-from):perpendicular2():normalized()*(object.width/2+myHero.boundingRadius)
			local To = to+(to-from):normalized()*myHero.boundingRadius
			local ToL = To+(to-from):perpendicular():normalized()*(object.width/2+myHero.boundingRadius)
			local ToR = To+(to-from):perpendicular2():normalized()*(object.width/2+myHero.boundingRadius)
			DrawCircle(from.x, from.y, from.z, object.width, 0xFFFFFF)
			DrawCircle(to.x, to.y, to.z, object.width, 0xFFFFFF)
			DrawCircle(objPos.x, objPos.y, objPos.z, object.width, 0xFFFFFF)
			DrawLine3D(FromL.x, FromL.y, FromL.z, ToL.x,ToL.y, ToL.z, 1, 0xFFFF0000)
			DrawLine3D(FromL.x, FromL.y, FromL.z, FromR.x,FromR.y, FromR.z, 1, 0xFFFF0000)
			DrawLine3D(ToR.x, ToR.y, ToR.z, FromR.x,FromR.y, FromR.z, 1, 0xFFFF0000)
			DrawLine3D(ToR.x, ToR.y, ToR.z, ToL.x,ToL.y, ToL.z, 1, 0xFFFF0000)
		elseif object.type == "PromptLine" then
			local from = object.endPos
			local to = object.startPos
			local From = from+(from-to):normalized()*myHero.boundingRadius
			local FromL = From+(to-from):perpendicular():normalized()*(object.width/2+myHero.boundingRadius)
			local FromR = From+(to-from):perpendicular2():normalized()*(object.width/2+myHero.boundingRadius)
			local To = to+(to-from):normalized()*myHero.boundingRadius
			local ToL = To+(to-from):perpendicular():normalized()*(object.width/2+myHero.boundingRadius)
			local ToR = To+(to-from):perpendicular2():normalized()*(object.width/2+myHero.boundingRadius)
			DrawCircle(from.x, from.y, from.z, object.width, 0xFFFFFF)
			DrawCircle(to.x, to.y, to.z, object.width, 0xFFFFFF)
			DrawLine3D(FromL.x, FromL.y, FromL.z, ToL.x,ToL.y, ToL.z, 1, 0xFFFF0000)
			DrawLine3D(FromL.x, FromL.y, FromL.z, FromR.x,FromR.y, FromR.z, 1, 0xFFFF0000)
			DrawLine3D(ToR.x, ToR.y, ToR.z, FromR.x,FromR.y, FromR.z, 1, 0xFFFF0000)
			DrawLine3D(ToR.x, ToR.y, ToR.z, ToL.x,ToL.y, ToL.z, 1, 0xFFFF0000)
		elseif object.type:find("Circle") then
			local from = object.endPos
			DrawCircle(from.x, from.y, from.z, object.radius, 0xFFFFFF)
			_radius = math.max(object.radius - (object.hitTime - os.clock()), 0)
			DrawCircle(from.x, from.y, from.z, _radius, 0xFFFF0000)
		end
	end
end

function AutoShield:E_Ready()
	return myHero:CanUseSpell(_E) == READY
end
function AutoShield:OnAnimation(unit, animation)
	if animation == "recall" then
		self.IsRecall = true
		self.RecallTime = os.clock()+8
	elseif animation == "recall_winddown" or animation == "Run" or animation == "Spell1" or animation == "Spell2" or animation == "Spell3" or animation == "Spell4" then
		self.IsRecall = false
	end
end
function AutoShield:OnProcessSpell(unit, spell)
	if self.Menu.Debug and unit.type == myHero.type and self.Menu.Debug then
		print(spell.name)
	end
	if (not self.Menu.Dangerous or not self.Menu.Dangerous[spell.name]) and (not self.Menu.Normal or not self.Menu.Normal[spell.name]) and GetDistance(unit) < 2000 then -- unit.isMe or
		return
	end
	if Test and unit.type == myHero.type and not spell.name:find("BasicAttack") and spell.name ~= "recall" then
		local registered = false
		for i=1, #self.DangerousSpells do
			if spell.name == self.DangerousSpells[i].name then
				registered = true
				break
			end
		end
		if not registered then
			for i=1, #self.Spells do
				if spell.name == self.Spells[i].name then
					registered = true
					break
				end
			end
		end
		if not registered then
			for i=1, #self.Ignore do
				if spell.name == self.Ignore[i].name then
					registered = true
					break
				end
			end
		end
		if not registered then
			if spell.target == nil then
				--print(unit.charName..": "..spell.name..", NonTarget")
			else
				if spell.target == unit then
				--print(unit.charName..": "..spell.name..", Self")
				elseif spell.target.team ~= unit.team then
				  --print(unit.charName..": "..spell.name..", Target: "..spell.target.charName)
				end
			end
		end
	end
	self:CheckUp(spell, self.DangerousSpells)
	if not self.Menu.OnlyDangerous then
		if self.Menu.Debug then
			print("Call non dangerous spell")
		end
		self:CheckUp(spell, self.Spells)
	end
end
function AutoShield:OnRemoveBuff(unit, buff)
	if buff.name == "kalistaexpungemarker" then
		self.Spears[unit.networkID] = nil
	end
end
function AutoShield:OnUpdateBuff(unit, buff, stacks)
	if buff.name == "kalistaexpungemarker" then
		self.Spears[unit.networkID] = true
	end
end
function AutoShield:CheckUp(spell, Spell)
  --[[if unit.charName == "Leesin" and spell.name == "??E" and (unit:CanUseSpell(_R) == READY or R ?? ??? <= 25-3*myHero:GetSpellData(_E).level) then
    return
  end]]
	if self.Menu.Debug then
		print("Loaded CheckUp")
	end
	for i=1, #Spell do
		if (spell.name == Spell[i].name) or (spell.name == Spell[i].objname) then
			if self.Menu.Debug then
				print(Spell[i].type)
			end
			if spell.target == nil then
				if self.IsRecall and self:WillBeHit(spell, Spell[i]) then
					if self:HitTimePredict(spell, Spell[i]) <= self.RecallTime-os.clock() then
						self:MakeObject(spell, Spell[i])
					end
				else
					if Spell[i].type == "PromptCircle" and Spell[i].delay == 0 then
						self:PromptShield(spell, Spell[i])
					else
						if self.Menu.Debug then
							print("Make")
						end
						self:MakeObject(spell, Spell[i])
					end
				end
			elseif spell.target == myHero then
				if Spell[i].prompt then
					self:CastE()
				else
					if Spell[i].type:find("Prompt") then
						--DelayAction(function() self:CastE() end, ?? ??-0.1)
					else
						if self.Menu.Debug then
							print("Make")
						end
						self:MakeObject(spell, Spell[i])
					end
				end
			end
			break
		end
	end
end
function _G.Vector.angleBetween(self, v1, v2)
  assert(VectorType(v1) and VectorType(v2), "Shield: angleBetween: wrong argument types (2 <Vector> expected)")
  local p1, p2 = (-self+v1), (-self+v2)
  local theta = p1:polar()-p2:polar()
  if theta < 0 then
    theta = theta+360
  elseif theta >= 360 then
    theta = theta-360
  end
  
  return theta
end
function AutoShield:WillBeHit(spell, Spell)
	if Spell.type == "DelayLine" or Spell.type == "PromptLine" then
		local from = Vector(spell.startPos)
		local to = Vector(spell.endPos)
		local From = from+(from-to):normalized()*myHero.boundingRadius
		local FromL = From+(to-from):perpendicular():normalized()*(Spell.width/2+myHero.boundingRadius)
		local FromR = From+(to-from):perpendicular2():normalized()*(Spell.width/2+myHero.boundingRadius)
		local To = to+(to-from):normalized()*myHero.boundingRadius
		local ToL = To+(to-from):perpendicular():normalized()*(Spell.width/2+myHero.boundingRadius)
		local ToR = To+(to-from):perpendicular2():normalized()*(Spell.width/2+myHero.boundingRadius)
		local angleL = ToL:angleBetween(FromL, myHero)*math.pi/180
		local angleR = FromR:angleBetween(ToR, myHero)*math.pi/180
		local angleU = ToR:angleBetween(ToL, myHero)*math.pi/180
		local angleD = FromL:angleBetween(FromR, myHero)*math.pi/180
		if math.sin(angleL) <= 0 and math.sin(angleR) <= 0 and math.sin(angleU) <= 0 and math.sin(angleD) <= 0 then
			return true
		end
	elseif (Spell.type == "DelayCircle" or Spell.type == "PromptCircle") and GetDistance(spell.endPos, myHero) <= Spell.radius then
		return true
	end
	return false
end
function AutoShield:HitTimePredict(spell, Spell)
	if Spell.type == "DelayLine" then
	elseif Spell.type == "PromptLine" then
		return Spell.delay
	elseif Spell.type == "DelayCircle" then
		return Spell.delay+GetDistance(spell.endPos, spell.startPos)/Spell.speed
	elseif Spell.type == "PromptCircle" then
		return Spell.delay
	end
	return math.huge
end
function AutoShield:MakeObject(spell, Spell)
	if Spell.type == "DelayLine" then
		for i=1, #self.object+1 do
			if self.object[i] == nil then
				local startP = Vector(spell.startPos)
				local endP = Vector(spell.endPos)
				local trueEndPos = startP + ( endP - startP ):normalized() * Spell.range
				self.object[i] = {}
				self.object[i].owner = Spell.owner
				self.object[i].startPos = Vector(spell.startPos)
				self.object[i].endPos = startP + ( endP - startP ):normalized() * Spell.range --(math.sqrt((myHero.x - startP.x)^2 + (myHero.z - startP.z)^2)) -- (heropos:distance(spell.startPos)) *
				self.object[i].startTime = os.clock()+Spell.delay
				self.object[i].type = Spell.type
				self.object[i].speed = Spell.speed+100
				self.object[i].width = Spell.width
				self.object[i].range = Spell.range
				self.object[i].col = Spell.col
				DelayAction(function() self.object[i] = nil end, Spell.delay+GetDistance(trueEndPos, spell.startPos)/Spell.speed)
				return
			end
      
		end 
	elseif Spell.type == "PromptLine" then
		for i=1, #self.object+1 do
			if self.object[i] == nil then
				print("Maked")
				self.object[i] = {}
				self.object[i].owner = Spell.owner
				self.object[i].startPos = Vector(spell.startPos)
				self.object[i].endPos = Vector(spell.endPos)
				self.object[i].hitTime = os.clock()+Spell.delay
				self.object[i].type = Spell.type
				self.object[i].width = Spell.width
				self.object[i].col = Spell.col
				self.object[i].range = Spell.range
				DelayAction(function() self.object[i] = nil end, Spell.delay)
				return
			end
		end
	elseif Spell.type == "DelayCircle" then
		for i=1, #self.object+1 do
			if self.object[i] == nil then
				self.object[i] = {}
				self.object[i].owner = Spell.owner
				self.object[i].endPos = Vector(spell.endPos)
				self.object[i].hitTime = os.clock()+Spell.delay+GetDistance(spell.endPos, spell.startPos)/Spell.speed
				self.object[i].type = Spell.type
				self.object[i].radius = Spell.radius
				DelayAction(function() self.object[i] = nil end, Spell.delay+GetDistance(spell.endPos, spell.startPos)/Spell.speed)
				return
			end
		end
	elseif Spell.type == "PromptCircle" then
		for i=1, #self.object+1 do
			if self.object[i] == nil then
				self.object[i] = {}
				self.object[i].owner = Spell.owner
				self.object[i].endPos = Vector(spell.endPos)
				self.object[i].hitTime = os.clock()+Spell.delay
				self.object[i].type = Spell.type
				self.object[i].radius = Spell.radius
				DelayAction(function() self.object[i] = nil end, Spell.delay)
				return
			end
		end
	end
	--[[
	if Spell.type == "DelayLine" then
	
        --self.object[i] = {}
		--self.object[i].startPos = Vector(spell.startPos)
        --self.object[i].endPos = Vector(spell.endPos)
        --self.object[i].startTime = os.clock()+Spell.delay
        --self.object[i].type = Spell.type
        --self.object[i].speed = Spell.speed
        --self.object[i].width = Spell.width
        --DelayAction(function() self.object[i] = nil end, Spell.delay+GetDistance(spell.endPos, spell.startPos)/Spell.speed)

		_table= {unit = Spell.owner, name = Spell.name , startPos = Vector(spell.startPos), endPos = Vector(spell.endPos), startTime = os.clock()+Spell.delay, type = Spell.type, speed = Spell.speed, width = Spell.width, col = Spell.col }
		table.insert(self.object, _table)
		DelayAction(function() 
			for i, object in pairs(self.object) do
				if object.unit == unit.charName and object.name == spell.name then
					table.remove(self.object, i)
				end
			end
		end, Spell.delay+GetDistance(spell.endPos, spell.startPos)/Spell.speed)
		return
		
	elseif Spell.type == "PromptLine" then
	
		_table = {unit = spell.owner.charName, name = spell.name , startPos = Vector(spell.startPos), endPos = Vector(spell.endPos), hitTime = os.clock()+Spell.delay, type = Spell.type, width = Spell.width, col = Spell.col}
		table.insert(self.object, _table)
		DelayAction(function() 
			for i, object in pairs(self.object) do
				if object.unit == unit.charName and object.name == spell.name then
					table.remove(self.object, i)
				end
			end
		end, Spell.delay)
		return
		
	elseif Spell.type == "DelayCircle" then
	
        --self.object[i] = {}
        --self.object[i].endPos = Vector(spell.endPos)
        --self.object[i].hitTime = os.clock()+Spell.delay+GetDistance(spell.endPos, spell.startPos)/Spell.speed
        --self.object[i].type = Spell.type
        --self.object[i].radius = Spell.radius
        --DelayAction(function() self.object[i] = nil end, Spell.delay+GetDistance(spell.endPos, spell.startPos)/Spell.speed)
		
		_table= { unit = spell.owner.charName, name = spell.name , endPos = Vector(spell.endPos), hitTime = os.clock()+Spell.delay+GetDistance(spell.endPos, spell.startPos)/Spell.speed, type = Spell.type, radius = Spell.radius}
		table.insert(self.object, _table)
		DelayAction(function() 
			for i, object in pairs(self.object) do 
				if object.unit == unit.charName and object.name == spell.name then
					table.remove(self.object, i)
				end
			end
		end, Spell.delay+GetDistance(spell.endPos, spell.startPos)/Spell.speed)
        return
  elseif Spell.type == "PromptCircle" then
  
        --self.object[i] = {}
        --self.object[i].endPos = Vector(spell.endPos)
        --self.object[i].hitTime = os.clock()+Spell.delay
        --self.object[i].type = Spell.type
        --self.object[i].radius = Spell.radius
		
       -- DelayAction(function() self.object[i] = nil end, Spell.delay)
        --return
		_table = {unit = spell.owner.charName, name = spell.name , endPos = Vector(spell.endPos), hitTime = os.clock()+Spell.delay, type = Spell.type, radius = Spell.radius}
		table.insert(self.object, _table)
		DelayAction(function() 
			for i, object in pairs(self.object) do
				if object.unit == unit.charName and object.name == spell.name then
					table.remove(self.object, i)
				end
			end
		end, Spell.delay)
	end
	]]
end

function AutoShield:ObjectShield()
	for i, obj in ipairs(self.object) do
		if obj.type == "DelayLine" then
			self.enemyMinion:update()
			if obj.col == true and self:Collision(obj) then
				table.remove(self.object, i)
			end
			if self:MyCollision(obj) then
				self:CastE()
				break
			end
			local object = self:skillshotPosition(obj)
			if self:WillBeHitTick(obj) and GetDistance(object, myHero) < myHero.boundingRadius+self.buffer*(myHero.ms+obj.speed) then
				if self.Menu.Debug then
					print(myHero.boundingRadius+self.buffer*(myHero.ms+obj.speed) - GetDistance(object, myHero))
				end
				self:CastE()
				break
			end
		elseif self:WillBeHitTick(obj) and obj.hitTime-os.clock() < self.buffer+0.045 then
			if self.Menu.Debug then
				print(obj.hitTime-os.clock())
				print(self.buffer)
			end
			self:CastE()
			break
		end
	end
end
function AutoShield:MyCollision(object)
	self.enemyMinion:update()
	local width = object.width or object.radius or 0
	local objPos = self:skillshotPosition(object)
	if GetDistance(Vector(objPos), Vector(myHero)) < (myHero.boundingRadius + width)then
		return true
	end
	return false
end
function AutoShield:Collision(object)
	self.enemyMinion:update()
	local width = object.width or object.radius or 0
	local objPos = self:skillshotPosition(object)
	for index, unit in pairs(self.enemyMinion.objects) do
		if GetDistance(Vector(objPos), Vector(unit)) < (unit.boundingRadius/2 + width/2)then
			return true
		end
	end
	self.jungleMob:update()
	for index, unit in pairs(self.jungleMob.objects) do
		if GetDistance(Vector(objPos), Vector(unit)) < (unit.boundingRadius/2 + width/2)then
			return true
		end
	end
	self.otherMob:update()
	for index, unit in pairs(self.otherMob.objects) do
		if GetDistance(Vector(objPos), Vector(unit)) < (unit.boundingRadius/2 + width/2)then
			return true
		end
	end
	if GetDistance(Vector(objPos)) < (myHero.boundingRadius/2 + width/2)then
		return true
	end
	return false
end
function AutoShield:skillshotPosition(object, tickCount)
	if object.type == "DelayLine" then
		directionVector = (object.endPos - object.startPos):normalized()
		if GetDistance(object.startPos + (object.endPos - object.startPos) * ((os.clock() - object.startTime) / (object.range / object.speed)), object.endPos) < GetDistance(object.endPos, object.startPos) then
			return object.startPos + (object.endPos - object.startPos) * ((os.clock() - object.startTime) / (object.range / object.speed))
		else
			return object.startPos
		end
	else
		return object.endPos
	end
end
function AutoShield:WillBeHitTick(object)
	if object.type == "DelayLine" or object.type == "PromptLine" then
		local from = object.startPos
		local to = object.endPos
		local From = from+(from-to):normalized()*myHero.boundingRadius
		local FromL = From+(to-from):perpendicular():normalized()*(object.width/2+myHero.boundingRadius)
		local FromR = From+(to-from):perpendicular2():normalized()*(object.width/2+myHero.boundingRadius)
		local To = to+(to-from):normalized()*myHero.boundingRadius
		local ToL = To+(to-from):perpendicular():normalized()*(object.width/2+myHero.boundingRadius)
		local ToR = To+(to-from):perpendicular2():normalized()*(object.width/2+myHero.boundingRadius)
		
		--local WFromL = WorldToScreen(D3DXVECTOR3(FromL.x, FromL.y, FromL.z))
		--local WFromR = WorldToScreen(D3DXVECTOR3(FromR.x, FromR.y, FromR.z))
		--local WToL = WorldToScreen(D3DXVECTOR3(ToL.x, ToL.y, ToL.z))
		--local WToR = WorldToScreen(D3DXVECTOR3(ToR.x, ToR.y, ToR.z))
		
		--local poly = Polygon(Point(WFromL.x, WFromL.y),  Point(WToL.x, WToL.y), Point(WFromR.x, WFromR.y),   Point(WToR.x, WToR.y))
		
		local angleL = ToL:angleBetween(FromL, myHero)*math.pi/180
		local angleR = FromR:angleBetween(ToR, myHero)*math.pi/180
		local angleU = ToR:angleBetween(ToL, myHero)*math.pi/180
		local angleD = FromL:angleBetween(FromR, myHero)*math.pi/180
		local myHeroPos = WorldToScreen(D3DXVECTOR3(myHero.x, myHero.y, myHero.z))
		--if poly:contains(myHeroPos) then
		--	return true
		--end
		if math.sin(angleL) <= 0 and math.sin(angleR) <= 0 and math.sin(angleU) <= 0 and math.sin(angleD) <= 0 then
			return true
		end
    
	elseif (object.type == "DelayCircle" or object.type == "PromptCircle") and GetDistance(object.endPos, myHero) <= object.radius then
		return true
	end
	return false
end
function AutoShield:PromptShield(spell, Spell)
	if GetDistance(spell.endPos, myHero) <= Spell[i].radius then
		self:CastE()
	end
end
function AutoShield:CastE()

  if self:E_Ready() then
    CastSpell(_E)
  end
  
end
uniqueId2 = 0
class 'Point2' 
function Point2:__init(x, y)
	uniqueId2 = uniqueId2 + 1
	self.uniqueId2 = uniqueId2

	self.x = x
	self.y = y

	self.points = {self}
end

class("ScriptUpdate")
function ScriptUpdate:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
  self.LocalVersion = LocalVersion
  self.Host = Host
  self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
  self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
  self.SavePath = SavePath
  self.CallbackUpdate = CallbackUpdate
  self.CallbackNoUpdate = CallbackNoUpdate
  self.CallbackNewVersion = CallbackNewVersion
  self.CallbackError = CallbackError
  AddDrawCallback(function() self:OnDraw() end)
  self:CreateSocket(self.VersionPath)
  self.DownloadStatus = 'Connect to Server for VersionInfo'
  AddTickCallback(function() self:GetOnlineVersion() end)
end

function ScriptUpdate:print(str)
  print('<font color="#FFFFFF">'..os.clock()..': '..str)
end

function ScriptUpdate:OnDraw()

  if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
	DrawText3D('No Vayne No Gain',myHero.x,myHero.y,myHero.z+70, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
    DrawText3D('Download Status: '..(self.DownloadStatus or 'Unknown'),myHero.x,myHero.y,myHero.z+50, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
  end
  
end

function ScriptUpdate:CreateSocket(url)

  if not self.LuaSocket then
    self.LuaSocket = require("socket")
  else
    self.Socket:close()
    self.Socket = nil
    self.Size = nil
    self.RecvStarted = false
  end
  
  self.LuaSocket = require("socket")
  self.Socket = self.LuaSocket.tcp()
  self.Socket:settimeout(0, 'b')
  self.Socket:settimeout(99999999, 't')
  self.Socket:connect('sx-bol.eu', 80)
  self.Url = url
  self.Started = false
  self.LastPrint = ""
  self.File = ""
end

function ScriptUpdate:Base64Encode(data)

  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  
  return ((data:gsub('.', function(x)
  
    local r,b='',x:byte()
    
    for i=8,1,-1 do
      r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0')
    end
    
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
  
    if (#x < 6) then
      return ''
    end
    
    local c=0
    
    for i=1,6 do
      c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0)
    end
    
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
  
end

function ScriptUpdate:GetOnlineVersion()

  if self.GotScriptVersion then
    return
  end
  
  self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
  
  if self.Status == 'timeout' and not self.Started then
    self.Started = true
    self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
  end
  
  if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
    self.RecvStarted = true
    self.DownloadStatus = 'Downloading VersionInfo (0%)'
  end
  
  self.File = self.File .. (self.Receive or self.Snipped)
  
  if self.File:find('</s'..'ize>') then
  
    if not self.Size then
      self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
    end
    
    if self.File:find('<scr'..'ipt>') then
    
      local _,ScriptFind = self.File:find('<scr'..'ipt>')
      local ScriptEnd = self.File:find('</scr'..'ipt>')
      
      if ScriptEnd then
        ScriptEnd = ScriptEnd-1
      end
      
      local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
      
      self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
    end
    
  end
  
  if self.File:find('</scr'..'ipt>') then
    self.DownloadStatus = 'Downloading VersionInfo (100%)'
    
    local a,b = self.File:find('\r\n\r\n')
    
    self.File = self.File:sub(a,-1)
     self.NewFile = ''
    
    for line,content in ipairs(self.File:split('\n')) do
    
      if content:len() > 5 then
        self.NewFile = self.NewFile .. content
      end
      
    end
    
    local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
    local ContentEnd, _ = self.File:find('</sc'..'ript>')
    
    if not ContentStart or not ContentEnd then
    
      if self.CallbackError and type(self.CallbackError) == 'function' then
        self.CallbackError()
      end
      
    else
      self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart+1,ContentEnd-1)))
      self.OnlineVersion = tonumber(self.OnlineVersion)
      
      if self.OnlineVersion > self.LocalVersion then
      
        if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
          self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
        end
        
        self:CreateSocket(self.ScriptPath)
        self.DownloadStatus = 'Connect to Server for ScriptDownload'
        AddTickCallback(function() self:DownloadUpdate() end)
      else
        
        if self.CallbackNoUpdate then
          self.CallbackNoUpdate(self.LocalVersion)
        end
        
      end
      
    end
    
    self.GotScriptVersion = true
  end
  
end

function ScriptUpdate:DownloadUpdate()

  if self.GotScriptUpdate then
    return
  end
  
  self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
  
  if self.Status == 'timeout' and not self.Started then
    self.Started = true
    self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
  end
  
  if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
    self.RecvStarted = true
    self.DownloadStatus = 'Downloading Script (0%)'
  end
  
  self.File = self.File .. (self.Receive or self.Snipped)
  
  if self.File:find('</si'..'ze>') then
  
    if not self.Size then
      self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
    end
    
    if self.File:find('<scr'..'ipt>') then
    
      local _,ScriptFind = self.File:find('<scr'..'ipt>')
      local ScriptEnd = self.File:find('</scr'..'ipt>')
      
      if ScriptEnd then
        ScriptEnd = ScriptEnd-1
      end
      
      local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
      
      self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
    end
    
  end
  
  if self.File:find('</scr'..'ipt>') then
    self.DownloadStatus = 'Downloading Script (100%)'
    
    local a,b = self.File:find('\r\n\r\n')
    
    self.File = self.File:sub(a,-1)
    self.NewFile = ''
    
    for line,content in ipairs(self.File:split('\n')) do
    
      if content:len() > 5 then
        self.NewFile = self.NewFile .. content
      end
      
    end
    
    local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
    local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
    
    if not ContentStart or not ContentEnd then
      
      if self.CallbackError and type(self.CallbackError) == 'function' then
        self.CallbackError()
      end
      
    else
      
      local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
      local newf = newf:gsub('\r','')
      
      if newf:len() ~= self.Size then
      
        if self.CallbackError and type(self.CallbackError) == 'function' then
          self.CallbackError()
        end
        
        return
      end
      
      local newf = Base64Decode(newf)
      
      if type(load(newf)) ~= 'function' then
      
        if self.CallbackError and type(self.CallbackError) == 'function' then
          self.CallbackError()
        end
        
      else
      
        local f = io.open(self.SavePath,"w+b")
        
        f:write(newf)
        f:close()
        
        if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
          self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
        end
        
      end
      
    end
    
    self.GotScriptUpdate = true
  end
  
end

class('Awareness')
function Awareness:__init()
	self.SpellsData = {}
	self.SSpells = {
			{CName="Flash", Name="summonerflash", Color={255, 255, 255, 0} },
			{CName="Ghost", Name="summonerhaste", Color={255, 0, 0, 255} },
			{CName="Ignite", Name="summonerdot", Color={255, 255, 0, 0 }},
			{CName="Barrier", Name="summonerbarrier", Color={255, 209, 143, 0}},
			{CName="Smite", Name="summonersmite", Color={255, 209, 143, 0}},
			{CName="Exhaust", Name="summonerexhaust", Color={255, 209, 143, 0}},
			{CName="Heal", Name="summonerheal", Color={255, 0, 255, 0}},
			{CName="Teleport", Name="summonerteleport", Color={255, 192, 0, 209}},
			{CName="Cleanse", Name="summonerboost", Color={255, 255, 138, 181}},
			{CName="Clarity", Name="summonermana", Color={255, 0, 110, 255}},
			{CName="Clairvoyance", Name="summonerclairvoyance", Color={255, 0, 110, 255}},
			{CName="Revive", Name="summonerrevive", Color={255, 0, 255, 0}},
			{CName="Garrison", Name="summonerodingarrison", Color={255, 0, 110, 255}},
			{CName="The Rest", Name="TheRest", Color={255, 255, 255, 255}},
	}
	self.TrackSpells = {_Q, _W, _E, _R}
	self.TickLimit = 0
	self.wards = {}
	self.visions= {}
	
	self.Ignite		= {slot = nil, Range = 600, IsReady = function() return (self.Ignite.slot ~= nil and myHero:CanUseSpell(self.Ignite.slot) == READY) end, Damage = function(target) return getDmg("IGNITE", target, myHero)*0.95 end}
	self.Barrier	= {slot = nil, Range = 0, IsReady = function() return (self.Barrier.slot ~= nil and myHero:CanUseSpell(self.Barrier.slot) == READY) end,}
	self.Smite		= {slot = nil, Range = 700, IsReady = function() return (self.Smite.slot ~= nil and myHero:CanUseSpell(self.Smite.slot) == READY) end, Damage = 0 }
	
	self.Ignite.slot = FindSummonerSlot("summonerdot")
	self.Barrier.slot = FindSummonerSlot("summonerbarrier")
	self.Smite.slot = FindSummonerSlot("summonersmite")
	
	self.minionTable =  minionManager(MINION_ENEMY, self.Smite.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, self.Smite.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	self.STS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 730, DAMAGE_PHYSICAL, false)
	
	self:LoadToMenu()
end

function Awareness:LoadToMenu()
	self.Config = scriptConfig("ezAwareness", "ezAwareness")
		self.Config:addSubMenu("CoolDownChecker", "CoolDownChecker")
			self.Config.CoolDownChecker:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			self.Config.CoolDownChecker:addParam("EnemyOn", "Enemy On", SCRIPT_PARAM_ONOFF, true)
			self.Config.CoolDownChecker:addParam("AllyOn", "Ally On", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu("WardTracker", "WardTracker")
			self.Config.WardTracker:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			
		
		self.Config:addSubMenu("SummonerHelper", "SummonerHelper")
			self.Config.SummonerHelper:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
				if self.Ignite.slot ~= nil then
					self.Config.SummonerHelper:addSubMenu("Ignite", "Ignite")
						self.Config.SummonerHelper.Ignite:addParam("IgniteOn", "Ignite On", SCRIPT_PARAM_ONOFF, true)
				end
				if self.Barrier.slot ~= nil then
					self.Config.SummonerHelper:addSubMenu("Barrier", "Barrier")
					self.Config.SummonerHelper.Barrier:addParam("BarrierOn", "Barrier On", SCRIPT_PARAM_ONOFF, true)
					self.Config.SummonerHelper.Barrier:addParam("health", "health", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
				end
				if self.Smite.slot ~= nil then
					self.Config.SummonerHelper:addSubMenu("smite", "smite")
						self.Config.SummonerHelper.smite:addParam("toggleuse", "Toggle Use", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("N"))
						self.Config.SummonerHelper.smite:addParam("autouse", "Auto Use", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
						self.Config.SummonerHelper.smite:addParam("hotkeycc", "Object: CC HotKey", SCRIPT_PARAM_ONKEYDOWN, false, 32)
						self.Config.SummonerHelper.smite:addParam("smite0", "Object: Champion CC", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite00", "Object: Champion LastHit", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
						self.Config.SummonerHelper.smite:addParam("smite1", "Baron", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite2", "Dragon", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite3", "Crab(Baron/Dragon)", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
						self.Config.SummonerHelper.smite:addParam("smite4", "Full Blue Camp", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite5", "Red", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite6", "Blue", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite7", "Gromp", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite8", "Wolf", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite9", "Beak", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite10", "Krug", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
						self.Config.SummonerHelper.smite:addParam("smite11", "Full Red Camp", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite12", "Red", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite13", "Blue", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite14", "Gromp", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite15", "Wolf", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite16", "Beak", SCRIPT_PARAM_ONOFF, true)
						self.Config.SummonerHelper.smite:addParam("smite17", "Krug", SCRIPT_PARAM_ONOFF, true)
				end
			
	AddTickCallback(function() self:Tick() end)
	AddDrawCallback(function() self:Draw() end)
	AddCreateObjCallback(function(obj) self:OnCreatWard(obj) end)
	AddDeleteObjCallback(function(obj) self:OnDeleteWard(obj) end)
end

function Awareness:Tick()
	self:CoolDownTick()
	if self.Config.SummonerHelper.On then self:SummonerHelper() end
	if self.Config.SummonerHelper.On and self.Smite.slot ~= nil then
		if myHero.level >14 then self.Smite.Damage = 800 + ((myHero.level-14)*50) end
		if myHero.level > 9 then self.Smite.Damage = 600 + ((myHero.level-9)*40) end
		if myHero.level > 5 then self.Smite.Damage = 480 + ((myHero.level-5)*30) end
		if myHero.level > 0 then self.Smite.Damage = 370 + ((myHero.level)*20) end
	end
	
	if self.Smite.slot ~= nil then
		self.STS:update()
		self.STarget = self.STS.target
	end
end

function Awareness:Draw()
	if self.Config.CoolDownChecker.On then self:CoolDownDraw() end
	if self.Config.WardTracker.On then self:WardTrackerDraw() end
	if self.Smite.slot ~= nil and (self.Config.SummonerHelper.smite.toggleuse or self.Config.SummonerHelper.smite.autouse) then
		DrawCircle(player.x, player.y, player.z, self.Smite.Range, Colors.Green)
	end
end

function Awareness:SummonerHelper()
	if self.Ignite.slot ~= nil and self.Config.SummonerHelper.Ignite.IgniteOn then
		for index, hero in ipairs(GetEnemyHeroes()) do
			if GetDistance(hero) < self.Ignite.Range and self.Ignite.Damage(hero) > hero.health and self.Ignite.IsReady() then
				CastSpell(self.Ignite.slot, hero)
			end
		end
	end
	
	if self.Smite.slot ~= nil and self.Config.SummonerHelper.smite.hotkeycc and self.Config.SummonerHelper.smite.smite0 and ValidTarget(self.STarget, 710) and self.Smite.IsReady() then
		self:CastSmite(self.STarget)
	end
	
	if self.Barrier.slot ~= nil and self.Config.SummonerHelper.Barrier.BarrierOn then
		if (myHero.health / myHero.maxHealth * 100) < self.Config.SummonerHelper.Barrier.health and self.Barrier.IsReady() then
			CastSpell(self.Barrier.slot)
		end
	end
		
	if self.Smite.slot ~= nil and (self.Config.SummonerHelper.smite.toggleuse or self.Config.SummonerHelper.smite.autouse) then
		self.jungleTable:update()
		for i, junglemob in pairs(self.jungleTable.objects) do				
			if junglemob == nil then
				return
			end			
			if ValidTarget(junglemob, 720) then
				if self.Config.SummonerHelper.smite.smite1 and junglemob.name=="SRU_Baron12.1.1" and junglemob.health < self.Smite.Damage then
					self:CastSmite(junglemob)
				end

				if self.Config.SummonerHelper.smite.smite2 and junglemob.name=="SRU_Dragon6.1.1" and junglemob.health < self.Smite.Damage then					
					self:CastSmite(junglemob)
				end

				if self.Config.SummonerHelper.smite.smite3 and (junglemob.name=="Sru_Crab15.1.1" or junglemob.name=="Sru_Crab16.1.1") and junglemob.health < self.Smite.Damage then
					self:CastSmite(junglemob)
				end

				if self.Config.SummonerHelper.smite.smite4 then					
					if self.Config.SummonerHelper.smite.smite5 and junglemob.name=="SRU_Red4.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end
					
					if self.Config.SummonerHelper.smite.smite6 and junglemob.name=="SRU_Blue1.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite7 and junglemob.name=="SRU_Gromp13.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite8 and junglemob.name=="SRU_Murkwolf2.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite9 and junglemob.name=="SRU_Razorbeak3.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite10 and junglemob.name=="SRU_Krug5.1.2" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end
				end

				if self.Config.SummonerHelper.smite.smite11 then
					if self.Config.SummonerHelper.smite.smite12 and junglemob.name=="SRU_Red10.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite13 and junglemob.name=="SRU_Blue7.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite14 and junglemob.name=="SRU_Gromp14.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite15 and junglemob.name=="SRU_Murkwolf8.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite16 and junglemob.name=="SRU_Razorbeak9.1.1" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end

					if self.Config.SummonerHelper.smite.smite17 and junglemob.name=="SRU_Krug11.1.2" and junglemob.health < self.Smite.Damage then				
						self:CastSmite(junglemob)
					end
				end
			end
		end
	end
end

function Awareness:CastSmite(target)
	if target ~= nil and GetDistance(target) < self.Smite.Range then
		CastSpell(self.Smite.slot, target)
	end
end

function Awareness:CoolDownTick()
	if os.clock() - self.TickLimit > 0.3 then
		self.TickLimit = os.clock()
		for i=1, heroManager.iCount, 1 do
			local hero = heroManager:getHero(i)
			if ValidTarget(hero, math.huge, false) or ValidTarget(hero) then
				--[[	Update the current cooldowns]]
				hero = heroManager:getHero(i)
				for _, spell in pairs(self.TrackSpells) do
					if self.SpellsData[i] == nil then
						self.SpellsData[i] = {}
					end
					if self.SpellsData[i][spell] == nil then
						self.SpellsData[i][spell] = {currentCd=0, maxCd = 0, level=0}
					end
					--[[	Get the maximum cooldowns to make the progress  bar]]
					local thespell = hero:GetSpellData(spell)
					local currentcd
					if thespell and thespell.currentCd then
						currentcd = thespell.currentCd
					end
					if currentcd and thespell and thespell.currentCd then
						self.SpellsData[i][spell] = {
							currentCd = math.floor(currentcd),
							maxCd = math.floor(currentcd) > self.SpellsData[i][spell].maxCd and math.floor(currentcd) or self.SpellsData[i][spell].maxCd,
							level = thespell.level
						}
					end
				end
			end
		end
	end
	self.FirstTick = true
end


function Awareness:CoolDownDraw()
	if (self.Config.CoolDownChecker.EnemyOn or self.Config.CoolDownChecker.AllyOn) and self.FirstTick then
		for i=1, heroManager.iCount, 1 do
			local hero = heroManager:getHero(i)
			if ((ValidTarget(hero, math.huge,false)  and (self.Config.CoolDownChecker.AllyOn)) or (ValidTarget(hero) and (self.Config.CoolDownChecker.EnemyOn))) and not hero.isMe then
				local barpos = GetHPBarPos(hero)
				if OnScreen(barpos.x, barpos.y) and (self.SpellsData[i] ~= nil) then
					local pos = Vector(barpos.x, barpos.y, 0)
					local CDcolor = ARGB(255, 214, 114, 0)
					local Readycolor = ARGB(255, 54, 214, 0)
					local Textcolor = ARGB (255, 255, 255, 255)
					local Backgroundcolor = ARGB(255, 128, 128, 128)
					local width = 20
					local height = 5
					local sep = 2
					--[[First 4 spells]]
					pos.y =  pos.y + 0
					for j, Spells in ipairs (self.TrackSpells) do
						local currentcd = self.SpellsData[i][Spells].currentCd
						local maxcd = self.SpellsData[i][Spells].maxCd
						local level = self.SpellsData[i][Spells].level
						
						if j > 4 then
							CDcolor = ARGB(255, 255, 255, 255)
							--[[
							for _, spell in ipairs(SSpells) do
								if (hero:GetSpellData(j == 5 and SUMMONER_1 or SUMMONER_2).name == spell.Name) then
									CDcolor = ARGB(255, 214, 114, 0)
								end
							end
							]]
							Readycolor = CDcolor
						end
						
						self:DrawRectangleAL(pos.x-1, pos.y-1, width + sep , height+4, Backgroundcolor)
					
						if level == 0 then
							self:DrawRectangleAL(pos.x, pos.y, width, height, 0xBBFFFFFF)
						else
							if (currentcd ~= 0) then
								self:DrawRectangleAL(pos.x, pos.y, width - math.floor(width * currentcd) / maxcd, height, CDcolor)
							else
								self:DrawRectangleAL(pos.x, pos.y, width, height, Readycolor)
							end
						end
					
						if (currentcd ~= 0) and (currentcd < 100) then
							DrawText(tostring(currentcd),13, pos.x+6, pos.y+4, ARGB(255, 0, 0, 0))
							DrawText(tostring(currentcd),13, pos.x+8, pos.y+6, ARGB(255, 0, 0, 0))
							DrawText(tostring(currentcd),13, pos.x+7, pos.y+5, Textcolor)
						--[[
						elseif IsKeyDown(16) then
							DrawText(tostring(level),13, pos.x+6, pos.y+4, ARGB(255, 0, 0, 0))
							DrawText(tostring(level),13, pos.x+8, pos.y+6, ARGB(255, 0, 0, 0))
							DrawText(tostring(level),13, pos.x+7, pos.y+5, Textcolor)
						]]
						end
						pos.x = pos.x + width + sep
						if j == 4 then break end
					end
					pos.x = barpos.x + 25*5+3 + 2*4
					pos.y = barpos.y - 8
					--[[Last 2 spells]]
					--[[
					for j, Spells in ipairs (TrackSpells) do
						local currentcd = self.SpellsData[i][Spells].currentCd
						local maxcd = self.SpellsData[i][Spells].maxCd
						local width2 = 202
						if j > 4 then
							CDcolor = ARGB(255, 255, 255, 255)
							for _, spell in ipairs(SSpells) do
								if  (hero:GetSpellData(j == 5 and SUMMONER_1 or SUMMONER_2).name == spell.Name) then
									CDcolor = ARGB(255, 214, 114, 0)
								end
							end
							self:DrawRectangleAL(pos.x, pos.y,width2+2,11,Backgroundcolor)
							if currentcd ~= 0 then
								self:DrawRectangleAL(pos.x+1, pos.y+1, width2 - width2 * currentcd / maxcd,9,CDcolor)
							else
								self:DrawRectangleAL(pos.x+1, pos.y+1, width2, 9, CDcolor)
							end
							if (currentcd ~= 0) and (currentcd < 100) then
								DrawText(tostring(currentcd),13, pos.x-1, pos.y-1, ARGB(255, 0, 0, 0))
								DrawText(tostring(currentcd),13, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
								DrawText(tostring(currentcd),13, pos.x, pos.y, Textcolor)
							end
							Readycolor = CDcolor
							pos.y = pos.y - 12
						end
					end
					]]
				end
			end
		end
	end
end

function Awareness:DrawRectangleAL(x, y, w, h, color)
	local Points = {}
	Points[1] = D3DXVECTOR2(math.floor(x), math.floor(y))
	Points[2] = D3DXVECTOR2(math.floor(x + w), math.floor(y))
	DrawLines2(Points, math.floor(h), color)
end


function Awareness:OnCreatWard(obj)
	if obj.name:lower():find("sight") and obj.maxMana > 0 then
		local ward = {x = obj.x, y = obj.y, z = obj.z, mana = obj.mana, time = GetGameTimer(), type = "SightWard"}
		table.insert(self.wards, ward);
	end
end

function Awareness:OnDeleteWard(obj)
	for index, ward in pairs(self.wards) do
		if (obj.x == ward.x) and (obj.x == ward.x) and (obj.x == ward.x) then
			table.remove(self.wards, index)
		end
	end
end

function Awareness:WardTrackerDraw()
	for index, ward in pairs(self.wards) do
		currentMana = math.floor(ward.mana - (GetGameTimer() - ward.time))
		if (currentMana <= 0) then
			table.remove(self.wards, index)
		else
			--DrawCircle3D(myHero.x, myHero.y, myHero.z, 10, 3, RGBA(0, 255, 0, 254), 100)
			DrawCircle3D(ward.x, ward.y, ward.z, 100,5, RGBA(127, 255, 0, 255), 20)
			DrawText3D(tostring(currentMana), ward.x, ward.y, ward.z, 20, RGBA(127, 255, 0, 255), true)
		end
	end
	
	for index, ward in pairs(self.visions) do
		currentMana = math.floor(ward.mana - (GetGameTimer() - ward.time))
		if (currentMana <= 0) then
			table.remove(self.wards, index)
		else
			DrawCircle3D(ward.x, ward.y, ward.z, 100,5, Colors.Red, 20)
			DrawText3D(tostring(currentMana), ward.x, ward.y, ward.z, 20,5, Colors.Red, true)
		end
	end
end