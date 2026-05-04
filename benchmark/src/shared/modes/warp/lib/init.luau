--!strict
--@EternityDev
local Remote = {}

if game.RunService:IsServer() then
	if not script:FindFirstChild("_repl") then
		Instance.new("RemoteEvent", script).Name = "_repl"
	end
	if not script:FindFirstChild("Event") then
		Instance.new("RemoteEvent", script).Name = "Event"
	end
	if not script:FindFirstChild("UnreliableEvent") then
		Instance.new("UnreliableRemoteEvent", script).Name = "UnreliableEvent"
	end
end

local Buffer = require(script.Util.Buffer)
local Client = require(script.Client)
local Server = require(script.Server)

--[[
	@class Remote
	@client
]]
Remote.Client = function()
	return Client
end

--[[
	@class Remote
	@server
]]
Remote.Server = function()
	return Server
end

--[[
	@class Remote
	@schema
	define a schema for your data and use a strict packing
]]
Remote.Buffer = Buffer

return Remote :: typeof(Remote)
