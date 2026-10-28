--!strict
-- Taking over a bot after dying (system 62), as Counter-Strike lets the
-- dead do: watching a bot on their side, a player presses the use key and
-- plays on as it ('If nobody is possessing the bot, press E', a Steam
-- Community discussion, 2015), for 'the rest of the round' (cs2pulse;
-- community). Its console variable bot_controllable 'Determines whether
-- bots can be controlled by players' (the Valve Developer Community's list
-- of Counter-Strike 2's commands), and in 2021 Counter-Strike 'removed
-- them from classic competitive (5v5) and the wingman (2v2) modes
-- entirely' (PC Gamer, 8 January 2021). Here:
--   * in Skirmish and in the spike rounds but for Competitive's format
--     (MatchConfig's takeOver), while a round's played: anyone down on a
--     side, watching a living bot on it (Spectate), presses F, the
--     interact key, and a new life starts in the bot's body
--   * the body as it is: where it stands, the way it looks, its guns with
--     the rounds in them and the one in hand, its health and shield, and
--     the spike if it carries it (SpikeServer); with the player's own
--     abilities, as any life of theirs has (PlayerSimServer)
--   * the bot's out of the round from then, with no death, and plays from
--     the next on the mode's starting kit; the player's alive again in its
--     place (MatchRules and ArenaRules, Roster.takeOver), so each side has
--     as many alive as before
--   * what the player does from then goes in their record, not the bot's.
--     Counter-Strike counts it for the bot ('All kills will count toward
--     the bot's scoreboard, not yours', cs2pulse; community); here the
--     body's the player's for the rest of the round, its guns theirs to
--     keep if they live, as a survivor keeps theirs
--   * a bot that falls before the new life can start (Roblox takes a
--     moment to load a character) isn't taken, and the player goes on
--     watching
--
-- Here: when the client offers it (open), and the kit a body's taken over
-- on, as its new character carries it for its owner
-- (CharacterRig.SPAWN_KIT), so their prediction starts on it rather than on
-- their last life's.

local MatchConfig = require("../Match/MatchConfig")
local WeaponConfig = require("../Weapons/WeaponConfig")
local WeaponSim = require("../Weapons/WeaponSim")

local BotTakeover = {}

-- The slots a kit has: the primary, the sidearm, the knife and the spike's.
BotTakeover.SLOTS = 4

-- A body's kit: each slot's weapon ("" for none), the rounds in it and in
-- reserve, and the slot in hand.
export type Kit = { loadout: { string }, ammo: { number }, reserve: { number }, equipped: number }

-- Whether what's played lets the dead take over their side's bots now:
-- Skirmish's rounds, and the spike rounds' in a format that has it (not
-- Competitive's), while one's played. `mode` and `phase` are the arena
-- model's Mode and Phase, and `format` its Format, a key of
-- MatchConfig.Formats.
function BotTakeover.open(mode: any, format: any, phase: any): boolean
	if mode == "skirmish" then
		return phase == "live"
	elseif mode ~= "spike" or (phase ~= "live" and phase ~= "planted") then
		return false
	end
	local f = if typeof(format) == "string" then MatchConfig.Formats[format] else nil
	return f ~= nil and f.takeOver
end

-- A simulation's kit as it is.
function BotTakeover.kitOf(w: WeaponSim.State): Kit
	local kit: Kit = { loadout = {}, ammo = {}, reserve = {}, equipped = w.equipped }
	for slot = 1, BotTakeover.SLOTS do
		kit.loadout[slot] = w.loadout[slot]
		kit.ammo[slot] = w.ammo[slot]
		kit.reserve[slot] = w.reserve[slot]
	end
	return kit
end

-- The rounds of a kit in the guns of a new simulation's weapons, made on
-- its loadout (PlayerSim.new), and the slot in hand, if it holds a
-- primary, a sidearm or a knife, already drawn: a body goes on as it was.
function BotTakeover.arm(w: WeaponSim.State, kit: Kit)
	for slot = 1, BotTakeover.SLOTS do
		if w.loadout[slot] ~= "" and w.loadout[slot] == kit.loadout[slot] then
			w.ammo[slot] = math.max(kit.ammo[slot] or 0, 0)
			w.reserve[slot] = math.max(kit.reserve[slot] or 0, 0)
		end
	end
	local hand = kit.equipped
	if hand >= 1 and hand <= 3 and w.loadout[hand] ~= "" then
		w.equipped = hand
	end
end

-- A kit as text, as CharacterRig.SPAWN_KIT carries it: each slot's weapon,
-- rounds and reserve, and after a semicolon the slot in hand
-- ("vandal:25:75,classic:12:36,knife:0:0,;1").
function BotTakeover.kitText(kit: Kit): string
	local parts = {}
	for slot = 1, BotTakeover.SLOTS do
		local id = kit.loadout[slot] or ""
		parts[slot] = if id == "" then "" else string.format("%s:%d:%d", id, kit.ammo[slot] or 0, kit.reserve[slot] or 0)
	end
	return table.concat(parts, ",") .. ";" .. tostring(kit.equipped)
end

-- A kit from its text; nil for anything that isn't one, or names a weapon
-- there's none of.
function BotTakeover.readKit(text: any): Kit?
	if typeof(text) ~= "string" then
		return nil
	end
	local slots, hand = string.match(text, "^([^;]*);(%d+)$")
	if not slots or not hand then
		return nil
	end
	local parts = string.split(slots, ",")
	if #parts ~= BotTakeover.SLOTS then
		return nil
	end
	local kit: Kit = { loadout = {}, ammo = {}, reserve = {}, equipped = tonumber(hand) :: number }
	for slot, part in parts do
		if part == "" then
			kit.loadout[slot], kit.ammo[slot], kit.reserve[slot] = "", 0, 0
			continue
		end
		local id, ammo, reserve = string.match(part, "^([%w_]+):(%d+):(%d+)$")
		if not id or not ammo or not reserve or not WeaponConfig.Defs[id] then
			return nil
		end
		kit.loadout[slot], kit.ammo[slot], kit.reserve[slot] = id, tonumber(ammo) :: number, tonumber(reserve) :: number
	end
	return kit
end

return BotTakeover
