--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]

local _G = getfenv(0)
local object = _G.object

object.bramble_combat = object.bramble_combat or {}
local bramble_combat = object.bramble_combat

local function ShouldUseSporeBreath()

end

local function ShouldUseEnsnaringShrubbery(damageTaken)
    object.core.BotEcho('TEst 2');
    if (damageTaken > (object.core.unitSelf:GetMaxHealth()*0.01)) and object.skills.ensnaringShrubbery:CanActivate() then
        object.core.BotEcho('ENSNARING SKILL');
        return true
    end
    return false
end

runfile("bots/util/CombatEvents.lua")
local function OnDamageTakenOverride(damage, sourceUnit)

    local unitself = object.core.unitSelf
    object.skills.ensnaringShrubbery = unitself:GetAbility(1)
    object.core.BotEcho('TEst');
    if ShouldUseEnsnaringShrubbery(damage) then
        object.core.BotEcho('TEst 3');  
        object.core.OrderAbilityEntity(unitself, object.skills.ensnaringShrubbery, unitself)
    end
 
end
object.CombatEvents.OnDamageTaken = OnDamageTakenOverride