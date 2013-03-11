--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
]]
--[[

    File that includes the combat logic for Bramble

    Bramble's skills: 
    Q - Spore Breath
    W - Ensnaring Shrubbery
    E - Combat Vigor
    R - Entangling Vine Wall
--]]

local _G = getfenv(0)
local object = _G.object

object.bramble_combat = object.bramble_combat or {}
local bramble_combat = object.bramble_combat

local skills, core, behaviorLib = object.skills, object.core, object.behaviorLib


-- set skillbuild
runfile"bots/util/botmethods.lua"
object.botmethods.SetSkillBuild(      
                    {0, 2, 0, 1, 0, 3,
                     0, 1, 1, 1, 3, 2,
                     2, 2, 4, 3})

runfile(SKILLSFILEPATH .. "EnsnaringShrubbery.lua");
local ensnaringShrubbery = object.EnsnaringShrubbery;

runfile(SKILLSFILEPATH .. "SporeBreath.lua");
local sporeBreath = object.SporeBreath;

runfile(SKILLSFILEPATH .. "VineWall.lua");
local vineWall = object.VineWall;

--test set-up for spore breath
local function CustomHarassUtilityFnOverride(unitTarget)    
    sporeBreath.SetUseSporeBreath(unitTarget)
    --really defensive atm, need to be more aggresive, in some cases
    nHarrassUtil = nHarrassUtil * 0.3; -- save some old aggresivnes
    nHarrassUtil = nHarrassUtil + math.floor((core.unitSelf:GetHealth() / core.unitSelf:GetMaxHealth()) / (unitTarget:GetHealth() / unitTarget:GetMaxHealth()) ) *25;
    core.BotEcho('nHarrassUtil' .. nHarrassUtil)
    ensnaringShrubbery.SetAgressiveEnsnaringShrubbery(nHarrassUtil)

    vineWall.SetUseVineWall(unitTarget)
    return nHarrassUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride  


local function HarassHeroExecuteOverride(botBrain)
    core.BotEcho('HELLO' )
    --core.BotEcho( vineWall.bShouldActivate)
    if(sporeBreath.bShouldActivate) then
        sporeBreath.Activate(botBrain)    
    elseif(ensnaringShrubbery.bShouldActivate) then
    	ensnaringShrubbery.Activate( botBrain , core.unitSelf )
    elseif(vineWall.bShouldActivate) then
        core.BotEcho('HELLO 2' )
        vineWall.Activate(botBrain);
    else
        object.harassExecuteOld(botBrain)
    end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride