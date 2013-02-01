local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()
object.logger = {}

object.bRunLogic 		= true
object.bRunBehaviors	= true
object.bUpdates 		= true
object.bUseShop 		= true

object.bRunCommands 	= true
object.bMoveCommands 	= true
object.bAttackCommands 	= true
object.bAbilityCommands = true
object.bOtherCommands 	= true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false

object.core 		= {}
object.eventsLib 	= {}
object.metadata 	= {}
object.behaviorLib 	= {}
object.skills 		= {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills
local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random


BotEcho('loading bramble_main...')

object.heroName = 'Hero_Plant'

runfile "bots/util/standarditembuilds.lua"
standarditembuilds = {}
local standarditembuilds = object.standarditembuilds 

behaviorLib.StartingItems = {"Item_Hatchet", "Item_IronBuckler", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = {"Item_Hatchet", "Item_IronBuckler", "Item_RunesOfTheBlight"}
behaviorLib.MidItems = {"Item_Sicarius", "Item_Immunity", "Item_ManaBurn2"} --Item_Sicarius is Firebrand, ManaBurn2 is Geomenter's Bane, Immunity is Shrunken Head
behaviorLib.LateItems = {"Item_Weapon3", "Item_Sicarius", "Item_ManaBurn2", "Item_BehemothsHeart", "Item_Damage9" } --Weapon3 is Savage Mace. Item_Damage9 is Doombringer





