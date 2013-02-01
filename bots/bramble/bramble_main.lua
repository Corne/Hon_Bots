local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()
object.logger = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

core, behavior = {}
local core, behavior = object.core, object.behaviorLib
local BotEcho= core.BotEcho

BotEcho('loading bramble_main...')

object.heroName = 'Hero_Plant'

--[[
runfile "bots/core.lua" --works
runfile "bots/util/standarditembuilds.lua" --fails
require "bots/core.lua" --works
require "bots/util/standarditembuilds.lua" --fails
--]]

require"/Hon_bots/bots/util/standarditembuilds.lua"
standarditembuilds = standarditembuilds
--BotEcho(standarditembuilds.tRegen2Totem)



