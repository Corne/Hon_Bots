--This file will include Bramble's item/shop logic

local _G = getfenv(0)
local object = _G.object

object.bramble_items = object.bramble_items or {}
local bramble_items = object.bramble_items

runfile "bots/util/standarditembuilds.lua"
standarditembuilds = {}
local standarditembuilds = object.standarditembuilds 
local behaviorLib = object.behaviorLib

-- At the moment 1 default build for Bramble, can get more later on
function bramble_items.SetDefaultItems()
    behaviorLib.StartingItems = standarditembuilds.tSMeleeCarry
    behaviorLib.LaneItems = standarditembuilds.tLMeleeCarry
    behaviorLib.MidItems = standarditembuilds.tMTank
    behaviorLib.LateItems = standarditembuilds.tETank
end