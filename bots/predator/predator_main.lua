--PredatorBot v0.000001
local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic 		= true
object.bRunBehaviors	= true
object.bUpdates 		= true
object.bUseShop 		= true

object.bRunCommands 	= true 
object.bMoveCommands 	= true
object.bAttackCommands 	= true
object.bAbilityCommands = true
object.bOtherCommands 	= true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core 		= {}
object.eventsLib 	= {}
object.metadata 	= {}
object.behaviorLib 	= {}
object.skills 		= {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading predator_main...')

object.heroName = 'Hero_Predator'

--------------------------------
-- Skills
--------------------------------
function object:SkillBuild()
	--core.VerboseLog("SkillBuild()")

	local unitSelf = self.core.unitSelf

	if skills.leap == nil then
		skills.leap = unitSelf:GetAbility(0)
		skills.stoneHide = unitSelf:GetAbility(1)
		skills.carnivorous = unitSelf:GetAbility(2)
		skills.terror = unitSelf:GetAbility(3)
		skills.attributeBoost = unitSelf:GetAbility(4)
	end
	
	--[[ ability property test
	local sting = self.leap
	if sting then
		core.BotEcho(format("range: %g  manaCost: %g  canActivate: %s  isReady: %s  cooldownTime: %g  remainingCooldownTime: %g", 
		sting:GetRange(), sting:GetManaCost(), tostring(sting:CanActivate()), tostring(sting:IsReady()), sting:GetCooldownTime(), sting:GetRemainingCooldownTime()
		))
	end --]]
	
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	--max leap, 1 lvl stonehide, max {carnivorous, ult, stonehide, stats}
	if skills.leap:CanLevelUp() then
		skills.leap:LevelUp()
	elseif skills.stoneHide:GetLevel() < 1 then
		skills.stoneHide:LevelUp()
	elseif skills.carnivorous:CanLevelUp() then
		skills.carnivorous:LevelUp()
	elseif skills.terror:CanLevelUp() then
		skills.terror:LevelUp()
	elseif skills.stoneHide:CanLevelUp() then
		skills.stoneHide:LevelUp()
	else
		skills.attributeBoost:LevelUp()
	end	
end

---------------------------------------------------
--                   Overrides                   --
---------------------------------------------------

--[[for testing
function object:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)
	
	core.unitSelf:TeamShare()
	
	--BotEcho(tostring(core.enemyWellAttacker))
	if core.enemyWellAttacker then
		core.DrawXPosition(core.enemyWellAttacker:GetPosition(), 'blue')
	end
	
	local vecMyPos = core.unitSelf:GetPosition()
	local vecEWellPos = core.enemyWellAttacker:GetPosition()
	local vToMe = Vector3.Normalize(vecMyPos - vecEWellPos)
	--core.AdjustMovementForTowerLogic(vecEWellPos + vToMe * 250, true)
	
	if false then
		behaviorLib.HitBuildingUtility(self)
	
		local vecMyPos = core.unitSelf:GetPosition()
		
		--behaviorLib.HitBuildingUtility(self)
		
		local unitTower = core.GetClosestEnemyTower(vecMyPos)
		
		if unitTower then
			local vecToMe = Vector3.Normalize(vecMyPos - unitTower:GetPosition())
			core.AdjustMovementForTowerLogic(unitTower:GetPosition() + vecToMe * 150)
			BotEcho("TowerSafe: "..tostring(core.IsTowerSafe(unitTower, core.unitSelf)))
			core.DrawXPosition(unitTower:GetPosition(), 'red')
		end
	end
end
object.onthinkOld = object.onthink
object.onthink 	= object.onthinkOverride
--]]

behaviorLib.nCreepPushbackMul = 0.5
behaviorLib.nTargetPositioningMul = 0.6

----------------------------------
--	Pred specific harass bonuses
--
--  Abilities off cd increase harass util
--  Ability use increases harass util for a time
----------------------------------

object.leapUpBonus = 13
--object.stoneHideUpBonus = ?
object.terrorUpBonus = 16

object.leapUseBonus = 35
object.terrorUseBonus = 25

object.leapUtilThreshold = 35

