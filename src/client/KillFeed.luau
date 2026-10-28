--!strict
-- The kill feed (system 16), at the top right, as the reference's: a row for
-- each kill, newest at the top, each kept FEED_TIME seconds and at most
-- FEED_ROWS of them. A row reads: the killer, the weapon, HS for a headshot
-- and WALL for a kill through a wall, then whoever died. Each name is in its
-- side's colour: you and your side in the ally colour, the other side (and,
-- on the course, everyone else) in the enemy colour. A row you're in, as
-- the killer or the one killed, is outlined in gold. A death nobody caused
-- has what caused it for its killer: the spike's blast, or a spawn room's
-- burn (Team Deathmatch, system 27). Someone Sage's Resurrection brings
-- back has a row too (system 39): who brought them back, the
-- Resurrection in its green, then who's back (Patch 3.0 has the feed
-- show a revive).
--
-- It reads the server's damage events and returns (the Combat remote's
-- "damage" and "revived"), which every client gets. A bot (system 60) is
-- named and coloured as a player is (Who).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TeamDeathmatchConfig = require(Shared.Arena.TeamDeathmatchConfig)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)

local Ui = require(script.Parent.Debug.Ui)
local NetSim = require(script.Parent.NetSim)
local Visuals = require(script.Parent.Visuals)
local Who = require(script.Parent.Who)

local KillFeed = {}

local FEED_ROWS = 6 -- estimate
local FEED_TIME = 6 -- seconds a row stays (estimate)
local ROW_H = 24
local GOLD = Color3.fromRGB(230, 200, 120)
local HEAD = Color3.fromRGB(255, 210, 90)
local SPIKE_RED = Color3.fromRGB(235, 70, 60)
local REVIVE_GREEN = Color3.fromRGB(90, 230, 210)

type Row = { frame: Frame, label: TextLabel, stroke: UIStroke }
type Kill = { attacker: number?, target: number, weapon: string, head: boolean, wall: boolean, revived: boolean, at: number }

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

local function nameOf(id: number): string
	if PlayerCodec.isDummy(id) then
		return string.format("Dummy %d", id - PlayerCodec.DUMMY_BASE)
	end
	return Who.name(id) or "?"
end

-- The colour a name is in: the ally colour for you and your side, the
-- enemy colour for anyone else.
local function colourOf(id: number): Color3
	if id == PlayerCodec.entityIdForUser(Players.LocalPlayer.UserId) or Who.ally(id) then
		return color3(VisualConfig.allyColour)
	end
	return color3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
end

local function tinted(text: string, colour: Color3): string
	return string.format('<font color="#%s">%s</font>', Ui.hex(colour), text)
end

-- A kill's row, as rich text.
local function describe(kill: Kill): string
	local def = WeaponConfig.Defs[kill.weapon]
	local parts = {}
	local attacker = kill.attacker
	if attacker and kill.revived then
		table.insert(parts, tinted(nameOf(attacker), colourOf(attacker)))
		table.insert(parts, tinted(if def then def.name else "?", REVIVE_GREEN))
	elseif attacker then
		table.insert(parts, tinted(nameOf(attacker), colourOf(attacker)))
		table.insert(parts, if def then def.name else "?")
	else
		local cause = if def then string.upper(def.name) elseif kill.weapon == TeamDeathmatchConfig.BURN then "SPAWN ROOM" else "?"
		table.insert(parts, tinted(cause, SPIKE_RED))
	end
	if kill.head then
		table.insert(parts, tinted("HS", HEAD))
	end
	if kill.wall then
		table.insert(parts, tinted("WALL", Ui.DIM))
	end
	table.insert(parts, tinted(nameOf(kill.target), colourOf(kill.target)))
	return table.concat(parts, "   ")
end

function KillFeed.start()
	local gui = Ui.screen("VFKillFeed", 15)
	local rows: { Row } = {}
	for i = 1, FEED_ROWS do
		local frame = Ui.frame(gui, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 12 + (i - 1) * (ROW_H + 4)),
			Size = UDim2.fromOffset(0, ROW_H),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 0.35,
			Visible = false,
		})
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = GOLD
		stroke.Thickness = 1.5
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = frame
		local label = Ui.label(frame, {
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		table.insert(rows, { frame = frame, label = label, stroke = stroke })
	end

	local kills: { Kill } = {} -- newest first
	NetSim.on(Remotes.get().Combat, function(event: any)
		if typeof(event) ~= "table" or typeof(event.target) ~= "number" then
			return
		end
		local revived = event.kind == "revived"
		if not revived and (event.kind ~= "damage" or not event.killed) then
			return
		end
		local kill: Kill = {
			attacker = if typeof(event.attacker) == "number" then event.attacker else nil,
			target = event.target,
			weapon = if typeof(event.weapon) == "string" then event.weapon else "",
			head = event.region == "head",
			wall = event.wallbang == true,
			revived = revived,
			at = os.clock(),
		}
		table.insert(kills, 1, kill)
		if #kills > FEED_ROWS then
			table.remove(kills)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		while #kills > 0 and now - kills[#kills].at >= FEED_TIME do
			table.remove(kills)
		end
		local me = PlayerCodec.entityIdForUser(Players.LocalPlayer.UserId)
		for i, row in rows do
			local kill = kills[i]
			row.frame.Visible = kill ~= nil
			if kill then
				row.label.Text = describe(kill)
				row.stroke.Enabled = kill.attacker == me or kill.target == me
			end
		end
	end)
end

return KillFeed
