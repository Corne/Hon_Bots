--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]

local _G = getfenv(0)
local object = _G.object

object.SporeBreath = object.SporeBreath or {}
local SporeBreath = object.SporeBreath

local core, behaviorLib = object.core, object.behaviorLib;
SporeBreath.bShouldUse = false;

local function SetUseSporeBreath(unitTarget)
    local unitSelf = core.unitSelf

    local vecMyPosition = unitSelf:GetPosition()
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
    nAttackRangeSq = nAttackRangeSq * nAttackRangeSq
    local nMyExtraRange = core.GetExtraRange(unitSelf)

    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetExtraRange = core.GetExtraRange(unitTarget)
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
    

        
    local sporebreath = core.unitSelf:GetAbility(0);
    core.BotEcho('nTargetDistanceSq: ' .. nTargetDistanceSq)
    if(sporebreath:CanActivate()) then
        local nRange = 500
        if nTargetDistanceSq < (nRange * nRange) then
            SporeBreath.bShouldUse = true;
            return
        end
    end
    SporeBreath.bShouldUse = false;
end

--DEPRECATED
local function ShouldBeAggresive( unitTarget )
    return((unitTarget:GetHealth() / unitTarget:GetMaxHealth()) <=
        (core.unitSelf:GetHealth() / core.unitSelf:GetMaxHealth()));

end

--test set-up for spore breath
--TODO move to BRAMBLE COMBAT
local function CustomHarassUtilityFnOverride(unitTarget)    
    SetUseSporeBreath(unitTarget)
    --[[if(ShouldBeAggresive(unitTarget)) then
        return 100;
    end
    return 0;--]]
    nHarrassUtil = math.floor((core.unitSelf:GetHealth() / core.unitSelf:GetMaxHealth()) / (unitTarget:GetHealth() / unitTarget:GetMaxHealth()) ) *25;
    core.BotEcho('HarrasUtil: ' .. nHarrassUtil)
    return nHarrassUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride  

--TODO move to BRAMBLE COMBAT
local function HarassHeroExecuteOverride(botBrain)
    
    if(SporeBreath.bShouldUse) then
        local sporebreath = core.unitSelf:GetAbility(0);
        core.OrderAbility(botBrain, sporebreath, true, true)
        SporeBreath.bShouldUse = false;
    end
    object.harassExecuteOld(botBrain)
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride