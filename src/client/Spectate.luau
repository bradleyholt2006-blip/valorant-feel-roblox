--!strict
-- Watching a teammate (system 21): while you're down in the arena or the
-- spike rounds, dead or waiting for the next round to play, the camera looks
-- out of a living teammate's eyes, as Counter-Strike's competitive
-- spectating: 'dead players can only watch their teammates in first person',
-- switching between them with the 'left and right mouse button' (the
-- Counter-Strike Wiki; community). Anyone not on a side, waiting in line for
-- a place, may watch anyone; in deathmatch (system 26), where each side is
-- one player, the dead watch nobody, and are back in a moment. After a
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
-- view.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local MatchConfig = require(Shared.Match.MatchConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local Units = require(Shared.Units)

local Ui = require(script.Parent.Debug.Ui)
local CameraController = require(script.Parent.CameraController)
local PlayMenu = require(script.Parent.PlayMenu)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)

local Spectate = {}

-- Who the camera is watching, if anyone.
Spectate.watching = nil :: Player?

-- Seconds a view stays put after a death before it moves on (estimate).
local DEATH_HOLD = 2

type View = { eye: Vector3, yaw: number, pitch: number }

local me = Players.LocalPlayer
local holdUntil = 0
local held: View? = nil -- the last view drawn, held once nobody's left to watch

-- Who you may watch now, in the order the arena's tiles have them: your
-- side's living players, or anyone alive if you aren't on a side or have
-- nothing to look at yet (you joined as your side's last fell).
local function watchable(): { Player }
	local side = me:GetAttribute(ArenaConfig.SIDE)
	local anyone = typeof(side) ~= "number" or (held == nil and PlayerController.sim == nil)
	local out: { Player } = {}
	for _, player in Players:GetPlayers() do
		if player == me or player:GetAttribute(MatchConfig.ALIVE) ~= true then
			continue
		elseif not anyone and player:GetAttribute(ArenaConfig.SIDE) ~= side then
			continue
		elseif RemoteEntities.isPresent(PlayerCodec.entityIdForUser(player.UserId)) then
			table.insert(out, player)
		end
	end
	table.sort(out, function(a: Player, b: Player): boolean
		if a.DisplayName ~= b.DisplayName then
			return a.DisplayName < b.DisplayName
		end
		return a.UserId < b.UserId
	end)
	return out
end

-- Where a player looks from as they're drawn: their eye, and their aim.
local function viewOf(player: Player): View?
	local pose = RemoteEntities.sample(PlayerCodec.entityIdForUser(player.UserId), RemoteEntities.renderTime())
	if not pose then
		return nil
	end
	local cfg = PlayerController.cfg
	local eye = cfg.standEyeHeight + (cfg.crouchEyeHeight - cfg.standEyeHeight) * pose.crouchAlpha
	return { eye = Units.toStuds(pose.position + vector.create(0, eye, 0)), yaw = pose.yaw, pitch = pose.pitch }
end

-- When you play next, as the line under the name says it. Gun game and
-- deathmatch have no rounds: the dead come back in a moment (systems 23 and
-- 26).
local function whenYouPlay(phase: any, mode: any): string
	local line = me:GetAttribute(ArenaConfig.LINE)
	if typeof(line) == "number" then
		return string.format("You're %s in line: you play once a place opens", Ui.ordinal(line))
	elseif me:GetAttribute(MatchConfig.ALIVE) == true then
		return "" -- spawning now
	elseif phase == "waiting" or mode == "gungame" or mode == "deathmatch" then
		return "You come back in a moment"
	end
	return "You play from the next round"
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
		if current and not table.find(list, current) then
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
		RemoteEntities.viewing = if target then PlayerCodec.entityIdForUser(target.UserId) else nil
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
		if target and #list > 1 then
			text ..= (if text ~= "" then "     " else "") .. "LEFT / RIGHT CLICK  switch"
		end
		title.Visible = target ~= nil and not over
		if target then
			title.Text = "SPECTATING  " .. string.upper(target.DisplayName)
			title.TextColor3 = if target:GetAttribute(ArenaConfig.SIDE) == me:GetAttribute(ArenaConfig.SIDE) then ally else Ui.TEXT
		end
		status.Visible = text ~= "" and not over
		status.Text = text
	end)

	-- Left click watches the next player, right click the one before; either
	-- ends a death's moment early.
	UserInputService.InputBegan:Connect(function(input, processed)
		local step = if input.UserInputType == Enum.UserInputType.MouseButton1
			then 1
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then -1
			else 0
		if step == 0 or processed or CameraController.cursorFree or PlayerController.alive then
			return
		end
		local current = Spectate.watching
		if not current then
			holdUntil = 0
			return
		end
		local list = watchable()
		local index = table.find(list, current)
		if index and #list > 1 then
			Spectate.watching = list[(index - 1 + step) % #list + 1]
		end
	end)
end

return Spectate
