--[[
    Lua 5.1 Copyright (C) 1994-2006 Lua.org, PUC-Rio
--]]

--[[
    Author: Corné
    File for (currently) missing bot methods
--]]
local _G = getfenv(0)
local object = _G.object

object.botmethods = object.botmethods or {}
local botmethods = object.botmethods

--[[
Method for setting a static skillbuild

Missing values will be amplified with stats

example:
botmethods.setSkillBuild(      
            {0, 2, 0, 1, 0, 3,
             0, 1, 1, 1, 3, 2,
             2, 2, 4, 3})
--]]
function botmethods.setSkillBuild(tSkills)    
    --set the skillbuild for botbraincore
    function object:SkillBuild()
        local unitSelf = self.core.unitSelf
        
        if unitSelf:GetAbilityPointsAvailable() <= 0 then
            return
	end
        
        nNextSkill = tSkills[unitSelf:GetLevel()]
        if nNextSkill == nil then nNextSkill = 4 end
        unitSelf:GetAbility(nNextSkill):LevelUp()
    end
end