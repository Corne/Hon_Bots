--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]
--[[

    File that includes the skill logic for Bramble

    Bramble's skills: 
    Q - Spore Breath
    W - Ensnaring Shrubbery
    E - Combat Vigor
    R - Entangling Vine Wall
--]]

local _G = getfenv(0)
local object = _G.object

object.bramble_skills = object.bramble_skills or {}
local bramble_skills = object.bramble_skills

local skills, core = object.skills, object.core


-- set skillbuild
runfile"bots/util/botmethods.lua"
object.botmethods.SetSkillBuild(      
                    {0, 2, 0, 1, 0, 3,
                     0, 1, 1, 1, 3, 2,
                     2, 2, 4, 3})

--TODO: bind skills!

runfile "bots/bramble/bramble_combat.lua"
