module(..., package.seeall);

local _G = getfenv(0)
local object = _G.object
 
object.myName = object:GetName()

--File with some default item builds
standarditembuilds.tRegen2Totem = {"Item_HealthPotion", "Item_MinorTotem", "Item_MinorTotem", "Item_RunesOfTheBlight"}

tDefaultCarry = {"Item_Hatchet", "Item_IronBuckler", "Item_RunesOfTheBlight"}
tLongLaneSupport = {"Item_FlamingEye", "Item_FlamingEye", tRegen2Totem, "Item_ManaPotion", "Item_ManaPotion"}