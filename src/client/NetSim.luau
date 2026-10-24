--!strict
-- Simulated network conditions for this client: extra latency each way,
-- jitter and packet loss (set in the Hit Reg Lab, F2 third page), so lag
-- compensation can be tried at any ping in Studio, where the real ping is
-- close to zero.
--
-- Gameplay traffic goes through here: inputs out; snapshots, acks, shot
-- verdicts, tracers and combat events in. Reliable remotes keep their order
-- and never drop, like Roblox's reliable channel; unreliable ones can arrive
-- out of order or not at all. Only this client is affected: to the server it
-- looks like a player with a worse connection, and lag compensation's cap
-- applies to it like anyone else.

local RunService = game:GetService("RunService")

local NetSim = {}

NetSim.settings = {
	latency = 0, -- seconds added each way
	jitter = 0, -- up to this many seconds more, at random, per message
	loss = 0, -- share of unreliable messages dropped, each way
}
NetSim.stats = { delayed = 0, dropped = 0 }

type Pending = { at: number, order: number, deliver: () -> () }

local pending: { Pending } = {}
local order = 0
local lastReliable = { incoming = 0, outgoing = 0 }
local random = Random.new()
local handlers: { [Instance]: { (...any) -> () } } = {}

function NetSim.active(): boolean
	local s = NetSim.settings
	return s.latency > 0 or s.jitter > 0 or s.loss > 0
end

-- Queues `deliver` for later, or returns false if the message is lost. Once
-- anything is queued, everything goes through the queue until it drains, so
-- turning the simulation off never lets a reliable message overtake one.
local function route(reliable: boolean, direction: "incoming" | "outgoing", deliver: () -> ()): boolean
	if not NetSim.active() and #pending == 0 then
		return false
	end
	local s = NetSim.settings
	if not reliable and s.loss > 0 and random:NextNumber() < s.loss then
		NetSim.stats.dropped += 1
		return true
	end
	local at = os.clock() + s.latency + random:NextNumber() * s.jitter
	if reliable then
		at = math.max(at, lastReliable[direction])
		lastReliable[direction] = at
	end
	order += 1
	table.insert(pending, { at = at, order = order, deliver = deliver })
	NetSim.stats.delayed += 1
	return true
end

-- Connects a handler to a server-to-client remote. Every handler of a remote
-- gets each message at the same moment, or none of them does.
function NetSim.on(remote: Instance, handler: (...any) -> ())
	local list = handlers[remote]
	if not list then
		local fresh: { (...any) -> () } = {}
		list = fresh
		handlers[remote] = fresh
		local reliable = not remote:IsA("UnreliableRemoteEvent")
		local function fire(...: any)
			for _, h in fresh do
				h(...)
			end
		end
		(remote :: any).OnClientEvent:Connect(function(...: any)
			local args = table.pack(...)
			if not route(reliable, "incoming", function()
				fire(table.unpack(args, 1, args.n))
			end) then
				fire(...)
			end
		end)
	end
	table.insert(list, handler)
end

-- Sends to the server through the simulation.
function NetSim.fireServer(remote: Instance, ...: any)
	local args = table.pack(...)
	local function send()
		(remote :: any):FireServer(table.unpack(args, 1, args.n))
	end
	if not route(not remote:IsA("UnreliableRemoteEvent"), "outgoing", send) then
		send()
	end
end

-- Delivers what is due, at the start of every frame (where Roblox hands over
-- real network messages too).
local function flush()
	if #pending == 0 then
		return
	end
	local now = os.clock()
	table.sort(pending, function(a, b)
		return if a.at == b.at then a.order < b.order else a.at < b.at
	end)
	local ready: { Pending } = {}
	local rest: { Pending } = {}
	for _, p in pending do
		table.insert(if p.at <= now then ready else rest, p)
	end
	pending = rest
	for _, p in ready do
		p.deliver()
	end
end

function NetSim.start()
	RunService:BindToRenderStep("VFNetSim", Enum.RenderPriority.First.Value, flush)
end

return NetSim
