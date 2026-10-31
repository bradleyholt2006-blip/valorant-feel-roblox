--!strict
-- Watching a teammate (system 21): while you're down in the arena or the
-- spike rounds, dead or waiting for the next round to play, the camera looks
-- out of a living teammate's eyes, a bot's too (system 60, Who), as
-- Counter-Strike's competitive
-- spectating: 'dead players can only watch their teammates in first person',
-- switching between them with the 'left and right mouse button' (the
-- Counter-Strike Wiki; community). Anyone not on a side, waiting in line for
-- a place, may watch anyone; in deathmatch (system 26), where each side is
-- one player, the dead watch nobody, and are back in a moment, as they are
-- in Team Deathmatch (system 27) after a moment watching a teammate. After a
-- death, yours or the watched player's, the view stays where it was for a
-- moment, and once nobody you may watch is alive it holds there, as
-- Counter-Strike's cameras stay 'frozen at the last viewed position of the
-- last player'.
--
-- Near the bottom, who you're watching and when you play: the next round,
-- or once a place opens; not while the Play menu is open (system 24), with
-- the match behind it. Who's alive, on which side and in line comes from
-- the player attributes the server keeps (Arena), and where they look from
-- from RemoteEntities, which leaves the watched player's blocks out of the
-- view. Watching Sova fly his Owl Drone (system 47), the view's the
-- drone's, as the snapshots show it (his `VFDroneId`).
--
-- Watching a bot on your side, F takes it over for the rest of the round
-- (system 62, BotTakeover), where what's played lets the dead: the server
-- starts your new life in its body, and the line under the name says so.
--
-- On a gamepad (system 68, Gamepad), RT and LT switch as left and right
-- click do, and RS takes over as F does; the line says so while the pad's
-- in use.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DroneSim = require(Shared.Abilities.DroneSim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local BotTakeover = require(Shared.Bots.BotTakeover)
local MatchConfig = require(Shared.Match.MatchConfig)
local Remotes = require(Shared.Net.Remotes)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local Units = require(Shared.Units)

local Ui = require(script.Parent.Debug.Ui)
local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)
local PlayMenu = require(script.Parent.PlayMenu)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local Who = require(script.Parent.Who)

local Spectate = {}

-- Who the camera is watching, if anyone.
Spectate.watching = nil :: Who.Someone?

-- Seconds a view stays put after a death before it moves on (estimate).
local DEATH_HOLD = 2
-- Seconds a takeover asked for is waited for before F asks again (estimate:
-- Roblox loads a character in about a third of a second in Studio).
local TAKE_WAIT = 3

type View = { eye: Vector3, yaw: number, pitch: number }

local me = Players.LocalPlayer
local holdUntil = 0
local held: View? = nil -- the last view drawn, held once nobody's left to watch
-- The bot last asked to be taken over (its id in the rules), and when.
local askedFor: number? = nil
local askedAt = -math.huge

