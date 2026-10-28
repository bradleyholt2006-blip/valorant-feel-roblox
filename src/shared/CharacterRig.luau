--!strict
-- Where the HumanoidRootPart sits relative to the simulated feet position.

local CharacterRig = {}

-- Attribute the server puts on each new character: the feet (metres) its
-- simulation starts that life from, so the owner's prediction starts there
-- too instead of reading its own copy of the character.
CharacterRig.SPAWN_FEET = "VFSpawnFeet"
-- And the seq of that life's first input (InputQueue.LIFE_GAP past the last
-- life's), so the owner numbers its inputs from there and ignores acks from
-- before it. Set before SPAWN_FEET, so it's there when that is.
CharacterRig.FIRST_SEQ = "VFFirstSeq"
-- And, when the life starts facing a set way (the arena's spawns), the yaw
-- in radians. Also set before SPAWN_FEET.
CharacterRig.SPAWN_YAW = "VFSpawnYaw"
-- And, for a life the Resurrection brought back (system 39), until when it
-- rises with the body and until when it's held, as seconds of that life's
-- simulation (a Vector2: X and Y). Also set before SPAWN_FEET.
CharacterRig.REVIVED = "VFRevived"
-- And, for a life in a bot's body taken over (system 62), the way it
-- looked up or down, in radians, and its kit as text (BotTakeover.kitText):
-- the life starts on that kit, not the last one's. Also set before
-- SPAWN_FEET.
CharacterRig.SPAWN_PITCH = "VFSpawnPitch"
CharacterRig.SPAWN_KIT = "VFSpawnKit"

function CharacterRig.rootOffset(character: Model, root: BasePart): number
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
		return humanoid.HipHeight + root.Size.Y * 0.5
	end
	return 3 -- R6: 2 stud legs + half of a 2 stud torso
end

return CharacterRig
