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

--test set-up for spore breath
--TODO move to BRAMBLE COMBAT
local function CustomHarassUtilityFnOverride(unitTarget)    
    sporeBreath.SetUseSporeBreath(unitTarget)

    nHarrassUtil = math.floor((core.unitSelf:GetHealth() / core.unitSelf:GetMaxHealth()) / (unitTarget:GetHealth() / unitTarget:GetMaxHealth()) ) *25;
    core.BotEcho('HarrasUtil: ' .. nHarrassUtil)
    ensnaringShrubbery.SetAgressiveEnsnaringShrubbery(nHarrassUtil)
    return nHarrassUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride  


local function HarassHeroExecuteOverride(botBrain)
    
    if(sporeBreath.bShouldUse) then
        local abilSporebreath = core.unitSelf:GetAbility(0);
        core.OrderAbility(botBrain, abilSporebreath, true, true)
        sporeBreath.bShouldUse = false;
    end
    if(ensnaringShrubbery.bShouldUse) then
    	EnsnaringShrubbery.Activate( botBrain )
    end
    object.harassExecuteOld(botBrain)
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride