--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]

local _G = getfenv(0)
local object = _G.object

object.EnsnaringShrubbery = object.EnsnaringShrubbery or {}
local EnsnaringShrubbery = object.EnsnaringShrubbery

local core, behaviorLib = object.core, object.behaviorLib;
EnsnaringShrubbery.bShouldActivate = false;


function EnsnaringShrubbery.SetAgressiveEnsnaringShrubbery( harassUtil )
    local ensnaring = core.unitSelf:GetAbility(1)
    EnsnaringShrubbery.bShouldActivate = (harassUtil >= 75) and ensnaring:CanActivate();
end

local function SetDefenceEnsnaringShrubbery(damageTaken)
    local ensnaring = core.unitSelf:GetAbility(1)
    if (damageTaken > (core.unitSelf:GetMaxHealth()*0.1)) and ensnaring:CanActivate() then
        EnsnaringShrubbery.bShouldActivate = true
        return;
    end
end

runfile("bots/util/CombatEvents.lua")
local function OnDamageTakenOverride(damage, sourceUnit)
    SetDefenceEnsnaringShrubbery(damage) 
end
object.CombatEvents.OnDamageTaken = OnDamageTakenOverride


function behaviorLib.DefenceSkillUtility(botBrain)
    if(EnsnaringShrubbery.bShouldActivate) then
        return 100;
    end
    return 0;
end

-- TODO only uses skill on himself atm, should use on other heroes aswell.
function behaviorLib.DefenceSkillExecute(botBrain)
    if(EnsnaringShrubbery.bShouldActivate) then
        EnsnaringShrubbery.Activate( botBrain, core.unitSelf )
    end
end

function EnsnaringShrubbery.Activate( botBrain , unit)
    local ensnaring = core.unitSelf:GetAbility(1)
    core.OrderAbilityEntity(botBrain, ensnaring, unit);
    EnsnaringShrubbery.bShouldActivate = false;
end

behaviorLib.DefenceSkillBehavior = {}
behaviorLib.DefenceSkillBehavior["Utility"] = behaviorLib.DefenceSkillUtility
behaviorLib.DefenceSkillBehavior["Execute"] = behaviorLib.DefenceSkillExecute
behaviorLib.DefenceSkillBehavior["Name"] = "DefenceSkill"
_G.table.insert(behaviorLib.tBehaviors, behaviorLib.DefenceSkillBehavior)