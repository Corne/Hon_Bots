local _G = getfenv(0)
local object = _G.object
 
object.standarditembuilds = object.standarditembuilds or {}
local standarditembuilds = object.standarditembuilds

--File with some default item builds

--default combinations
local tRegen2Totem = {"Item_HealthPotion", "2 Item_MinorTotem", "Item_RunesOfTheBlight"}

--item builds
standarditembuilds.tDefaultCarry = {"Item_Hatchet", "Item_IronBuckler", "Item_RunesOfTheBlight"}
standarditembuilds.tLongLaneSupport = {"Item_FlamingEye", "Item_FlamingEye", tRegen2Totem, "Item_ManaPotion", "Item_ManaPotion"}