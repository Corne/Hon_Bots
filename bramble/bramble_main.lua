local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()
object.logger = {}

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

local core, eventsLib, behaviorLib, metadata, skills =
    object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog

BotEcho('loading bramble_main...')

object.heroName = 'Hero_Plant'

BotEcho('Setting items')
runfile "bots/bramble/bramble_items.lua"
local brambleItems = object.bramble_items
brambleItems.SetDefaultItems()
BotEcho('Items set')

BotEcho('Setting skill build')
runfile "bots/bramble/bramble_skills.lua"
BotEcho('skill build set')

BotEcho('done loading bramble_main...')