
function ScriptMsg(msg)
  print("<font color=\"#66CCFF\"><b>Kao Helper:</b></font> <font color=\"#FFFFFF\">"..msg.."</font>")
end


local Author = "KaoKaoNi"
local Version = "1.0"

local SCRIPT_INFO = {
	["Name"] = "Kao Helper",
	["Version"] = 1.0,
	["Author"] = {
		["KaoKaoNi"] = "http://forum.botoflegends.com/user/145247-"
	},
}
local SCRIPT_UPDATER = {
	["Activate"] = true,
	["Script"] = SCRIPT_PATH..GetCurrentEnv().FILE_NAME,
	["URL_HOST"] = "raw.github.com",
	["URL_PATH"] = "/kej1191/anonym/master/Helper/Helper/Kao Helper.lua",
	["URL_VERSION"] = "/kej1191/anonym/master/Helper/Helper/version/Free Awarencess/Kao Helper.version"
}
local SCRIPT_LIBS = {
	["SourceLib"] = "https://raw.github.com/LegendBot/Scripts/master/Common/SourceLib.lua",
}

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

local Statu = {}

local enemycd = {}
local allycd = {}

local SpellId = {_Q, _W, _E, _R}
local _SpellId = {"Q", "W", "E", "R"}

local player = myHero

if VIP_USER then
 	AdvancedCallback:bind('OnApplyBuff', function(source, unit, buff) OnApplyBuff(source, unit, buff) end)
	AdvancedCallback:bind('OnUpdateBuff', function(unit, buff, stack) OnUpdateBuff(unit, buff, stack) end)
	AdvancedCallback:bind('OnRemoveBuff', function(unit, buff) OnRemoveBuff(unit, buff) end)
end


function OnLoad()
	OnLoadMenu()
end

function OnTick()
end

function OnDraw()
	if Config.CoolDownChecker.On then CoolDownChecker() end
	if Config._3DRader.On then _3DRader() end
end

function OnLoadMenu()
	Config = scriptConfig("Free Awarencess", "Free Awarencess")
		
		Config:addSubMenu("CoolDownChecker", "CoolDownChecker")
			Config.CoolDownChecker:addSubMenu("Enemy", "Enemy")
				Config.CoolDownChecker.Enemy:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
				
				for i, Enemy in ipairs(GetEnemyHeroes()) do
					Config.CoolDownChecker.Enemy:addParam(Enemy.charName, Enemy.charName.." On", SCRIPT_PARAM_ONOFF, true)
				end
				
			Config.CoolDownChecker:addSubMenu("Ally", "Ally")
				Config.CoolDownChecker.Ally:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
				
				for i, Ally in ipairs(GetAllyHeroes()) do
					Config.CoolDownChecker.Ally:addParam(Ally.charName, Ally.charName.." On", SCRIPT_PARAM_ONOFF, true)
				end
				
			Config.CoolDownChecker:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
		
		Config:addSubMenu("3DRader", "_3DRader")
			Config._3DRader:addParam("On", "On", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("EnemyOn", "Enemy On", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("AllyOn", "Ally On", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("Line", "Line", SCRIPT_PARAM_ONOFF, true)
			Config._3DRader:addParam("LineType", "Line Type", SCRIPT_PARAM_LIST, 2, {"Static", "Dynamic"})
			Config._3DRader:addParam("Range", "Range", SCRIPT_PARAM_ONOFF, true)
end

function CoolDownChecker()
	if Config.CoolDownChecker.Enemy.On then
		for i, Enemy in ipairs(GetEnemyHeroes()) do
			if Config.CoolDownChecker.Enemy[Enemy.charName] then
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
	end
	if Config.CoolDownChecker.Ally.On then
		for i, Ally in ipairs(GetAllyHeroes()) do
			if Config.CoolDownChecker.Ally[Ally.charName] then
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
end

function _3DRader()
	if Config._3DRader.AllyOn then
		for i, Ally in ipairs(GetAllyHeroes()) do
			DrawLine3D(myHero.x, myHero.y, myHero.z, Ally.x, Ally.y, Ally.z, LineType(Ally), 0x0000FF)
		end
	end
	if Config._3DRader.EnemyOn then
		for i, Enemy in ipairs(GetEnemyHeroes()) do
			if GetDistance(Enemy, player) >= 1000 and not Enemy.dead and ValidTarget(Enemy) then
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