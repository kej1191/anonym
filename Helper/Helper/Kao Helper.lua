
function ScriptMsg(msg)
  print("<font color=\"#66CCFF\"><b>Kao Helper:</b></font> <font color=\"#FFFFFF\">"..msg.."</font>")
end


local Author = "KaoKaoNi"
local Version = "Beta_1.1"

local Statu = {}

local enemycd = {}
local allycd = {}

local SpellId = {_Q, _W, _E, _R}
local _SpellId = {"Q", "W", "E", "R"}


local TrackSpells = {_Q, _W, _E, _R}
local SpellsData = {}
local TickLimit = 0
local FirstTick = false

local missing_since = {}
local missing_time = {}
local traveled_distance = 0

local player = myHero

if VIP_USER then
 	AdvancedCallback:bind('OnApplyBuff', function(source, unit, buff) OnApplyBuff(source, unit, buff) end)
	AdvancedCallback:bind('OnUpdateBuff', function(unit, buff, stack) OnUpdateBuff(unit, buff, stack) end)
	AdvancedCallback:bind('OnRemoveBuff', function(unit, buff) OnRemoveBuff(unit, buff) end)
end

local _miniMapRatio = nil
local function GetMinimapRatio()
    if _miniMapRatio then return _miniMapRatio end
    local windowWidth, windowHeight = 1
    local gameSettings = GetGameSettings()
    if gameSettings and gameSettings.General and gameSettings.General.Width and gameSettings.General.Height then
        windowWidth, windowHeight = gameSettings.General.Width, gameSettings.General.Height
        local hudSettings = ReadIni(GAME_PATH .. "DATA\\menu\\hud\\hud" .. windowWidth .. "x" .. windowHeight .. ".ini")
        if hudSettings and hudSettings.Globals and hudSettings.Globals.MinimapScale then
            _miniMapRatio = (windowHeight / 1080) * hudSettings.Globals.MinimapScale
        else
            _miniMapRatio = (windowHeight / 1080)
        end
    end
end


function OnLoad()
	OnLoadMenu()
	
	for i, enemy in ipairs(GetEnemyHeroes()) do
        missing_since[i] = -1
    end
end

function OnTick()
	if Config.MissingTimer.On then MissingTimer() end
	if Config.CoolDownChecker.On and Config.CoolDownChecker.Type == 2 then CoolDownChecker_Line_Tick() end
end

function OnDraw()
	if Config.CoolDownChecker.On then 
		if Config.CoolDownChecker.Type == 1 then
			CoolDownChecker_Text()
		elseif Config.CoolDownChecker.Type == 2 then
			CoolDownChecker_Line()
		end
	end
	if Config._3DRader.On then _3DRader() end
	if Config.MissingTimer.On then MissingTimerDraw() end
end

