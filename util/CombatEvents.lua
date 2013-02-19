--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]

local _G = getfenv(0)
local object = _G.object

object.CombatEvents = object.CombatEvents or {}

local CombatEvents = object.CombatEvents

--Override OnThink to add combatevents
function object:OnCombatEvent(EventData)
    self:OnCombatEventOld(EventData)

    if(EventData.Type == 'Damage') then
        --object.core.BotEcho(EventData.Type)
        CombatEvents.OnDamageTaken(EventData.DamageApplied, EventData.SourceUnit)
    end
end
object.OnCombatEventOld = object.oncombatevent
object.oncombatevent 	= object.OnCombatEvent


function CombatEvents.OnDamageTaken(damage, sourceUnit)
    --Override this methods for events on damagetaken
end

