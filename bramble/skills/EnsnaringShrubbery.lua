--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]

local _G = getfenv(0)
local object = _G.object

object.EnsnaringShrubbery = object.EnsnaringShrubbery or {}
local EnsnaringShrubbery = object.EnsnaringShrubbery

local core, behaviorLib = object.core, object.behaviorLib;
EnsnaringShrubbery.bShouldUse = false;


local function SetUseEnsnaringShrubbery(damageTaken)
    local ensnaring = core.unitSelf:GetAbility(1)
    if (damageTaken > (core.unitSelf:GetMaxHealth()*0.1)) and ensnaring:CanActivate() then
        EnsnaringShrubbery.bShouldUse = true
        return;
    end
    EnsnaringShrubbery.bShouldUse = false
end

runfile("bots/util/CombatEvents.lua")
local function OnDamageTakenOverride(damage, sourceUnit)
    SetUseEnsnaringShrubbery(damage) 
end
object.CombatEvents.OnDamageTaken = OnDamageTakenOverride


function behaviorLib.DefenceSkillUtility(botBrain)
    if(EnsnaringShrubbery.bShouldUse) then
        return 100;
    end
    return 0;
end

function behaviorLib.DefenceSkillExecute(botBrain)
    local ensnaring = core.unitSelf:GetAbility(1)
    if(EnsnaringShrubbery.bShouldUse) then
        core.OrderAbilityEntity(botBrain, ensnaring, core.unitSelf);
        EnsnaringShrubbery.bShouldUse = false;
        return;
    end
end

behaviorLib.DefenceSkillBehavior = {}
behaviorLib.DefenceSkillBehavior["Utility"] = behaviorLib.DefenceSkillUtility
behaviorLib.DefenceSkillBehavior["Execute"] = behaviorLib.DefenceSkillExecute
behaviorLib.DefenceSkillBehavior["Name"] = "DefenceSkill"
_G.table.insert(behaviorLib.tBehaviors, behaviorLib.DefenceSkillBehavior)