function OnLoadMenu()
	Config = scriptConfig("Free Awarencess", "Free Awarencess")
		
		Config:addSubMenu("CoolDownChecker", "CoolDownChecker")
			Config.CoolDownChecker:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			Config.CoolDownChecker:addParam("Type", "Type", SCRIPT_PARAM_LIST, 1, {"Text", "Line"})
			Config.CoolDownChecker:addParam("EnemyOn", "Enemy On", SCRIPT_PARAM_ONOFF, true)
			Config.CoolDownChecker:addParam("AllyOn", "Ally On", SCRIPT_PARAM_ONOFF, true)
		
		Config:addSubMenu("3DRader", "_3DRader")
			Config._3DRader:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("EnemyOn", "Enemy On", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("AllyOn", "Ally On", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("LineType", "Line Type", SCRIPT_PARAM_LIST, 2, {"Static", "Dynamic"})
			Config._3DRader:addParam("MinRange", "MinRange", SCRIPT_PARAM_SLICE, 1500, 1000, 3000, 0)
		
		Config:addSubMenu("MissingTimer", "MissingTimer")
			Config.MissingTimer:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			Config.MissingTimer:addParam("ShowTimer", "Show Missing Timer", SCRIPT_PARAM_ONOFF, true)
			Config.MissingTimer:addParam("DrawCircle", "Show circle on minimap" , SCRIPT_PARAM_ONOFF, true)
			Config.MissingTimer:addParam("MinRadius", "Alert after range", SCRIPT_PARAM_SLICE, 2000, 1500, 3000, 0)
			Config.MissingTimer:addParam("MaxRadius", "Max circle radius", SCRIPT_PARAM_SLICE, 5000, 3000, 9000, 0)
			
		Config:addParam("INFO", "", SCRIPT_PARAM_INFO, "")
		Config:addParam("Author", "Author", SCRIPT_PARAM_INFO, Author)
		Config:addParam("Version", "Version", SCRIPT_PARAM_INFO, Version)
			
end


---------------------------------
---------CoolDownChecker---------
---------------------------------


function CoolDownChecker_Text()
	if Config.CoolDownChecker.EnemyOn then
		for i, Enemy in ipairs(GetEnemyHeroes()) do
			for i, Spell in ipairs(SpellId) do
				local startPos = GetHPBarPos(Enemy)
				if not Enemy.dead and ValidTarget(Enemy) then
					if Enemy:GetSpellData(SpellId[i]).currentCd == 0 then
						DrawText("[".._SpellId[i].."]",18, startPos.x+18*i, startPos.y, 0xFFFFFF00)
					else
						DrawText("["..math.ceil(Enemy:GetSpellData(SpellId[i]).currentCd).."]",18, startPos.x+18*i, startPos.y, 0xFFFF0000)
					end
				end
			end
		end
	end
	if Config.CoolDownChecker.AllyOn then
		for i, Ally in ipairs(GetAllyHeroes()) do
			for i, Spell in ipairs(SpellId) do
				local startPos = GetHPBarPos(Ally)
				if not Ally.dead then
					if Ally:GetSpellData(SpellId[i]).currentCd == 0 then
						DrawText("[".._SpellId[i].."]",18, startPos.x, startPos.y+18*i, 0xFFFFFF00)
					else
						DrawText("["..math.ceil(Ally:GetSpellData(SpellId[i])).currentCd.."]",18, startPos.x, startPos.y+18*i, 0xFFFF0000)
					end
				end
			end
		end
	end
end

function CoolDownChecker_Line_Tick()
	if os.clock() - TickLimit > 0.3 then
		TickLimit = os.clock()
		for i=1, heroManager.iCount, 1 do
			local hero = heroManager:getHero(i)
			if ValidTarget(hero, math.huge, false) or ValidTarget(hero) then
				--[[	Update the current cooldowns]]
				hero = heroManager:getHero(i)
				for _, spell in pairs(TrackSpells) do
					if SpellsData[i] == nil then
						SpellsData[i] = {}
					end
					if SpellsData[i][spell] == nil then
						SpellsData[i][spell] = {currentCd=0, maxCd = 0, level=0}
					end
					--[[	Get the maximum cooldowns to make the progress  bar]]
					local thespell = hero:GetSpellData(spell)
					local currentcd
					if thespell and thespell.currentCd then
						currentcd = thespell.currentCd
					end
					if currentcd and thespell and thespell.currentCd then
						SpellsData[i][spell] = {
							currentCd = math.floor(currentcd),
							maxCd = math.floor(currentcd) > SpellsData[i][spell].maxCd and math.floor(currentcd) or SpellsData[i][spell].maxCd,
							level = thespell.level
						}
					end
				end
			end
		end
	end
	FirstTick = true
end


function CoolDownChecker_Line()
	if (Config.CoolDownChecker.EnemyOn or Config.CoolDownChecker.AllyOn) and FirstTick then
		for i=1, heroManager.iCount, 1 do
			local hero = heroManager:getHero(i)
			if ((ValidTarget(hero, math.huge,false)  and (Config.CoolDownChecker.AllyOn)) or (ValidTarget(hero) and (Config.CoolDownChecker.EnemyOn))) and not hero.isMe then
				local barpos = GetHPBarPos(hero)
				if OnScreen(barpos.x, barpos.y) and (SpellsData[i] ~= nil) then
					local pos = Vector(barpos.x, barpos.y, 0)
					local CDcolor = TARGB{255, 214, 114, 0}
					local Readycolor = TARGB{255, 54, 214, 0}
					local Textcolor = TARGB{255, 255, 255, 255}
					local Backgroundcolor = TARGB{255, 128, 128, 128}
					local width = 20
					local height = 5
					local sep = 2
					--[[First 4 spells]]
					pos.y =  pos.y + 0
					for j, Spells in ipairs (TrackSpells) do
						local currentcd = SpellsData[i][Spells].currentCd
						local maxcd = SpellsData[i][Spells].maxCd
						local level = SpellsData[i][Spells].level
						--[[
						if j > 4 then
							CDcolor = TARGB(Menu.Colors.SSpells["TheRest"][1], Menu.Colors.SSpells["TheRest"][2], Menu.Colors.SSpells["TheRest"][3], Menu.Colors.SSpells["TheRest"][4])
							for _, spell in ipairs(SSpells) do
								if (Menu.Colors.SSpells[spell.Name] ~= nil) and (hero:GetSpellData(j == 5 and SUMMONER_1 or SUMMONER_2).name == spell.Name) then
									CDcolor = TARGB(Menu.Colors.SSpells[spell.Name][1], Menu.Colors.SSpells[spell.Name][2], Menu.Colors.SSpells[spell.Name][3], Menu.Colors.SSpells[spell.Name][4])
								end
							end
							Readycolor = CDcolor
						else
							CDcolor = TARGB(Menu.Colors.cdcolor[1], Menu.Colors.cdcolor[2],Menu.Colors.cdcolor[3],Menu.Colors.cdcolor[4])
							Readycolor = TARGB(Menu.Colors.readycolor[1],Menu.Colors.readycolor[2],Menu.Colors.readycolor[3],Menu.Colors.readycolor[4])
						end
						]]
						DrawRectangleAL(pos.x-1, pos.y-1, width + sep , height+4, Backgroundcolor)
					
						if (currentcd ~= 0) then
							DrawRectangleAL(pos.x, pos.y, width - math.floor(width * currentcd) / maxcd, height, CDcolor)
						else
							DrawRectangleAL(pos.x, pos.y, width, height, Readycolor)
						end
					
						if (currentcd ~= 0) and (currentcd < 100) then
							DrawText(tostring(currentcd),13, pos.x+6, pos.y+4, TARGB(255, 0, 0, 0))
							DrawText(tostring(currentcd),13, pos.x+8, pos.y+6, TARGB(255, 0, 0, 0))
							DrawText(tostring(currentcd),13, pos.x+7, pos.y+5, Textcolor)
						elseif IsKeyDown(16) then
							DrawText(tostring(level),13, pos.x+6, pos.y+4, TARGB(255, 0, 0, 0))
							DrawText(tostring(level),13, pos.x+8, pos.y+6, TARGB(255, 0, 0, 0))
							DrawText(tostring(level),13, pos.x+7, pos.y+5, Textcolor)
						end
							pos.x = pos.x + width + sep
						if j == 4 then break end
					end
					pos.x = barpos.x + 25*5+3 + 2*4
					pos.y = barpos.y - 8
					--[[Last 2 spells]]
					for j, Spells in ipairs (TrackSpells) do
						local currentcd = SpellsData[i][Spells].currentCd
						local maxcd = SpellsData[i][Spells].maxCd
						local width2 = 202
						if j > 4 then
							--[[
							CDcolor = TARGB(Menu.Colors.SSpells["TheRest"][1], Menu.Colors.SSpells["TheRest"][2], Menu.Colors.SSpells["TheRest"][3], Menu.Colors.SSpells["TheRest"][4])
							for _, spell in ipairs(SSpells) do
								if (Menu.Colors.SSpells[spell.Name] ~= nil) and (hero:GetSpellData(j == 5 and SUMMONER_1 or SUMMONER_2).name == spell.Name) then
									CDcolor = TARGB(Menu.Colors.SSpells[spell.Name][1], Menu.Colors.SSpells[spell.Name][2], Menu.Colors.SSpells[spell.Name][3], Menu.Colors.SSpells[spell.Name][4])
								end
							end
							]]
							DrawRectangleAL(pos.x, pos.y,width2+2,11,Backgroundcolor)
							if currentcd ~= 0 then
								DrawRectangleAL(pos.x+1, pos.y+1, width2 - width2 * currentcd / maxcd,9,CDcolor)
							else
								DrawRectangleAL(pos.x+1, pos.y+1, width2, 9, CDcolor)
							end
							if (currentcd ~= 0) and (currentcd < 100) then
								DrawText(tostring(currentcd),13, pos.x-1, pos.y-1, TARGB(255, 0, 0, 0))
								DrawText(tostring(currentcd),13, pos.x+1, pos.y+1, TARGB(255, 0, 0, 0))
								DrawText(tostring(currentcd),13, pos.x, pos.y, Textcolor)
							end
							Readycolor = CDcolor
							pos.y = pos.y - 12
						end
					end
				end
			end
		end
	end
end

function DrawRectangleAL(x, y, w, h, color)
	local Points = {}
	Points[1] = D3DXVECTOR2(math.floor(x), math.floor(y))
	Points[2] = D3DXVECTOR2(math.floor(x + w), math.floor(y))
	DrawLines2(Points, math.floor(h), color)
end

---------------------------------
---------3D Rader----------------
---------------------------------

function _3DRader()
	if Config._3DRader.AllyOn then
		for i, Ally in ipairs(GetAllyHeroes()) do
			if GetDistance(Ally, player) >= Config._3DRader.MinRange and not Ally.dead and ValidTarget(Ally) then
				DrawLine3D(myHero.x, myHero.y, myHero.z, Ally.x, Ally.y, Ally.z, LineType(Ally), 0x0000ffff)
			end
		end
	end
	if Config._3DRader.EnemyOn then
		for i, Enemy in ipairs(GetEnemyHeroes()) do
			if GetDistance(Enemy, player) >= Config._3DRader.MinRange and not Enemy.dead and ValidTarget(Enemy) then
				DrawLine3D(myHero.x, myHero.y, myHero.z, Enemy.x, Enemy.y, Enemy.z, LineType(Enemy), 0xffff0000)
			end
		end
	end
end

function LineType(unit)
	if Config._3DRader.LineType == 1 then
		return 8
	else
		local Distance = GetDistance(unit, player)
		return (16000/Distance)
	end
end

---------------------------------
---------Missing Timer-----------
---------------------------------

function MissingTimer()
	for i, enemy in ipairs(GetEnemyHeroes()) do
        if enemy.visible == false and enemy.dead == false then
            if missing_since[i] ~= -1 then
                if missing_since[i] == nil then
                    missing_since[i] = GetTickCount()
                end
                missing_time[i] = (GetTickCount() - missing_since[i]) / 1000
            end
        else
            missing_since[i] = nil
            missing_time[i] = 0
        end
    end
end

function MissingTimerDraw()
    for i, enemy in ipairs(GetEnemyHeroes()) do
        if enemy.visible == false and enemy.dead == false and missing_since[i] ~= -1 then
            
            traveled_distance = enemy.ms * missing_time[i]
            
            if traveled_distance > Config.MissingTimer.MinRadius then
                if traveled_distance < Config.MissingTimer.MaxRadius then
                    
                    if Config.MissingTimer.DrawCircle then
                        DrawCircleMinimap(enemy.x, enemy.y, enemy.z, traveled_distance, 2, 0xFFFF0000)
                    end
                    
                    if Config.MissingTimer.ShowTimer then
                        DrawText(tostring(math.floor(missing_time[i])), 20, GetMinimapX(enemy.x)-6*GetMinimapRatio(), GetMinimapY(enemy.z)-6*GetMinimapRatio(), ARGB(255, 255, 255, 0))
                    end
                
                else
                    
                    if Config.MissingTimer.drawCircle then
                        DrawCircleMinimap(enemy.x, enemy.y, enemy.z, Config.MissingTimer.MaxRadius, 2, 4294902015)
                    end
                    
                    if Config.MissingTimer.ShowTimer then
                        DrawText(tostring(math.floor(missing_time[i])), 20, GetMinimapX(enemy.x)-6*GetMinimapRatio(), GetMinimapY(enemy.z)-6*GetMinimapRatio(), ARGB(255, 255, 0, 0))
                    end
                end
            end
        end
    end
end


---------------------------------
---------unit statu--------------
---------------------------------

function OnProcessSpell(unit, spell)
	if unit and spell then
	end
end

function OnApplyBuff(source, unit, buff)
	if unit then
	end
end

function OnUpdateBuff(unit, buff, stack)
	if unit then
	end
end

function OnRemoveBuff(unit, buff)
	if unit then
	end
end

---------------------------------
---------Athor-------------------
---------------------------------

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

function TARGB(colorTable)
    assert(colorTable and type(colorTable) == "table" and #colorTable == 4, "TARGB: colorTable is invalid!")
    return ARGB(colorTable[1], colorTable[2], colorTable[3], colorTable[4])
end

function test(target)
	return player + Vector(target.x-player.x,target.y,target.z-player.z):normalized()*(GetDistance(target,player)-200)
end