local function AbilitiesUpUtilityFn(hero)
	local bDebugLines = false
	local bDebugEchos = false
	
	local val = 0
	
	if skills.leap:CanActivate() then
		val = val + object.leapUpBonus
	end
	
	--if skills.stoneHide:CanActivate() then
	--	val = val + object.stoneHideUpBonus
	--end
	
	if skills.terror:CanActivate() then
		val = val + object.terrorUpBonus
	end
	
	if bDebugEchos then BotEcho(" HARASS - abilitiesUp: "..val) end
	if bDebugLines then
		local lineLen = 150
		local myPos = core.unitSelf:GetPosition()
		local vTowards = Vector3.Normalize(hero:GetPosition() - myPos)
		local vOrtho = Vector3.Create(-vTowards.y, vTowards.x) --quick 90 rotate z
		core.DrawDebugArrow(myPos - vOrtho * lineLen * 1.4, (myPos - vOrtho * lineLen * 1.4 ) + vTowards * val * (lineLen/100), 'cyan')
		core.DrawDebugLine( (myPos - vOrtho * lineLen * 0.6) + vTowards * lineLen * (object.leapUtilThreshold/100) - (vOrtho * 0.15 * lineLen),
								(myPos - vOrtho * lineLen * 0.6) + vTowards * lineLen * (object.leapUtilThreshold/100) + (vOrtho * 0.15 * lineLen), 'white')
	end
	
	return val
end

--Pred ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local addBonus = 0
	
	if EventData.Type == "Ability" then
		--BotEcho("  ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)
		if EventData.InflictorName == "Ability_Predator1" then
			addBonus = addBonus + object.leapUseBonus
		elseif EventData.InflictorName == "Ability_Predator4" then
			addBonus = addBonus + object.terrorUseBonus
		end
	end
	
	if addBonus > 0 then
		--decay before we add
		core.DecayBonus(self)
	
		core.nHarassBonus = core.nHarassBonus + addBonus
	end
end
object.oncombateventOld = object.oncombatevent
object.oncombatevent 	= object.oncombateventOverride

--Util calc override
local function CustomHarassUtilityOverride(hero)
	local nUtility = AbilitiesUpUtilityFn(hero)
	
	return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride   


----------------------------------
--	Pred harass actions
----------------------------------
local function HarassHeroExecuteOverride(botBrain)
	local bDebugEchos = false
	
	--[[
	if object.myName == "Bot5" then
		bDebugEchos = true
	end--]]
	
	local unitSelf = core.unitSelf
	local target = behaviorLib.heroTarget 
	
	local bActionTaken = false
	--since we are using an old pointer, ensure we can still see the target for entity targeting
	if target ~= nil and core.CanSeeUnit(botBrain, target) then 
		local dist = Vector3.Distance2D(unitSelf:GetPosition(), target:GetPosition())
		local attackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, target);
		
		--leap
		local leap = skills.leap
		local leapRange = leap:GetRange() + core.GetExtraRange(unitSelf) + core.GetExtraRange(target)
		if not bActionTaken then
			if bDebugEchos then BotEcho("No action taken, considering Leap") end			
			local bLeapUsable = leap:CanActivate() and dist < leapRange
			local bShouldLeap = false 
			
			if bLeapUsable and behaviorLib.lastHarassUtil > botBrain.leapUtilThreshold then
				bShouldLeap = true
			end
			
			if bShouldLeap then
				if bDebugEchos then BotEcho('LEAPIN!') end
				bActionTaken = core.OrderAbilityEntity(botBrain, leap, target)
			end
		end
		
		--terror
		local terror = skills.terror
		if not bActionTaken then
			if bDebugEchos then BotEcho("No action taken, considering Terror") end			
			--only use terror if we are ready to wreck them
			--BotEcho('terror logic - terror:CanActivate: '..tostring(terror:CanActivate())..' and '..dist..' < '..attackRange)
			if terror:CanActivate() and dist < attackRange then
				if bDebugEchos then BotEcho("TERRORIN!") end
				bActionTaken = core.OrderAbility(botBrain, terror)
			end
		end
	end
	
	if not bActionTaken then
		if bDebugEchos then BotEcho("No action taken, running my base harass") end
		return object.harassExecuteOld(botBrain)
	end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


----------------------------------
--	Predator items
----------------------------------
--[[ list code:
	"# Item" is "get # of these"
	"Item #" is "get this level of the item" --]]
behaviorLib.StartingItems = {"Item_LoggersHatchet", "Item_IronBuckler", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = {"Item_Marchers", "Item_Strength5", "Item_Steamboots", "Item_Strength6"} --Item_Strength6 is Frostbrand
behaviorLib.MidItems = {"Item_Immunity", "Item_StrengthAgility", "Item_Insanitarius"} --Immunity is Shrunken Head, Item_StrengthAgility is Frostburn
behaviorLib.LateItems = {"Item_SolsBulwark", "Item_DaemonicBreastplate", "Item_BehemothsHeart", "Item_Damage9"} --Item_Damage9 is doombringer



--[[ colors:
	red
	aqua == cyan
	gray
	navy
	teal
	blue
	lime
	black
	brown
	green
	olive
	white
	silver
	purple
	maroon
	yellow
	orange
	fuchsia == magenta
	invisible
--]]

BotEcho('finished loading predator_main')

