
function ScriptMsg(msg)
  print("<font color=\"#daa520\"><b>APLD KogMaw:</b></font> <font color=\"#FFFFFF\">"..msg.."</font>")
end


local Author = "KaoKaoNi"
local Version = "1.01"

local SCRIPT_INFO = {
	["Name"] = "Kao Helper",
	["Version"] = 1.01,
	["Author"] = {
		["KaoKaoNi"] = "http://forum.botoflegends.com/user/145247-"
	},
}
local SCRIPT_UPDATER = {
	["Activate"] = true,
	["Script"] = SCRIPT_PATH..GetCurrentEnv().FILE_NAME,
	["URL_HOST"] = "raw.github.com",
	["URL_PATH"] = "/kej1191/anonym/master/Helper/Helper/Kao Helper.lua",
	["URL_VERSION"] = "/kej1191/anonym/master/Helper/Helper/version/Kao Helper.version"
}
local SCRIPT_LIBS = {
	["SourceLib"] = "https://raw.github.com/LegendBot/Scripts/master/Common/SourceLib.lua",
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

local Author =  "KaoKaoNi"
local Version = "1.01"

local Statu = {}

local enemycd = {}
local allycd = {}

local SpellId = {_Q, _W, _E, _R}
local _SpellId = {"Q", "W", "E", "R"}


local TrackSpells = {_Q, _W, _E, _R}
local SSpells = {
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

local SpellsData = {}
local TickLimit = 0
local FirstTick = false

local missing_since = {}
local missing_time = {}
local traveled_distance = 0

local tRange = 950
local towers = {}
local tHealth = {1000, 1200, 1300, 1500, 2000, 2300, 2500}

local player = myHero

local ExpRangeDraw = false

local PATH = BOL_PATH.."Sprites\\"
local Code = {
	['5.9'] = {solution = "0.0.0.163", projects = "0.0.0.174"},
	['5.10'] = {solution = "0.0.1.91", projects = "0.0.1.146"},
}
local LolClientVersion = {"5.10", "5.9"}

local SQUARE_PATH
local Spell_Img_PATH
local enemyTable

local J_enemyTabls = {}
local J_allyTabls = {}
local J_chat = {}


local wards = {}

enemyMinions = minionManager(MINION_ENEMY, 1400, myHero, MINION_SORT_MAXHEALTH_DEC)

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
	--LoadItem()
	SQUARE_PATH = GAME_PATH:gsub('\\solutions\\lol_game_client_sln\\releases\\'..Code[LolClientVersion[Config.ClientVersion]].solution..'\\deploy', '\\projects\\lol_air_client\\releases\\'..Code[LolClientVersion[Config.ClientVersion]].projects..'\\deploy\\assets\\images\\champions')
	Spell_Img_PATH = GAME_PATH:gsub('\\solutions\\lol_game_client_sln\\releases\\'..Code[LolClientVersion[Config.ClientVersion]].solution..'\\deploy', '\\projects\\lol_air_client\\releases\\'..Code[LolClientVersion[Config.ClientVersion]].projects..'\\deploy\\assets\\images\\abilities')
	enemyTable = {}
	for i, enemy in ipairs(GetEnemyHeroes()) do
        missing_since[i] = -1
		enemyTable[enemy.charName] = {unit = enemy, dead = false, sprite = nil, transparency = 0xBF, q = nil, w = nil, e = nil, r = nil} 
		enemyTable[enemy.charName].sprite = FindSprite(SQUARE_PATH .. enemy.charName .. '_Square_0.png')
		--[[
		local Qname, Wname, Ename, Rname = enemy:GetSpellData(_Q).name, enemy:GetSpellData(_W).name, enemy:GetSpellData(_E).name, enemy:GetSpellData(_R).name
		print (Qname.." "..Wname.." "..Ename.." "..Rname)
		enemyTable[enemy.charName].q = FindSprite(Spell_Img_PATH .. enemy.charName .. "_" .. Qname .. '.png')
		enemyTable[enemy.charName].w = FindSprite(Spell_Img_PATH .. enemy.charName .. "_" .. Wname .. '.png')
		enemyTable[enemy.charName].e = FindSprite(Spell_Img_PATH .. enemy.charName .. "_" .. Ename .. '.png')
		enemyTable[enemy.charName].r = FindSprite(Spell_Img_PATH .. enemy.charName .. "_" .. Rname .. '.png')
		]]
		J_enemyTabls[enemy.charName] = {unit = enemy, attack = false, attacked = false, casting = nil, statu = ""}
    end
	
	for i, ally in ipairs(GetAllyHeroes()) do
		J_allyTabls[ally.charName] = {unit = enemy, attack = false, attacked = false, casting = nil, statu = ""}
	end
	
	for i = 1, objManager.iCount, 1 do
        local tow = objManager:getObject(i)
        if tow ~= nil then
			for j, health in ipairs(tHealth) do
				if tow.type == "obj_AI_Turret" and not string.find(tow.name, "TurretShrine") then
					table.insert(towers, tow)
					break
				end
			end
		end
	end
end

function OnTick()
	if Config.MissingTimer.On then MissingTimer() end
	if Config.CoolDownChecker.On and Config.CoolDownChecker.Type == 2 then CoolDownChecker_Line_Tick() end
	if Config._3DRader.On then _3DRader_Tick() end
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
	if Config.Misc.DrawTawerRange then TowerRange() end
	--if Config.Jarvis.On and Config.Jarvis.DrawInfo then Jarvis_Draw() end
	if Config.WardTracker.On then WardTracker_Draw() end
	if Config.Misc.DrawExpRange then ExpRange_Draw() end
end

function OnUnload()
    for index, enemy in pairs(enemyTable) do
		if enemy.sprite ~= nil then
			enemy.sprite:Release()
		end
    end    
end

function OnLoadMenu()
	Config = scriptConfig("Kao Hepler", "Kao Hepler")
		
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
			Config._3DRader:addParam("Info1", "", SCRIPT_PARAM_INFO, "")
			Config._3DRader:addParam("Info", "Draw Line Info", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("Name", "Draw Name", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("NameType", "Name Type", SCRIPT_PARAM_LIST, 1, {"Name", "Image"})
			Config._3DRader:addParam("Range", "Draw Distance", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("MinRange", "MinRange", SCRIPT_PARAM_SLICE, 1500, 1000, 3000, 0)
			Config._3DRader:addParam("length", "Line Length",SCRIPT_PARAM_SLICE, 120, 10, 200, 1)
			Config._3DRader:addParam("distance", "Line Distance",SCRIPT_PARAM_SLICE, 200, 0, 350, 1)  
		
		Config:addSubMenu("MissingTimer", "MissingTimer")
			Config.MissingTimer:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			Config.MissingTimer:addParam("ShowTimer", "Show Missing Timer", SCRIPT_PARAM_ONOFF, true)
			Config.MissingTimer:addParam("ShowImage", "Show Missing Image", SCRIPT_PARAM_ONOFF, true)
			Config.MissingTimer:addParam("DrawCircle", "Show circle on minimap" , SCRIPT_PARAM_ONOFF, true)
			Config.MissingTimer:addParam("MinRadius", "Alert after range", SCRIPT_PARAM_SLICE, 2000, 1500, 3000, 0)
			Config.MissingTimer:addParam("MaxRadius", "Max circle radius", SCRIPT_PARAM_SLICE, 5000, 3000, 9000, 0)
			
		Config:addSubMenu("WardTracker","WardTracker")
			Config.WardTracker:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			
		--[[
		Config:addSubMenu("Jarvis", "Jarvis")
			Config.Jarvis:addParam("Info1", "this is beta not perfect", SCRIPT_PARAM_INFO, "")
			Config.Jarvis:addParam("On", "On", SCRIPT_PARAM_ONOFF, false)
			Config.Jarvis:addParam("DrawInfo", "Draw Info", SCRIPT_PARAM_ONOFF, true)
			Config.Jarvis:addParam("X", "Draw X vector", SCRIPT_PARAM_SLICE, 100, 0, WINDOW_W, 0)
			Config.Jarvis:addParam("Y", "Draw Y vector", SCRIPT_PARAM_SLICE, 100, 0, WINDOW_H, 0)
		]]
		
		Config:addSubMenu("Misc", "Misc")
			Config.Misc:addParam("DrawTawerRange", "Draw Tower Range", SCRIPT_PARAM_ONOFF, true)
			Config.Misc:addParam("DrawExpRange", "Drwa Exp Range", SCRIPT_PARAM_ONOFF, true)
			
		Config:addParam("INFO", "", SCRIPT_PARAM_INFO, "")
		Config:addParam("Author", "Author", SCRIPT_PARAM_INFO, Author)
		Config:addParam("Version", "Version", SCRIPT_PARAM_INFO, Version)
		Config:addParam("ClientVersion", "Your Client Version", SCRIPT_PARAM_LIST, 1, LolClientVersion)
			
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
					--DrawRectangleAL(startPos.x-1, startPos.y-30, 75 , 13, 0xBB202020)
					if Enemy:GetSpellData(SpellId[i]).level ~= 0 then
						if Enemy:GetSpellData(SpellId[i]).currentCd == 0 then
							DrawText("[".._SpellId[i].."]",12, startPos.x+20*(i-1), startPos.y, 0xFFFFFF00)
						else
							DrawText("["..math.ceil(Enemy:GetSpellData(SpellId[i]).currentCd).."]",12, startPos.x+20*(i-1), startPos.y, 0xFFFF0000)
						end
					else
						DrawText("[".._SpellId[i].."]",12, startPos.x+20*(i-1), startPos.y, 0xBBFFFFFF)
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
					if Ally:GetSpellData(SpellId[i]).level ~= 0 then
						if Ally:GetSpellData(SpellId[i]).currentCd == 0 then
							DrawText("[".._SpellId[i].."]",12, startPos.x, startPos.y+20*(i-1), 0xFFFFFF00)
						else
							DrawText("["..math.ceil(Ally:GetSpellData(SpellId[i]).currentCd).."]",12, startPos.x, startPos.y+20*(i-1), 0xFFFF0000)
						end
					else
						DrawText("[".._SpellId[i].."]",12, startPos.x+20*(i-1), startPos.y, 0xBBFFFFFF)
					end
					--DrawRectangleAL(startPos.x-1, startPos.y-1, 22 , 22, ARGB(255, 128, 128, 128))
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
					local CDcolor = ARGB(255, 214, 114, 0)
					local Readycolor = ARGB(255, 54, 214, 0)
					local Textcolor = ARGB (255, 255, 255, 255)
					local Backgroundcolor = ARGB(255, 128, 128, 128)
					local width = 20
					local height = 5
					local sep = 2
					--[[First 4 spells]]
					pos.y =  pos.y + 0
					for j, Spells in ipairs (TrackSpells) do
						local currentcd = SpellsData[i][Spells].currentCd
						local maxcd = SpellsData[i][Spells].maxCd
						local level = SpellsData[i][Spells].level
						
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
						
						DrawRectangleAL(pos.x-1, pos.y-1, width + sep , height+4, Backgroundcolor)
					
						if level == 0 then
							DrawRectangleAL(pos.x, pos.y, width, height, 0xBBFFFFFF)
						else
							if (currentcd ~= 0) then
								DrawRectangleAL(pos.x, pos.y, width - math.floor(width * currentcd) / maxcd, height, CDcolor)
							else
								DrawRectangleAL(pos.x, pos.y, width, height, Readycolor)
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
						local currentcd = SpellsData[i][Spells].currentCd
						local maxcd = SpellsData[i][Spells].maxCd
						local width2 = 202
						if j > 4 then
							CDcolor = ARGB(255, 255, 255, 255)
							for _, spell in ipairs(SSpells) do
								if  (hero:GetSpellData(j == 5 and SUMMONER_1 or SUMMONER_2).name == spell.Name) then
									CDcolor = ARGB(255, 214, 114, 0)
								end
							end
							DrawRectangleAL(pos.x, pos.y,width2+2,11,Backgroundcolor)
							if currentcd ~= 0 then
								DrawRectangleAL(pos.x+1, pos.y+1, width2 - width2 * currentcd / maxcd,9,CDcolor)
							else
								DrawRectangleAL(pos.x+1, pos.y+1, width2, 9, CDcolor)
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
				if Config._3DRader.Info then
					local myVec = Vector(myHero.x-Ally.x+40, 0 , myHero.z - Ally.z):normalized()
					local pos = WorldToScreen(D3DXVECTOR3(myHero.x - (myVec.x*(Config._3DRader.distance + Config._3DRader.length)), myVec.y*(Config._3DRader.distance + Config._3DRader.length), myHero.z - (myVec.z*(Config._3DRader.distance + Config._3DRader.length))))
					if Config._3DRader.NameType == 1 then
						if Config._3DRader.Name then DrawText(Ally.charName,18 ,pos.x, pos.y,0xFF000000) end
					elseif Config._3DRader.NameType ==2 then
						enemyTable[Ally.charName].sprite:SetScale(0.25, 0.25)
						enemyTable[Ally.charName].sprite:Draw(pos.x, pos.y, enemy.transparency)
					end
					if Config._3DRader.Range then DrawText("["..(math.floor(GetDistance(player, Ally)*0.01)).."m]" ,18,pos.x, pos.y+18, 0xFF000000) end
				end
			end
		end
	end
	if Config._3DRader.EnemyOn then
		for i, Enemy in ipairs(GetEnemyHeroes()) do
			if GetDistance(Enemy, player) >= Config._3DRader.MinRange and not Enemy.dead and ValidTarget(Enemy) then
				DrawLine3D(myHero.x, myHero.y, myHero.z, Enemy.x, Enemy.y, Enemy.z, LineType(Enemy), 0xffff0000)
				if Config._3DRader.Info then
					local myVec = Vector(myHero.x-Enemy.x, 0 , myHero.z - Enemy.z):normalized()
					local pos = WorldToScreen(D3DXVECTOR3(myHero.x - (myVec.x*(Config._3DRader.distance + Config._3DRader.length)), myVec.y*(Config._3DRader.distance + Config._3DRader.length), myHero.z - (myVec.z*(Config._3DRader.distance + Config._3DRader.length))))
					if Config._3DRader.NameType == 1 then
						if Config._3DRader.Name then DrawText(Enemy.charName,18 ,pos.x-50, pos.y-50, 0xFF000000) end
					elseif Config._3DRader.NameType ==2 then
						enemyTable[Enemy.charName].sprite:SetScale(0.5, 0.5)
						enemyTable[Enemy.charName].sprite:Draw(pos.x-50, pos.y-50, enemyTable[Enemy.charName].transparency)
					end
					if Config._3DRader.Range then DrawText("["..(math.floor(GetDistance(player, Enemy)*0.01)).."m]" ,18,pos.x-50, pos.y+15, 0xFF000000) end
				end
			end
		end
	end
end

function LineType(unit)
	if Config._3DRader.LineType == 1 then
		return 8
	else
		local Distance = GetDistance(unit, player)
		if (16000/Distance) > 0 then
			return math.abs(16000/Distance)
		else
			return 1
		end
	end
end

function _3DRader_Tick()
	for index, enemy in pairs(enemyTable) do
		if enemy.unit.dead == true then
			enemyTable[index].transparency = 0x22
			enemyTable[index].color = 0x55FFFFFF
		elseif not enemy.unit.visible then 
			enemyTable[index].transparency = 0x99                    
			enemyTable[index].color = 0xFFFF0000
		else
			enemyTable[index].transparency = 0xFF                    
			enemyTable[index].color = 0xFFAA2222
		end
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
					
					if Config.MissingTimer.ShowImage then
						enemyTable[enemy.charName].sprite:SetScale(0.25, 0.25)
						enemyTable[enemy.charName].sprite:Draw(GetMinimapX(enemy.x)-6*GetMinimapRatio(), GetMinimapY(enemy.z)-6*GetMinimapRatio(), 0x99)
					end
                
                else
                    
                    if Config.MissingTimer.drawCircle then
                        DrawCircleMinimap(enemy.x, enemy.y, enemy.z, Config.MissingTimer.MaxRadius, 2, 4294902015)
                    end
                    
                    if Config.MissingTimer.ShowTimer then
                        DrawText(tostring(math.floor(missing_time[i])), 20, GetMinimapX(enemy.x)-6*GetMinimapRatio(), GetMinimapY(enemy.z)-6*GetMinimapRatio(), ARGB(255, 255, 0, 0))
                    end
					
					if Config.MissingTimer.ShowImage then
						enemyTable[enemy.charName].sprite:SetScale(0.25, 0.25)
						enemyTable[enemy.charName].sprite:Draw(GetMinimapX(enemy.x)-6*GetMinimapRatio(), GetMinimapY(enemy.z)-6*GetMinimapRatio(), 0x99)
					end
					
                end
            end
        end
    end
end

function TowerRange()
	for i, tow in ipairs(towers) do
		if tow.health >  0 and myHero:GetDistance(tow.pos) <= tRange+1000 then
			DrawCircle(tow.x, tow.y, tow.z, tRange, RGB(80, 0, 0))
		end
	end
end

---------------------------------
---------Gold&Power--------------
---------------------------------



---------------------------------
---------WardTracker-------------
---------------------------------

function OnCreatWard(obj)
	if obj.name:lower():find("sight")  or (obj.name:lower():find("vision") and obj.maxMana > 0) then
		local ward = {x = obj.x, y = obj.y, z = obj.z, mana = obj.mana, time = GetGameTimer()}
		table.insert(wards, ward);
	end
end

function OnDeleteWard(obj)
	for index, ward in pairs(wards) do
		if (obj.x == ward.x) and (obj.x == ward.x) and (obj.x == ward.x) then
			table.remove(wards, index)
		end
	end
end

function WardTracker_Draw()
	for index, ward in pairs(wards) do
		currentMana = math.floor(ward.mana - (GetGameTimer() - ward.time))
		if (currentMana <= 0) then
			table.remove(wards, index)
		else
			LagFreeDrawCircle(ward.x, ward.y, ward.z, 100, RGBA(127, 255, 0, 255))
			DrawText3D(tostring(currentMana), ward.x, ward.y, ward.z, 20, RGBA(127, 255, 0, 255), true)
		end
	end
end

---------------------------------
---------Jarvis------------------
---------------------------------

function Jarvis(unit, spell)
	if unit and spell then
		if unit.type == player.type then
			if unit.team == player.team then
				if spell.name:lower():find("attack") then
					if spell.target.type:lower():find("hero") then
						J_allyTabls[unit.charName].statu = "fighting"
					elseif spell.target.type:lower():find("minion") then
						J_allyTabls[unit.charName].statu = "farming"
					end
				end
			else			
				if spell.name:lower():find("attack") then
					if spell.target.type:lower():find("hero") then
						J_enemyTabls[unit.charName].statu = "fighting"
					elseif spell.target.type:lower():find("minion") then
						J_enemyTabls[unit.charName].statu = "farming"
					end
				end
			end
		end
	end
end

function Jarvis_Tick()
end

function Jarvis_Draw()
	-- J_chat
	-- DrawRectangleAL(pos.x, pos.y, width, height, 0xBBFFFFFF)
	local StartPos = {x = 500, y = 100}
	local J_Font_Size = 18
	DrawRectangleAL(StartPos.x, StartPos.y, 1000,StartPos.y - ( #J_chat*J_Font_Size ))
	for index, chat in ipairs(J_chat) do
		if index > 5 then
			table.remove(J_chat, index)
		else
			DrawText("Jarvis : "..J_chat[index],J_Font_Size, StartPos.x, StartPos.y - ( index * J_Font_Size ) )
		end
	end
end

---------------------------------
---------ExpRange----------------
---------------------------------

function ExpRange_Draw()
	DrawCircle(player.x, player.y, player.z,1400, 0xffffffff)
end



---------------------------------
---------checker-----------------
---------------------------------

function OnProcessSpell(unit, spell)
	--if Config.Jarvis.On then Jarvis(unit, spell) end
end

function OnCreateObj(obj)
	if obj ~= nil then
		if Config.WardTracker.On then
			if obj.team ~= myHero.team and obj.name:lower():find("ward") and not obj.name:lower():find("idle") then
				OnCreatWard(obj)
			end
		end
	end
end

function OnDeleteObj(obj)
	if obj ~= nil then
		if Config.WardTracker.On then
			if obj.team ~= myHero.team and obj.name:lower():find("ward") and not obj.name:lower():find("idle") then
				OnDeleteWard(obj)
			end
		end
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
    assert(colorTable and type(colorTable) == "table" and #colorTable == 4, "0x0001 : colorTable is invalid")
    return ARGB(colorTable[1], colorTable[2], colorTable[3], colorTable[4])
end

function FindSprite(file) -- Thanks to Trees
    assert(type(file) == "string", "0x0002 : wrong argument types (<string> expected for file)")
    if FileExist(file) == true then
        return createSprite(file)
    else
        PrintChat("0x0003 : Check your client version and change version in script menu and reload script")
        return nil
		--createSprite("empty.dds")
    end
end

function LagFreeDrawCircle(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        DrawCircleNextLvl(x, y, z, radius, 1, color, 100) 
    end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
	quality = 2 * math.pi / quality
	radius = radius*.92
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