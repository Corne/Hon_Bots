local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic 	= true
object.bRunBehaviors    = true
object.bUpdates 	= true
object.bUseShop 	= true

object.bRunCommands 	= true 
object.bMoveCommands 	= true
object.bAttackCommands 	= true
object.bAbilityCommands = true
object.bOtherCommands 	= true

object.bReportBehavior  = false
object.bDebugUtility    = false
object.bDebugExecute    = false

object.logger = {}
object.logger.bWriteLog     = false
object.logger.bVerboseLog   = false

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

local core = object.core
local BotEcho= core.BotEcho

BotEcho('loading predator_main...')

object.heroName = 'Hero_Plant'