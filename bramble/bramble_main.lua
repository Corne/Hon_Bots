local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()
 
object.bRunLogic         = true
object.bRunBehaviors    = true
object.bUpdates         = true
object.bUseShop         = true
 
object.bRunCommands     = true
object.bMoveCommands     = true
object.bAttackCommands     = true
object.bAbilityCommands = true
object.bOtherCommands     = true
 
object.bReportBehavior = false
object.bDebugUtility = false
 
object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false
 
object.core         = {}
object.eventsLib     = {}
object.metadata     = {}
object.behaviorLib     = {}
object.skills         = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills =
    object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog

FILEPATH = "bots/bramble/"
SKILLSFILEPATH = FILEPATH .. "skills/"

BotEcho('loading bramble_main...')

object.heroName = 'Hero_Plant'


runfile (FILEPATH .. "bramble_items.lua")
local brambleItems = object.bramble_items
brambleItems.SetDefaultItems()

runfile (FILEPATH .. "bramble_combat.lua")
local brambleSkills = object.bramble_skills


BotEcho('done loading bramble_main...')
