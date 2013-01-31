--TeamBot v0.000001
local _G = getfenv(0)
local object = _G.object

object.teamID = object:GetTeam()
object.myName = ('Team '..(object.teamID or 'nil'))

object.bRunLogic 		= true
object.bGroupAndPush	= true

object.bUseRealtimePositions = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false


object.core 		= {}
object.metadata 	= {}

runfile "bots/core.lua"
runfile "bots/metadata.lua"

local core, metadata = object.core, object.metadata

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('Loading teambotbrain...')

object.tAllyHeroes = {}
object.tEnemyHeroes = {}
object.tAllyHumanHeroes = {}
object.tAllyBotHeroes = {}

object.tTopLane = {}
object.tMiddleLane = {}
object.tBottomLane = {}

object.teamBotBrainInitialized = false
function object:TeamBotBrainInitialize()
	BotEcho('TeamBotBrainInitializing')
	
	local bDebugEchos = false

	--collect all heroes
	self.tAllyHeroes = HoN.GetHeroes(core.myTeam)
	self.tEnemyHeroes = HoN.GetHeroes(core.enemyTeam)
	
	for _, hero in pairs(self.tAllyHeroes) do
		if hero:IsBotControlled() then
			tinsert(self.tAllyBotHeroes, hero)
		else
			tinsert(self.tAllyHumanHeroes, hero)
		end
	end
	
	if bDebugEchos then
		BotEcho('tAllyHeroes')
		core.printGetTypeNameTable(self.tAllyHeroes)
		BotEcho('allyHumanHeroes')
		core.printGetTypeNameTable(self.tAllyHumanHeroes)
		BotEcho('allyBotHeroes')
		core.printGetTypeNameTable(self.tAllyBotHeroes)
		BotEcho('enemyHeroes')
		core.printGetTypeNameTable(self.tEnemyHeroes)		
	end
	
	object.teamBotBrainInitialized = true
end

--Time left before the match starts when the bots should move to lane
object.nInitialBotMove = 15000

object.bLanesBuilt = false
object.laneDoubleCheckTime = 17000 --time after start to double check our lane decisions
object.bLanesDoubleChecked = false
object.laneReassessTime = 0
object.laneReassessInterval = core.SToMS(core.MinToS(3)) --regular interval to check for player lane switches

local STATE_IDLE		= 0
local STATE_GROUPING	= 1
local STATE_PUSHING		= 2
object.nPushState = STATE_IDLE

--Called every frame the engine gives us during the actual match
function object:onthink(tGameVariables)
	StartProfile('onthink')
	if core.coreInitialized == false or core.coreInitialized == nil then
		core.CoreInitialize(self)
	end	
	if self.teamBotBrainInitialized == false then
		self:TeamBotBrainInitialize()
	end
	if metadata.bInitialized == false then
		metadata.Initialize()
	end	
	if core.tGameVariables == nil then
		if tGameVariables == nil then
			BotEcho("TGAMEVARIABLES IS NIL OH GOD OH GOD WHYYYYYYYY!??!?!!?")
		else
			core.tGameVariables = tGameVariables
			core.bIsTutorial = core.tGameVariables.sMapName == 'tutorial'
			
			if core.bIsTutorial then
				if core.myTeam == HoN.GetHellbourneTeam() then
					--Tutorial Hellbourne heroes don't group up to push
					self.bGroupAndPush = false
				else
					--Tutorial Legion waits longer to push
					object.nNextPushTime = core.SToMS(core.MinToS(12))
				end
			end
		end
	end

	if self.bRunLogic == false then 
		return
	end
	
	self.bPurchasedThisFrame = false

	StartProfile('Memory Units')
		StartProfile('Validate')
			core.ValidateReferenceTable(self.tMemoryUnits)
		StopProfile()
		StartProfile('Update')
			self:UpdateAllMemoryUnits()
		StopProfile()
	StopProfile()

	StartProfile('LethalityCalculations')
		--TODO: add frequency limits for more performance if needed
		self:LethalityCalculations()
	StopProfile()
	
	StartProfile('Lane Building')
		--build lanes as the match starts, and reassess lanes every few minutes to cater to players
		local curTime = HoN.GetGameTime()

		if HoN.GetRemainingPreMatchTime() <= self.nInitialBotMove then
			if curTime > self.laneReassessTime and self.nPushState == STATE_IDLE then
				self:BuildLanes()
				
				if self.bLanesDoubleChecked then
					self.laneReassessTime = curTime + self.laneReassessInterval
				else
					self.laneReassessTime = curTime + self.laneDoubleCheckTime
					self.bLanesDoubleChecked = true
				end
			end
		end
	StopProfile()
	
	StartProfile('Group and Push Logic')
	if self.bGroupAndPush ~= false then
		self:GroupAndPushLogic()
	end
	StopProfile()
end

---- Memory units ----
object.tMemoryUnits = {}

