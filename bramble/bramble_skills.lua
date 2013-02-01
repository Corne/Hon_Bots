--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]

local _G = getfenv(0)
local object = _G.object

object.bramble_skills = object.bramble_skills or {}
local bramble_skills = object.bramble_skills

local skills = object.skills

runfile"bots/util/botmethods.lua"
botmethods = object.botmethods
botmethods.setSkillBuild(      
                    {0, 2, 0, 1, 0, 3,
                     0, 1, 1, 1, 3, 2,
                     2, 2, 4, 3})