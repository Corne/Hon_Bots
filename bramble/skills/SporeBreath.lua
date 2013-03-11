--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]

local _G = getfenv(0)
local object = _G.object

object.SporeBreath = object.SporeBreath or {}
local SporeBreath = object.SporeBreath

local core, behaviorLib = object.core, object.behaviorLib;
SporeBreath.bShouldActivate = false;

function SporeBreath.SetUseSporeBreath(unitTarget)
    local unitSelf = core.unitSelf

    local vecMyPosition = unitSelf:GetPosition()
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetDistanceSq = Vector3.Distance2DSq(vecTargetPosition, vecMyPosition)

        
    local abilSporebreath = core.unitSelf:GetAbility(0);
    core.BotEcho('nTargetDistanceSq: ' .. nTargetDistanceSq)
    local nRange = 500

    SporeBreath.bShouldActivate = abilSporebreath:CanActivate() and nTargetDistanceSq < (nRange * nRange);

end

function SporeBreath.Activate( botbrain )
    local abilSporebreath = core.unitSelf:GetAbility(0);
    core.OrderAbility(botbrain, abilSporebreath, true, true)
    SporeBreath.bShouldActivate = false;
end