object.nMemoryUnitHealthIntervalMS = 3000
function object:CreateMemoryUnit(unit)	
	StartProfile('CreateMemoryUnit')
	
	if unit == nil then
		BotEcho("CreateMemoryUnit - unit is nil")
		StopProfile()
		return nil
	end
	
	local nID = unit:GetUniqueID()
	local tMemoryUnits = self.tMemoryUnits
	if tMemoryUnits and tMemoryUnits[nID] ~= nil then
		--BotEcho(tostring(unit).." is already a memory unit; returning it")
		StopProfile()
		return tMemoryUnits[nID]
	end
		
	local tWrapped = core.WrapInTable(unit)
	
	if tWrapped then		
		--add to our list
		if tMemoryUnits then
			tMemoryUnits[nID] = tWrapped
		end
	
		local tMetatable = getmetatable(tWrapped)
		local tFunctionObject = tMetatable.__index
		
		--Echo("tFunctionObject")
		--core.printTable(tFunctionObject)
		
		--store some data
		tWrapped.bIsMemoryUnit		= true
		tWrapped.storedTime			= HoN.GetGameTime()
		tWrapped.storedHealth 		= tWrapped:GetHealth()
		tWrapped.storedMaxHealth 	= tWrapped:GetMaxHealth()
		tWrapped.storedMana			= tWrapped:GetMana()
		tWrapped.storedMaxMana		= tWrapped:GetMaxMana()
		tWrapped.storedPosition		= tWrapped:GetPosition()
		tWrapped.storedMoveSpeed	= tWrapped:GetMoveSpeed()
		tWrapped.storedAttackRange	= tWrapped:GetAttackRange()
		tWrapped.lastStoredPosition	= nil
		tWrapped.lastStoredTime  	= nil
		
		tWrapped.tStoredHealths 	= {}
		tWrapped.nHealthVelocity	= nil
		
		--tWrapped.nAverageHealthVelocity		= nil
		--tWrapped.nAverageHealthVelocityTime	= nil
		
		tWrapped.debugPosition		= false
		tWrapped.debugPositionSent	= false
		
		--tWrapped.storedPositions 	= {}
		--tWrapped.storedPositions[tWrapped.storedTime] = tWrapped:GetPosition()
		
		local funcNewGetHealth = nil
		local funcNewGetMaxHealth = nil
		local funcNewGetHealthPercent = nil
		local funcNewGetMana = nil
		local funcNewGetMaxMana = nil
		local funcNewGetPosition = nil
		local funcNewGetMoveSpeed = nil
		local funcNewGetAttackRange = nil
		
		local funcGetHealthVelocity = nil
		
		
		--GetHealth
		funcNewGetHealth = function(tThis)
			return tThis.storedHealth
		end
		
		--GetMaxHealth
		funcNewGetMaxHealth = function(tThis)
			return tThis.storedMaxHealth
		end
		
		--GetHealthPercent
		funcNewGetHealthPercent = function(tThis)
			return tThis.storedHealth/tThis.storedMaxHealth
		end
					
		--GetMana
		funcNewGetMana = function(tThis)
			return tThis.storedMana
		end
		
		--GetMaxMana
		funcNewGetMaxMana = function(tThis)
			return tThis.storedMaxMana
		end
		
		--GetPosition
		funcNewGetPosition = function(tThis)
			local vecReturn = tThis.storedPosition
			local bPredicted = false
			
			if object.bUseRealtimePositions and core.CanSeeUnit(object, tThis) then
				vecReturn = tThis.object:GetPosition()
			end
			
			local nCurrentTime = HoN.GetGameTime()
			if tThis.storedTime ~= nCurrentTime and not core.CanSeeUnit(object, tThis) then --object reference feels hacky, probably because it is
				--prediction and shit
				bPredicted = true
				--core.UpdateMemoryAveragePositions(tThis)
				if tThis.storedPosition and tThis.lastStoredPosition and tThis.storedMoveSpeed then
					local vecLastDirection = Vector3.Normalize(tThis.storedPosition - tThis.lastStoredPosition)
					vecReturn = tThis.storedPosition + vecLastDirection * tThis.storedMoveSpeed * core.MSToS(nCurrentTime - tThis.storedTime)
					
					if tThis.debugPosition then core.DrawArrowLine(tThis.storedPosition, tThis.storedPosition + vecLastDirection * 150, 'teal') end				
				else
					vecReturn = tThis.storedPosition
				end
			end
			
			if tThis.debugPosition and not tThis.debugPositionSent then
				if tThis.lastStoredPosition then 	core.DrawXPosition(tThis.lastStoredPosition, 'teal') end
				if tThis.storedPosition then 		core.DrawXPosition(tThis.storedPosition, 'blue') end
				if vecReturn then 				core.DrawXPosition(vecReturn, 'red') end
				tThis.debugPositionSent = true
			end
			
			return vecReturn, bPredicted
		end
		
		--GetMoveSpeed
		funcNewGetMoveSpeed = function(tThis)
			return tThis.storedMoveSpeed
		end
		
		--GetAttackRange
		funcNewGetAttackRange = function(tThis)
			return tThis.storedAttackRange
		end
		
		--GetHealthVelocity
		funcGetHealthVelocity = function(tThis)
			return tThis.nHealthVelocity or 0
		end
		
		--GetAverageHealthVelocity
		--[[
		local function GetAverageHealthVelocityFn(t)
			local nAverageHealthVelocityTime = t.nAverageHealthVelocityTime
			if nAverageHealthVelocityTime == nil or nAverageHealthVelocityTime < t.storedTime then
				core.UpdateAverageHealthVelocity(t)
			end
			
			return t.nAverageHealthVelocity or 0
		end
		tFunctionObject.GetAverageHealthVelocity = GetAverageHealthVelocityFn
		--]]	
		
		tFunctionObject.GetHealth			= funcNewGetHealth
		tFunctionObject.GetMaxHealth		= funcNewGetMaxHealth
		tFunctionObject.GetHealthPercent	= funcNewGetHealthPercent
		tFunctionObject.GetMana				= funcNewGetMana
		tFunctionObject.GetMaxMana			= funcNewGetMaxMana
		tFunctionObject.GetPosition			= funcNewGetPosition
		tFunctionObject.GetMoveSpeed		= funcNewGetMoveSpeed
		tFunctionObject.GetAttackRange		= funcNewGetAttackRange
		
		tFunctionObject.GetHealthVelocity	= funcGetHealthVelocity
	end
	
	StopProfile()
	return tWrapped
end

