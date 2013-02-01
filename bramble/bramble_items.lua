local _G = getfenv(0)
local object = _G.object

object.bramble_items = object.bramble_items or {}
local bramble_items = object.bramble_items

runfile "bots/util/standarditembuilds.lua"
standarditembuilds = {}
local standarditembuilds = object.standarditembuilds 


-- At the moment 1 default build for Bramble, can get more later on
function bramble_items.SetDefaultItems(behaviorLib)
    behaviorLib.StartingItems = standarditembuilds.tSDefaultMeleeCarry
    behaviorLib.LaneItems = standarditembuilds.tLDefaultMeleeCarry
    behaviorLib.MidItems = standarditembuilds.tMTank
    behaviorLib.LateItems = standarditembuilds.tETank
end