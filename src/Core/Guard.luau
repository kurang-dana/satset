-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Guard — server-side token bucket rate limiter for DDoS protection.

local RunService = game:GetService("RunService")

-- [ Constants ]

local IS_STUDIO = RunService:IsStudio()

-- [ Types ]

export type GuardConfig = {
	maxTokens: number, -- Max burst capacity (how many packets can be sent at once)
	refillRate: number, -- Tokens refilled per second
	onFlood: ((player: Player) -> ())?, -- Optional callback for when a player is flooding
	studioBypass: boolean?, -- If true, rate limiting is disabled in Studio (Default: true)
}

type PlayerBucket = {
	tokens: number,
	lastRefill: number,
}

-- We define the Guard type explicitly for better type checking in methods.
export type Guard = {
	consume: (self: Guard, player: Player) -> boolean,
	removePlayer: (self: Guard, player: Player) -> (),
	_getBucket: (self: Guard, player: Player) -> PlayerBucket,
	_maxTokens: number,
	_refillRate: number,
	_onFlood: ((player: Player) -> ())?,
	_buckets: { [Player]: PlayerBucket },
}

-- [ Private Constants ]

local DEFAULT_CONFIG: GuardConfig = {
	maxTokens = 1000,
	refillRate = 500,
	onFlood = nil,
	studioBypass = true,
}

-- [ Public API ]

local Guard = {}
Guard.__index = Guard

--[[
	Creates a new Guard instance. 
	
	The guard implements a token bucket algorithm to prevent players from 
	spamming the server. If a player exceeds the maxTokens, their packets 
	will be dropped until the bucket refills.
]]
function Guard.new(config: GuardConfig?): Guard
	local self = setmetatable({}, Guard)

	local cfg = config or DEFAULT_CONFIG
	self._maxTokens = math.max(cfg.maxTokens or DEFAULT_CONFIG.maxTokens, 1)
	self._refillRate = math.max(cfg.refillRate or DEFAULT_CONFIG.refillRate, 1)
	self._onFlood = cfg.onFlood
	self._studioBypass = if cfg.studioBypass ~= nil then cfg.studioBypass else DEFAULT_CONFIG.studioBypass
	self._buckets = {} :: { [Player]: PlayerBucket }

	return (self :: any) :: Guard
end

--[[
	Consumes a token for the given player. 
	
	Returns true if the request is within the rate limit, or false if 
	the player is flooding.
]]
function Guard:consume(player: Player): boolean
	-- Bypass rate limiting in Studio if enabled.
	if IS_STUDIO and self._studioBypass then
		return true
	end

	local bucket: PlayerBucket = self:_getBucket(player)
	local now = os.clock()
	local elapsed = now - bucket.lastRefill

	-- Refill tokens based on elapsed time.
	bucket.tokens = math.min(self._maxTokens, bucket.tokens + elapsed * self._refillRate)
	bucket.lastRefill = now

	-- Check if we have enough tokens to allow this request.
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end

	-- Trigger the flood callback if it exists.
	if self._onFlood then
		self._onFlood(player)
	end

	return false
end

--[[
	Cleans up the bucket for a player when they disconnect.
]]
function Guard:removePlayer(player: Player)
	self._buckets[player] = nil
end

-- [ Private Logic ]

function Guard:_getBucket(player: Player): PlayerBucket
	local bucket = self._buckets[player]
	if not bucket then
		bucket = {
			tokens = self._maxTokens,
			lastRefill = os.clock(),
		}
		self._buckets[player] = bucket
	end
	return bucket
end

return Guard
