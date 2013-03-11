--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]

local _G = getfenv(0)
local object = _G.object

object.VineWall = object.VineWall or {}
local VineWall = object.VineWall

local core, behaviorLib = object.core, object.behaviorLib;
VineWall.bShouldActivate = false;

local vecTarget; --kinda dirty, but API is dirty, so can't help it.

function VineWall.SetUseVineWall( unitTarget )
	local abilVineWall = core.unitSelf:GetAbility(3);
	VineWall.bShouldActivate = abilVineWall:CanActivate(); -- add more conditions

	local vecMyPosition = core.unitSelf:GetPosition()
	local vecTargetPosition = unitTarget:GetPosition()

	vecTarget = vecTargetPosition;
end

function VineWall.Activate( botbrain )
	local abilVineWall = core.unitSelf:GetAbility(3);
	core.OrderAbilityPosition(botbrain, abilVineWall, vecTarget)
	VineWall.bShouldActivate = false;
end
