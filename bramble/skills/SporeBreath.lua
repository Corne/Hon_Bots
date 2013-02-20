--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]

local _G = getfenv(0)
local object = _G.object

object.SporeBreath = object.SporeBreath or {}
local SporeBreath = object.SporeBreath

local core, behaviorLib = object.core, object.behaviorLib;
SporeBreath.bShouldUse = false;

function SporeBreath.SetUseSporeBreath(unitTarget)
    local unitSelf = core.unitSelf

    local vecMyPosition = unitSelf:GetPosition()
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)

        
    local abilSporebreath = core.unitSelf:GetAbility(0);
    core.BotEcho('nTargetDistanceSq: ' .. nTargetDistanceSq)
    local nRange = 300

    SporeBreath.bShouldUse = abilSporebreath:CanActivate() and nTargetDistanceSq < (nRange * nRange);

end