--[[
function core.UpdateAverageHealthVelocity(tUnit)
	local tPairs = {}
	for nTime, nHealth in pairs(tUnit.tStoredHealths) do
		tinsert(tPairs, {nTime, nHealth})
	end
	
	tsort(tPairs, function(a,b) return a[1] < b[1] end)
	
	local nAverageHealthVelocity = 0
	local nLastTime = nil
	local nLastHealth = nil	
	for i, tPair in ipairs(tPairs) do
		local nTime =	tPair[1]
		local nHealth = tPair[2]
		if nLastTime then
			nAverageHealthVelocity = nAverageHealthVelocity + (((nHealth - nLastHealth) / (nTime - nLastTime)) * 1000)
		end
		nLastTime = nTime
		nLastHealth = nHealth
	end
	tUnit.nAverageHealthVelocity = nAverageHealthVelocity / (#tPairs - 1)
	tUnit.nAverageHealthVelocityTime = tUnit.storedTime	
end
--]]

--[[
core.memoryUnitAverageVelocityTime = 2000
function core.UpdateMemoryPredictedVelocity(memoryUnit)
	local finalTime = HoN.GetGameTime()
	
	local sumVelocity = Vector3.Create()
	
	local currentTime = nil
	local currentPosition = nil
	local bFirstTime = true
	for nextTime, nextPosition in pairs(memoryUnit.storedPositions) do
		if not bFirstTime then
			local deltaTime = nextTime - currentTime
			
			sumVelocity = sumVelocity + (nextPosition - currentPosition) * deltaTime
		end
		
		bFristTime = false
		currentTime = nextTime
		currentPosition = nextPosition
	end	
	
	memoryUnit.predictedVelocityTime = finalTime
	memoryUnit.predictedVelocity = sumVelocity
end
--]]
--[[
function core.DrawMemoryPredictedVelocity(memoryUnit)
	local currentTime = nil
	local currentPosition = nil
	local bFirstTime = true
	for nextTime, nextPosition in pairs(memoryUnit.storedPositions) do
		if not bFirstTime then
			local deltaTime = nextTime - currentTime			
			local curVelocity = (nextPosition - currentPosition)
			
			core.DrawDebugArrow(currentPosition, currentPosition + curVelocity * core.MSToS(deltaTime), 'blue')
		end
		
		core.DrawXPosition(nextPosition, 'teal')
		
		bFristTime = false
		currentTime = nextTime
		currentPosition = nextPosition
	end
	
	local finalPosition = currentPosition
end
--]]

function object:UpdateMemoryUnit(unit)
	if not unit then
		return
	end
	
	if unit.bIsMemoryUnit then
		local nCurrentTime = HoN.GetGameTime()
		
		if core.CanSeeUnit(self, unit) then
			--BotEcho('Updating '..unit:GetTypeName())
			unit.lastStoredPosition	= unit.storedPosition
			unit.lastStoredTime  	= unit.storedTime
			
			unit.storedTime 		= nCurrentTime
			unit.storedHealth 		= unit.object:GetHealth()
			unit.storedMaxHealth 	= unit.object:GetMaxHealth()
			unit.storedMana			= unit.object:GetMana()
			unit.storedMaxMana		= unit.object:GetMaxMana()
			unit.storedPosition		= unit.object:GetPosition()
			unit.storedMoveSpeed	= unit.object:GetMoveSpeed()
			unit.storedAttackRange 	= unit.object:GetAttackRange()
			
			unit.tStoredHealths[nCurrentTime] = unit.storedHealth
		end
		
		unit.debugPositionSent			= false
		
		local nEarliestTime = 99999999	
		local nEarliestHealth = nil
		local tPairs = {}
		local nCutoffTime = nCurrentTime - self.nMemoryUnitHealthIntervalMS
		for nTime, nHealth in pairs(unit.tStoredHealths) do
			if nTime < nCutoffTime then
				--BotEcho(format("%d - %d < %d, removing", nTime, self.nMemoryUnitHealthIntervalMS, nCutoffTime))
				unit.tStoredHealths[nTime] = nil
			else
				if nTime < nEarliestTime then
					nEarliestTime = nTime
					nEarliestHealth = nHealth
				end
			end
		end
		
		if nEarliestHealth then
			unit.nHealthVelocity = ((unit:GetHealth() - nEarliestHealth) / self.nMemoryUnitHealthIntervalMS) * 1000
		end
		
		
		--unit.storedPositions[unit.storedTime] = unit:GetPosition()		
		--self:UpdateMemoryAveragePositions(memoryUnit)
	end
end

object.memoryUnitInterval = 200
object.memoryUnitTimeout = 3500
object.nMemoryUnitsNextUpdate = 0
function object:UpdateAllMemoryUnits()
	local bDebugEchos = false
	local currentTime = HoN.GetGameTime()
	
	if self.nMemoryUnitsNextUpdate > currentTime then
		return
	end
	
	local tMemoryUnits = self.tMemoryUnits
	local nMyTeam = core.myTeam
	
	for id, unit in pairs(tMemoryUnits) do
		if unit.bIsMemoryUnit then		
			self:UpdateMemoryUnit(unit)
			
			local pos, bPredicted = unit:GetPosition()
			local bHaveWaited = unit.storedTime + self.memoryUnitInterval > currentTime --give it a brief moment
			if unit:IsAlive() == false and unit:GetTeam() ~= nMyTeam then --bit hacky
				if bDebugEchos then BotEcho('Removing '..unit:GetTypeName()..' since it is dead') end
				tMemoryUnits[id] = nil			
			elseif bPredicted and bHaveWaited and HoN.CanSeePosition(pos) and not core.CanSeeUnit(self, unit) then
				--we have mispredicted, rm
				if bDebugEchos then BotEcho('Mispredicted position! removing') end
				tMemoryUnits[id] = nil
			elseif unit.storedTime + self.memoryUnitTimeout < currentTime then
				if bDebugEchos then BotEcho('Removing '..unit:GetTypeName()..' since it timedout') end
				tMemoryUnits[id] = nil
			end
		else
			if bDebugEchos then BotEcho('Removing '..(unit and unit:GetTypeName() or '"nil unit"')..' since it is not an actual memory unit') end
			tMemoryUnits[id] = nil --this is not an actual memoryUnit
		end
	end
	
	self.nMemoryUnitsNextUpdate = currentTime + self.memoryUnitInterval
end

function object:AddMemoryUnitsToTable(tInput, nTeamFilter, vecPos, nRadius, fnFilter)
	StartProfile('AddMemoryUnitsToTable')
	
	local bDebugEchos = false
	
	if tInput ~= nil then
		
		local bIgnoreDistance = false
		if vecPos and not nRadius then
			nRadius = nRadius or core.localCreepRange
		elseif not vecPos and not nRadius then
			bIgnoreDistance = true
		end
		
		if bDebugEchos then BotEcho(format("AddMemoryUnitsToTable - nTeamFilter: %s  bIgnoreDistance: %s", tostring(nTeamFilter), tostring(bIgnoreDistance))) end
		
		local tMemoryUnits = self.tMemoryUnits
		local nRadiusSq = (nRadius and nRadius * nRadius) or 0
		for nUID, unit in pairs(tMemoryUnits) do
			if (nTeamFilter == nil or unit:GetTeam() == nTeamFilter) and unit.bIsMemoryUnit then 
				if fnFilter == nil or fnFilter(unit) then
					local nUID = unit:GetUniqueID()
					if bIgnoreDistance or Vector3.Distance2DSq(unit:GetPosition(), vecPos) <= nRadiusSq then
						if bDebugEchos then BotEcho(format("  adding %d: %s", nUID, unit:GetTypeName())) end
						tInput[nUID] = unit
					end
				end
			end
		end
	end
	
	StopProfile()
end


---- Threat + Defense Calculations ----
object.nLethalityCalcInterval = 200

object.tStoredThreats = {}
object.tStoredDefenses = {}

function object:LethalityCalculations()
	bDebugEchos = false
	
	if bDebugEchos then BotEcho("LethalityCalculations()") end
	
	local tAllyHeroes = self.tAllyHeroes
	local tEnemyHeroes = self.tEnemyHeroes
	local tStoredThreats = object.tStoredThreats
	local tStoredDefenses = object.tStoredDefenses
	
	for nUID, unitHero in pairs(tAllyHeroes) do
		tStoredThreats[nUID]  = self.CalculateThreat(unitHero)
		tStoredDefenses[nUID] = self.CalculateDefense(unitHero)
		
		if bDebugEchos then BotEcho(format("%s  threat: %d  defense: %d", unitHero:GetTypeName(), tStoredThreats[nUID], tStoredDefenses[nUID])) end
	end
	
	for nUID, unitHero in pairs(tEnemyHeroes) do
		if core.CanSeeUnit(self, unitHero) then
			tStoredThreats[nUID]  = self.CalculateThreat(unitHero)
			tStoredDefenses[nUID] = self.CalculateDefense(unitHero)
			if bDebugEchos then BotEcho(format("%s  threat: %d  defense: %d", unitHero:GetTypeName(), tStoredThreats[nUID], tStoredDefenses[nUID])) end
		elseif bDebugEchos then
			BotEcho("Not updating "..unitHero:GetTypeName())
		end
	end	
end


function object.CalculateThreat(unitHero)
	local nDPSThreat = object.DPSThreat(unitHero)
	
	local nMoveSpeedThreat = unitHero:GetMoveSpeed() * 0.50
	local nRangeThreat = unitHero:GetAttackRange() * 0.50
	
	local nThreat = nDPSThreat + nMoveSpeedThreat + nRangeThreat -- + nCustomThreat
		
	return nThreat
end

function object.CalculateDefense(unitHero)
	local bDebugEchos = false

	--Health
	local nHealth = unitHero:GetHealth()
	local nMagicReduction = unitHero:GetMagicResistance()
	local nPhysicalReduction = unitHero:GetPhysicalResistance()
	
	--This is obviously not strictly accurate, but this will be effective for our utility calculations
	local nHealthDefense = nHealth + (nHealth * nMagicReduction) + (nHealth * nPhysicalReduction)
	nHealthDefense = nHealthDefense * 1.20
	
	if bDebugEchos then 
		BotEcho(format("HealthDefense: %d  nHealth: %d  nMagicR: %g  nPhysicalR: %g",
			nHealthDefense, nHealth, nMagicReduction, nPhysicalReduction)
		)
	end
	
	--MS and Range
	local nMoveSpeedDefense = unitHero:GetMoveSpeed() * 0.50
	local nRangeDefense = unitHero:GetAttackRange() * 0.50
		
	--local nRegen = unitHero:GetHealthRegen()
	--local nLifesteal = unitHero:GetLifeSteal()
	--local nLifeStealDefense = 0
	--if nLifesteal > 0 then
	--	local nDamage = core.GetFinalAttackDamageAverage(unitHero)
	--	local nAttacksPerSecond = core.GetAttacksPerSecond()
	--	local nDPS = nDamage * nAttacksPerSecond
	--	nLifeStealDefense = nDPS * nLifeSteal
	--end
	--
	--local nSustainabilityDefense = 0
	--
	--local nStayingPowerDefense = 
	--
	--local bStunned = unitHero:IsStunned()
	--local bImmobilized = unitHero:IsImmobilized()
	--
	--local nStunnedUtility = 0
	--local nImmobilizedUtility = 0
	
	local nDefense = nHealthDefense + nMoveSpeedDefense + nRangeDefense -- + other stuffs
	
	return nDefense
end

function object.DPSThreat(unitHero)
	local nDamage = core.GetFinalAttackDamageAverage(unitHero)
	local nAttacksPerSecond = core.GetAttacksPerSecond(unitHero)
	local nDPS = nDamage * nAttacksPerSecond
	
	--BotEcho(format("%s dps: %d  aps: %g  dmg: %d", unitHero:GetTypeName(), nDPS, nAttacksPerSecond, nDamage))
	
	return nDPS * 25
end


function object:GetThreat(unitHero)
	return self.tStoredThreats[unitHero:GetUniqueID()] or 0
end

function object:GetDefense(unitHero)
	return self.tStoredDefenses[unitHero:GetUniqueID()] or 0
end


---- Group-and-push logic ----
--Note: all times in match time
object.nNextPushTime = core.SToMS(core.MinToS(8))
object.nPushInterval = core.SToMS(core.MinToS(5))

object.nPushStartTime = 0
object.unitPushTarget = nil
object.unitRallyBuilding = nil

object.tArrivalEstimatePairs = {}
object.nGroupUpRadius = 800
object.nGroupUpRadiusSq = object.nGroupUpRadius * object.nGroupUpRadius
object.nGroupEstimateMul = 1.5
object.nMaxGroupWaitTime = core.SToMS(25)
object.nGroupWaitTime = nil

function object:GroupAndPushLogic()
	local bDebugEchos = false
	local bDebugLines = false
	
	local nCurrentMatchTime = HoN.GetMatchTime()
	local nCurrentGameTime = HoN.GetGameTime()
	
	if bDebugEchos then BotEcho('GroupAndPushLogic: ') end
	
	if self.nPushState == STATE_IDLE then
		if bDebugEchos then BotEcho(format('IDLE - nCurrentMatchTime: %d  nNextPushTime: %d', nCurrentMatchTime, self.nNextPushTime)) end
		
		if nCurrentMatchTime > self.nNextPushTime then
			--determine target lane
			local nLane = random(3)
			local tLaneUnits = nil
			local tLaneNodes = nil
			
			--put everyone in the target's lane
			self.tTopLane = {}
			self.tBottomLane = {}
			self.tMiddleLane = {}
			if nLane == 1 then
				self.tTopLane = core.CopyTable(self.tAllyHeroes)
				tLaneUnits = self.tTopLane
				tLaneNodes = metadata.GetTopLane()
			elseif nLane == 2 then
				self.tMiddleLane = core.CopyTable(self.tAllyHeroes)
				tLaneUnits = self.tMiddleLane
				tLaneNodes = metadata.GetMiddleLane()
			else
				self.tBottomLane = core.CopyTable(self.tAllyHeroes)
				tLaneUnits = self.tBottomLane
				tLaneNodes = metadata.GetBottomLane()
			end
			
			local unitTarget = core.GetClosestLaneTower(tLaneNodes, core.bTraverseForward, core.enemyTeam)
			if unitTarget == nil then
				unitTarget = core.enemyMainBaseStructure
			end
			self.unitPushTarget = unitTarget
			
			--calculate estimated time to arrive
			local unitRallyBuilding = core.GetFurthestLaneTower(tLaneNodes, core.bTraverseForward, core.myTeam)
			if unitRallyBuilding == nil then
				unitRallyBuilding = core.allyMainBaseStructure
			end		
			self.unitRallyBuilding = unitRallyBuilding
			
			--invalidate our wait timeout
			self.nGroupWaitTime = nil
			
			local vecTargetPos = unitRallyBuilding:GetPosition()
			for key, hero in pairs(tLaneUnits) do
				if hero:IsBotControlled() then
					local nWalkTime = core.TimeToPosition(vecTargetPos, hero:GetPosition(), hero:GetMoveSpeed())
					local nRespawnTime = (not hero:IsAlive() and hero:GetRemainingRespawnTime()) or 0
					local nTotalTime = nWalkTime * self.nGroupEstimateMul + nRespawnTime
					tinsert(self.tArrivalEstimatePairs, {hero, nTotalTime})
				end
			end
			
			if bDebugEchos then 
				BotEcho(format('IDLE - switching!  randLane: %d  target: %s at %s', nLane, unitTarget:GetTypeName(), tostring(unitTarget:GetPosition())))
				BotEcho("ArrivalEstimatePairs:")
				core.printTableTable(self.tArrivalEstimatePairs)
			end
			
			self.nPushStartTime = nCurrentMatchTime
			self.nPushState = STATE_GROUPING
			BotEcho('Grouping up!')
			self.nNextPushTime = self.nNextPushTime + self.nPushInterval
		end
	elseif self.nPushState == STATE_GROUPING then
		if not self.unitRallyBuilding or not self.unitRallyBuilding:IsValid() then
			self.nNextPushTime = nCurrentMatchTime
			self.nPushState = STATE_IDLE
		elseif self.nGroupWaitTime ~= nil and nCurrentGameTime >= self.nGroupWaitTime then
			if bDebugEchos then BotEcho("GROUPING - We've waited long enough... Time to push!") end
			self.nPushState = STATE_PUSHING
		else
			if bDebugEchos then BotEcho('GROUPING - checking if everyone is at the '..self.unitRallyBuilding:GetTypeName()) end
			local bAllHere = true
			local bAnyHere = false
			local vecRallyPosition = self.unitRallyBuilding:GetPosition()
			for key, tPair in pairs(self.tArrivalEstimatePairs) do
				local unit = tPair[1]
				local nTime = tPair[2]
				if not unit or not nTime then 
					BotEcho('GroupAndPushLogic - ERROR - malformed arrival esimate pair!')
				end
				
				if Vector3.Distance2DSq(unit:GetPosition(), vecRallyPosition) > self.nGroupUpRadiusSq then
					if bDebugEchos then BotEcho(format('%s should arrive in less than %ds', unit:GetTypeName(), (self.nPushStartTime + nTime - nCurrentTime)/1000)) end
				
					if nCurrentMatchTime > self.nPushStartTime + nTime then
						self.tArrivalEstimatePairs[key] = nil
						if bDebugEchos then 
							BotEcho(format('GROUPING - dropping %s due to taking too long %d > %d + (%d * %g)', 
								unit:GetTypeName(), nCurrentMatchTime, self.nPushStartTime, nTime, self.nGroupEstimateMul
							))
						end
					else
						bAllHere = false
					end
				else
					bAnyHere = true
					if bDebugEchos then BotEcho(unit:GetTypeName().." has arrived!") end
				end
			end
			
			if bAllHere then
				if bDebugEchos then BotEcho("GROUPING - everyone is here! Time to push!") end
				self.nPushState = STATE_PUSHING
			elseif bAnyHere and self.nGroupWaitTime == nil then
				self.nGroupWaitTime = nCurrentGameTime + self.nMaxGroupWaitTime
			end
		end
	elseif self.nPushState == STATE_PUSHING then
		local bEnd = not self.unitPushTarget:IsAlive()
		if bDebugEchos then BotEcho(format("PUSHING - target: %s  alive: %s", self.unitPushTarget:GetTypeName(), tostring(self.unitPushTarget:IsAlive()))) end
		
		if bEnd == false then
			--if we don't want to end already, see if we have wiped
			local nAllyHeroes = core.NumberElements(self.tAllyHeroes)
			local nHeroesAlive = 0
			for _, hero in pairs(self.tAllyHeroes) do
				if hero:IsAlive() then
					nHeroesAlive = nHeroesAlive + 1
				end
			end
			
			bEnd = nHeroesAlive <= nAllyHeroes / 2
			if bDebugEchos then BotEcho("PUSHING - have wiped: "..tostring(nHeroesAlive <= nAllyHeroes / 2)) end
		end
		
		if bEnd == true then
			BotEcho('Done pushing!')
			if bDebugEchos then BotEcho("PUSHING - done pushing") end
			self:BuildLanes()
			self.nPushState = STATE_IDLE
		end
	end
	
	if bDebugLines then
		if self.unitRallyBuilding then
			core.DrawXPosition(self.unitRallyBuilding:GetPosition(), 'yellow')
		end
		if self.unitPushTarget then
			core.DrawXPosition(self.unitPushTarget:GetPosition(), 'red')
		end
	end
end

function object:GroupUtility()
	local nUtility = 0
	
	if self.nPushState == STATE_GROUPING then
		nUtility = 100
	end
	
	return nUtility
end

function object:PushUtility()
	local nUtility = 0
	
	if self.nPushState == STATE_PUSHING then
		nUtility = 100
	end
	
	return nUtility
end

function object:GetGroupRallyPoint()
	return self.unitRallyBuilding:GetPosition()
end


---- Lane building ----
object.nLaneProximityThreshold = 0.60 --how close you need to be (percentage-wise) to be "in" a lane
function object:BuildLanes()
	local bDebugEchos = false
	
	--[[
	if object.myName == "Team 2" then
		bDebugEchos = true
	end--]]
	
	local tTopLane = {}
	local tMiddleLane = {}
	local tBottomLane = {}
	
	local nBots = core.NumberElements(self.tAllyBotHeroes)
	local tBotsLeft = core.CopyTable(self.tAllyBotHeroes)
	
	--check for players already in lane
	local nHumansInLane = 0
	for _, unitHero in pairs(self.tAllyHumanHeroes) do
		local vecPosition = unitHero:GetPosition()
		if Vector3.Distance2DSq(vecPosition, core.allyWell:GetPosition()) > 1200*1200 then
			local tLaneBreakdown = core.GetLaneBreakdown(unitHero)
			
			if tLaneBreakdown["mid"] >= self.nLaneProximityThreshold then
				tinsert(tMiddleLane, unitHero)
				nHumansInLane = nHumansInLane + 1
			else
				if tLaneBreakdown["top"] >= self.nLaneProximityThreshold  then
					tinsert(tTopLane, unitHero)
					nHumansInLane = nHumansInLane + 1
				elseif tLaneBreakdown["bot"] >= self.nLaneProximityThreshold then
					tinsert(tBottomLane, unitHero)
					nHumansInLane = nHumansInLane + 1
				end
			end			
		end
	end
	
	if bDebugEchos then
		BotEcho('Buildin Lanes!')
		Echo('  Humans:')
		print('    top: ')
		for _, unit in pairs(tTopLane) do
			print(unit:GetTypeName()..' '..tostring(unit))
			print(', ')
		end
		print('\n    mid: ')
		for _, unit in pairs(tMiddleLane) do
			print(unit:GetTypeName()..' '..tostring(unit))
			print(', ')
		end
		print('\n    bot: ')
		for _, unit in pairs(tBottomLane) do
			print(unit:GetTypeName()..' '..tostring(unit))
			print(', ')
		end
		print('\n')
		
		BotEcho(format('nBots: %i, nHumansInLane: %i', nBots, nHumansInLane))
	end
	
	--[[TEST: put particular bots in particular lanes	
	local unitSpecialBot1 = nil
	local unitSpecialBot2 = nil
	local tLane = nil
	local sName1 = nil
	local sName2 = nil
	
	if core.myTeam == HoN.GetLegionTeam() then
		tLane = tTopLane
		sName1 = "Hero_ForsakenArcher"
		sName2 = nil
	else
		tLane = tTopLane
		sName1 = "Hero_Shaman"
		sName2 = "Hero_Chronos"
	end
		
	for key, unit in pairs(self.tAllyBotHeroes) do
		if sName1 and unit:GetTypeName() == sName1 then
			tinsert(tLane, unit)
			unitSpecialBot1 = unit
		elseif sName2 and unit:GetTypeName() == sName2 then
			tinsert(tLane, unit)
			unitSpecialBot2 = unit
		end
	end
	
	for key, unit in pairs(tBotsLeft) do
		if unit == unitSpecialBot1 or unit == unitSpecialBot2 then
			tBotsLeft[key] = nil
			break
		end
	end	
	--/TEST]]	
	
	--Tutorial
	if core.bIsTutorial and core.myTeam == HoN.GetLegionTeam() then
		if bDebugEchos then BotEcho("BuildLanes - Tutorial!") end
		local unitSpecialBot = nil
		local tPlayerLane = nil
		local sName = "Hero_Shaman"
		
		--find the player's lane
		local tLanes = {tTopLane, tMiddleLane, tBottomLane}
		for _, t in pairs(tLanes) do
			if not core.IsTableEmpty(t) then
				if bDebugEchos then BotEcho("Found the player!") end
				tPlayerLane = t
			end
		end			
		
		if tPlayerLane ~= nil then
			for key, unit in pairs(self.tAllyBotHeroes) do
				if sName and unit:GetTypeName() == sName then
					if bDebugEchos then BotEcho("FoundShaman!") end
					tinsert(tPlayerLane, unit)
					unitSpecialBot = unit
				end
			end
			
			for key, unit in pairs(tBotsLeft) do
				if unit == unitSpecialBot then
					tBotsLeft[key] = nil
					break
				end
			end	
		end
	end	
	--/Tutorial
	
	local tExposedLane = nil
	local tSafeLane = nil
	if core.myTeam == HoN.GetLegionTeam() then
		tExposedLane = tTopLane
		tSafeLane = tBottomLane
	else
		tExposedLane = tBottomLane
		tSafeLane = tTopLane
	end
	
	
	--Lane Algorithm
	local nEmptyLanes = core.NumberTablesEmpty(tTopLane, tMiddleLane, tBottomLane)
	local nBotsLeft = core.NumberElements(tBotsLeft)
	
	--fill mid
	if core.NumberElements(tMiddleLane) == 0 and core.NumberElements(tBotsLeft) > 0 then
		local unitBestSolo = self.FindBestLaneSolo(tBotsLeft)
		if unitBestSolo ~= nil then
			core.RemoveByValue(tBotsLeft, unitBestSolo)
			tinsert(tMiddleLane, unitBestSolo)
		end
	end
	
	nEmptyLanes = core.NumberTablesEmpty(tTopLane, tMiddleLane, tBottomLane)	
	nBotsLeft = core.NumberElements(tBotsLeft)
	
	if bDebugEchos then BotEcho('nEmptyLanes: '..nEmptyLanes..'  nBotsLeft: '..nBotsLeft) end
	
	while nBotsLeft > 0 do
		if nBotsLeft > nEmptyLanes then
			--fill a pair, short lane before long lane
			local tLaneToFill = nil
			if core.NumberElements(tExposedLane) < 2 then
				tLaneToFill = tExposedLane
			elseif core.NumberElements(tSafeLane) < 2 then
				tLaneToFill = tSafeLane
			else
				BotEcho('Unable to find a lane to fill with a pair :/')
			end
			
			if tLaneToFill then
				if tLaneToFill[1] and tLaneToFill[2] == nil then
					--1 human
					local unitHuman = tLaneToFill[1]
					local unitBestBot = self.FindBestLaneComplement(unitHuman, tBotsLeft)
					
					if unitBestBot then
						core.RemoveByValue(tBotsLeft, unitBestBot)
						tinsert(tLaneToFill, unitBestBot)
					end
				elseif tLaneToFill[1] == nil and tLaneToFill[2] == nil then
					--lane is empty
					local unitA, unitB = self.FindBestLanePair(tBotsLeft)
					
					if unitA and unitB then
						core.RemoveByValue(tBotsLeft, unitA)
						core.RemoveByValue(tBotsLeft, unitB)
						tinsert(tLaneToFill, unitA)
						tinsert(tLaneToFill, unitB)
					else
						BotEcho('Unable to find a pair of bots to fill a lane pair')
					end
				end
			end
		else
			--fill the remaining lanes with solos.  if we have 2 lanes to fill then fill short then long, else just long lane
			local tLaneToFill = nil
			if nEmptyLanes == 2 then
				tLaneToFill = tExposedLane
			elseif core.NumberElements(tSafeLane) < 1 then
				tLaneToFill = tSafeLane
			elseif core.NumberElements(tExposedLane) < 1 then
				tLaneToFill = tExposedLane
			else
				BotEcho('Unable to find a lane to fill with a solo :/')
			end
			
			if tLaneToFill then
				local unitBestSolo = self.FindBestLaneSolo(tBotsLeft)
				if unitBestSolo ~= nil then
					core.RemoveByValue(tBotsLeft, unitBestSolo)
					tinsert(tLaneToFill, unitBestSolo)
				end
			end
		end
		
		nEmptyLanes = core.NumberTablesEmpty(tTopLane, tMiddleLane, tBottomLane)
		nBotsLeft = core.NumberElements(tBotsLeft)
	end
	
	if bDebugEchos then
		Echo('  Built Lanes:')
		print('    top: ')
		for _, unit in pairs(tTopLane) do
			print(unit:GetTypeName()..' '..tostring(unit))
			print(', ')
		end
		print('\n    mid: ')
		for _, unit in pairs(tMiddleLane) do
			print(unit:GetTypeName()..' '..tostring(unit))
			print(', ')
		end
		print('\n    bot: ')
		for _, unit in pairs(tBottomLane) do
			print(unit:GetTypeName()..' '..tostring(unit))
			print(', ')
		end
		print('\n')
	end
	
	self.tTopLane = tTopLane
	self.tMiddleLane = tMiddleLane
	self.tBottomLane = tBottomLane
end

function object.FindBestLaneComplement(unitInLane, tAvailableHeroes)
	if core.NumberElements(tAvailableHeroes) == 0 then
		return nil
	end
	
	local nLaneUnitRange = unitInLane:GetAttackRange()
	
	local tPairings = {}
	for _, unitHero in pairs(tAvailableHeroes) do
		local nRangeSum = nLaneUnitRange + unitHero:GetAttackRange()
		tinsert(tPairings, {nRangeSum, unitHero})
	end
	
	tsort(tPairings, function(a,b) return a[1] < b[1] end)
	
	local nSmallestRange = (tPairings[1])[1]
	local nLargestRange = (tPairings[core.NumberElements(tPairings)])[1]
	local nSetAverage = (nSmallestRange + nLargestRange) * 0.5
	
	local nSmallestDeviation = 99999
	local nMostAverageSum = 0
	local unitMostAverage = nil
	for _, tPair in pairs(tPairings) do
		local nCurrentDeviation = abs(tPair[1] - nSetAverage) 
		if nCurrentDeviation < nSmallestDeviation or (nCurrentDeviation == nSmallestDeviation and tPair[1] > nMostAverageSum) then
			nSmallestDeviation = nCurrentDeviation
			nMostAverageSum = tPair[1]
			unitMostAverage = tPair[2]
		end
	end
	 
	return unitMostAverage
end

function object.FindBestLanePair(tAvailableHeroes)
	local bDebugEchos = false
	
	--[[
	if object.myName == "Team 2" then
		bDebugEchos = true
	end--]]
	
	if core.NumberElements(tAvailableHeroes) == 0 then
		return nil, nil
	end

	if bDebugEchos then
		BotEcho('FindBestLanePair\ntAvailableHeroes:')
		for key, hero in pairs(tAvailableHeroes) do
			Echo("    "..hero:GetAttackRange().."  "..hero:GetTypeName())
		end
	end
	
	local tPairings = {}
	for _, unitA in pairs(tAvailableHeroes) do
		local bKeepSkipping = true
		for _, unitB in pairs(tAvailableHeroes) do
			if bKeepSkipping and unitA == unitB then
				bKeepSkipping = false
			elseif not bKeepSkipping then
				local nRangeSum = unitA:GetAttackRange() + unitB:GetAttackRange()
				tinsert(tPairings, {nRangeSum, unitA, unitB})
			end
		end
	end
	
	if #tPairings == 0 then
		BotEcho('FindBestLanePair - unable to find pair!')
		return nil, nil
	end
	
	tsort(tPairings, function(a,b) return a[1] < b[1] end)
	
	if bDebugEchos then
		BotEcho('Pairings:')
		for key, tPair in pairs(tPairings) do
			Echo("  "..tPair[1].."  "..tPair[2]:GetTypeName().."  "..tPair[3]:GetTypeName())
		end
	end
	
	local tSmallestPair = tPairings[1]
	local nSmallestRange = tSmallestPair[1]
	
	local tLargestPair = tPairings[#tPairings]
	local nLargestRange = tLargestPair[1]
	
	local nSetAverage = (nSmallestRange + nLargestRange) * 0.5
	
	if bDebugEchos then BotEcho(format("RangeSums - nSmallest: %d  nLargest: %d  nAverage: %d", nSmallestRange, nLargestRange, nSetAverage)) end
	
	local nSmallestDeviation = 99999
	local nMostAverageSum = 0
	local tMostAveragePair = nil
	for _, tPair in pairs(tPairings) do
		local nCurrentDeviation = abs(tPair[1] - nSetAverage)
		if bDebugEchos then BotEcho("Checking "..nCurrentDeviation.." vs "..nSmallestDeviation.." for pair ["..tPair[2]:GetTypeName().."  "..tPair[3]:GetTypeName().."]") end
		if nCurrentDeviation < nSmallestDeviation or (nCurrentDeviation == nSmallestDeviation and tPair[1] > nMostAverageSum) then
			if bDebugEchos then BotEcho("  Better pair!  "..tPair[2]:GetTypeName().." "..tPair[3]:GetTypeName()) end
			nSmallestDeviation = nCurrentDeviation
			nMostAverageSum = tPair[1]
			tMostAveragePair = {tPair[2], tPair[3]}
		end
	end
	
	if tMostAveragePair ~= nil then
		return tMostAveragePair[1], tMostAveragePair[2]
	end
	
	BotEcho('FindBestLanePair - unable to find pair!')
	return nil, nil
end

function object.FindBestLaneSolo(tAvailableHeroes)
	if core.NumberElements(tAvailableHeroes) == 0 then
		return nil, nil
	end

	local nLargestRange = 0
	local unitBestUnit = nil
	for _, unit in pairs(tAvailableHeroes) do
		local nCurrentRange = unit:GetAttackRange() 
		if nCurrentRange > nLargestRange then
			nLargestRange = nCurrentRange
			unitBestUnit = unit
		end
	end
	
	return unitBestUnit
end

function object:GetDesiredLane(unitAsking)
	--BotEcho(tostring(unitAsking)..' '..unitAsking:GetTypeName()..' asking for a lane!')
	
	if unitAsking.object then
		BotEcho("Was passed a memory unit: "..unitAsking:GetTypeName())
	elseif type(unitAsking) == "table" then
		BotEcho("Was passed a weird table in unit: "..(unitAsking:GetTypeName() or "Unamed because it's a table"))
	end
	
	for _, unit in pairs(self.tTopLane) do
		if unit == unitAsking then
			return metadata.GetTopLane()
		end
	end
	
	for _, unit in pairs(self.tMiddleLane) do
		if unit == unitAsking then
			return metadata.GetMiddleLane()
		end
	end
	
	for _, unit in pairs(self.tBottomLane) do
		if unit == unitAsking then
			return metadata.GetBottomLane()
		end
	end
	
	if unitAsking then
		BotEcho("Couldn't find a lane for unit: "..tostring(unitAsking)..'  name: '..unitAsking:GetTypeName())	
	else
		BotEcho("Couldn't find a lane for unit: nil")
	end
	
	self.teamBotBrainInitialized = false
	
	return nil
end





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

BotEcho('Finished loading teambotbrain')

