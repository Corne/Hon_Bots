local _G = getfenv(0)
local object = _G.object
 
object.standarditembuilds = object.standarditembuilds or {}
local standarditembuilds = object.standarditembuilds

--[[
File with some default item builds

*t is table see howto.txt

Every build has a Letter that identifies the game phase:
S - StartItems
L - LaningItems
M - MidGameItems
E - EndGameItems
--]]

--default combinations
local tRegen2Totem = {"Item_HealthPotion", "2 Item_MinorTotem", "Item_RunesOfTheBlight"}

--starter items
standarditembuilds.tSMeleeCarry = {"Item_LoggersHatchet", "Item_IronBuckler", "Item_RunesOfTheBlight"}
standarditembuilds.tStartLongLaneSupport = {"Item_FlamingEye", "Item_FlamingEye", tRegen2Totem, "Item_ManaPotion", "Item_ManaPotion"}

--lane items
standarditembuilds.tLMeleeCarry = {"Item_Marchers", "Item_Lifetube"}

--Midgame items
standarditembuilds.tMTank = {"Item_EnhancedMarchers", "Item_Shield2", "Item_MagicArmor2"}

--Endgame items
standarditembuilds.tETank = {"Item_DaemonicBreastplate", "Item_BarrierIdol", "Item_BehemothsHeart"}