-- Who you may watch now, in the order the arena's tiles have them: your
-- side's living players, or anyone alive if you aren't on a side or have
-- nothing to look at yet (you joined as your side's last fell).
local function watchable(): { Who.Someone }
	local side = me:GetAttribute(ArenaConfig.SIDE)
	local anyone = typeof(side) ~= "number" or (held == nil and PlayerController.sim == nil)
	local out: { Who.Someone } = {}
	for _, someone in Who.all() do
		local holder = someone.holder
		if someone.player == me or holder:GetAttribute(MatchConfig.ALIVE) ~= true then
			continue
		elseif not anyone and holder:GetAttribute(ArenaConfig.SIDE) ~= side then
			continue
		elseif RemoteEntities.isPresent(someone.entity) then
			table.insert(out, someone)
		end
	end
	table.sort(out, function(a: Who.Someone, b: Who.Someone): boolean
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.id < b.id
	end)
	return out
end

-- Where someone is in a list of who you may watch.
local function indexOf(list: { Who.Someone }, someone: Who.Someone): number?
	for i, other in list do
		if other.id == someone.id then
			return i
		end
	end
	return nil
end

-- Where someone looks from as they're drawn: their eye, and their aim;
-- flying the Owl Drone, the drone's middle and its.
local function viewOf(someone: Who.Someone): View?
	local drone = someone.holder:GetAttribute(DroneSim.ID_ATTRIBUTE)
	local flying = if typeof(drone) == "number" then RemoteEntities.drone(drone, RemoteEntities.renderTime()) else nil
	if flying then
		return { eye = Units.toStuds(flying.position), yaw = flying.yaw, pitch = flying.pitch }
	end
	local pose = RemoteEntities.sample(someone.entity, RemoteEntities.renderTime())
	if not pose then
		return nil
	end
	local cfg = PlayerController.cfg
	local eye = cfg.standEyeHeight + (cfg.crouchEyeHeight - cfg.standEyeHeight) * pose.crouchAlpha
	return { eye = Units.toStuds(pose.position + vector.create(0, eye, 0)), yaw = pose.yaw, pitch = pose.pitch }
end

-- Whether you may take over who you're watching (system 62): a bot on your
-- side, while what's played lets the dead (BotTakeover.open, from the
-- arena's model), and you're down on a side, not waiting in line.
local function takeable(target: Who.Someone?, arena: Instance?): boolean
	local side = me:GetAttribute(ArenaConfig.SIDE)
	return target ~= nil
		and arena ~= nil
		and target.player == nil
		and typeof(side) == "number"
		and target.holder:GetAttribute(ArenaConfig.SIDE) == side
		and me:GetAttribute(ArenaConfig.LINE) == nil
		and BotTakeover.open(arena:GetAttribute("Mode"), arena:GetAttribute("Format"), arena:GetAttribute("Phase"))
end

-- When you play next, as the line under the name says it. Gun game and both
-- deathmatches have no rounds: the dead come back in a moment (systems 23,
-- 26 and 27).
local function whenYouPlay(phase: any, mode: any): string
	local line = me:GetAttribute(ArenaConfig.LINE)
	if typeof(line) == "number" then
		return string.format("You're %s in line: you play once a place opens", Ui.ordinal(line))
	elseif me:GetAttribute(MatchConfig.ALIVE) == true then
		return "" -- spawning now
	elseif phase == "waiting" or mode == "gungame" or mode == "deathmatch" or mode == "teamdeathmatch" then
		return "You come back in a moment"
	end
	return "You play from the next round"
end

-- Takes over the bot watched, as F does (system 62), once while it's asked
-- for: whether it asked.
function Spectate.takeControl(): boolean
	local target = Spectate.watching
	local now = os.clock()
	if PlayerController.alive or not target or (askedFor == target.id and now - askedAt < TAKE_WAIT) then
		return false
	elseif not takeable(target, Workspace:FindFirstChild(ArenaConfig.MODEL)) then
		return false
	end
	askedFor, askedAt = target.id, now
	Remotes.get().TakeOver:FireServer(target.id)
	return true
end

-- Watches the next player (1) or the one before (-1), as left and right
-- click do; either ends a death's moment early. Not while the mouse moves a
-- cursor on the big map, whose left click pings (system 52), or a menu's.
function Spectate.step(by: number)
	if CameraController.cursorFree or CameraController.mapCursor or PlayerController.alive then
		return
	end
	local current = Spectate.watching
	if not current then
		holdUntil = 0
		return
	end
	local list = watchable()
	local index = indexOf(list, current)
	if index and #list > 1 then
		Spectate.watching = list[(index - 1 + by) % #list + 1]
	end
end

function Spectate.start()
	local gui = Ui.screen("VFSpectate", 15)
	local title = Ui.label(gui, {
		Size = UDim2.fromOffset(600, 26),
		Position = UDim2.new(0.5, -300, 1, -252),
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})
	local status = Ui.label(gui, {
		Size = UDim2.fromOffset(600, 20),
		Position = UDim2.new(0.5, -300, 1, -224),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})
	local ally = Color3.fromRGB(VisualConfig.allyColour.rgb[1], VisualConfig.allyColour.rgb[2], VisualConfig.allyColour.rgb[3])

	local wasAlive = false
	-- After PlayerController has drawn your own view (Camera + 1) and
	-- RemoteEntities everyone else (Camera + 2).
	RunService:BindToRenderStep("VFSpectate", Enum.RenderPriority.Camera.Value + 3, function()
		local now = os.clock()
		local alive = PlayerController.alive
		if wasAlive and not alive then
			holdUntil = now + DEATH_HOLD -- where you fell, for a moment
		end
		wasAlive = alive
		if alive or Workspace:GetAttribute(ArenaConfig.ON) ~= true then
			Spectate.watching = nil
			RemoteEntities.viewing = nil
			held = nil
			title.Visible = false
			status.Visible = false
			return
		end

		local list = watchable()
		local current = Spectate.watching
		if current and not indexOf(list, current) then
			-- They're down: their last view, for a moment.
			Spectate.watching = nil
			holdUntil = now + DEATH_HOLD
		end
		if Spectate.watching == nil and now >= holdUntil then
			Spectate.watching = list[1]
		end
		local target = Spectate.watching
		local view = if target then viewOf(target) else nil
		held = view or held
		RemoteEntities.viewing = if target then target.entity else nil
		local shown = held
		if shown then
			CameraController.lookFrom(shown.eye, shown.yaw, shown.pitch)
		end

		local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
		local phase = if arena then arena:GetAttribute("Phase") else nil
		-- The victory screen (Scoreboard) has the end of a match, the vote for
		-- the next map (VoteScreen) what follows it, and the Play menu the
		-- screen while it's open.
		local over = phase == "matchOver" or phase == "vote" or PlayMenu.open
		local text = whenYouPlay(phase, if arena then arena:GetAttribute("Mode") else nil)
		if target and askedFor == target.id and now - askedAt < TAKE_WAIT then
			text = "Taking control"
		elseif takeable(target, arena) then
			text = if InputSampler.padActive then "RS  take control" else "F  take control"
		end
		if target and #list > 1 then
			text ..= (if text ~= "" then "     " else "") .. (if InputSampler.padActive
				then "RT / LT  switch"
				else "LEFT / RIGHT CLICK  switch")
		end
		title.Visible = target ~= nil and not over
		if target then
			title.Text = "SPECTATING  " .. string.upper(target.name)
			title.TextColor3 = if target.holder:GetAttribute(ArenaConfig.SIDE) == me:GetAttribute(ArenaConfig.SIDE) then ally else Ui.TEXT
		end
		status.Visible = text ~= "" and not over
		status.Text = text
	end)

	-- Left click watches the next player, right click the one before; either
	-- ends a death's moment early. Not while the mouse moves a cursor on the
	-- big map, whose left click pings (system 52).
	UserInputService.InputBegan:Connect(function(input, processed)
		-- F takes over the bot watched (system 62).
		if input.KeyCode == Enum.KeyCode.F then
			if not processed and not CameraController.cursorFree and not CameraController.mapCursor then
				Spectate.takeControl()
			end
			return
		end
		local step = if input.UserInputType == Enum.UserInputType.MouseButton1
			then 1
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then -1
			else 0
		if step ~= 0 and not processed then
			Spectate.step(step)
		end
	end)
end

return Spectate
