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

function CharacterRig.rootOffset(character: Model, root: BasePart): number
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
		return humanoid.HipHeight + root.Size.Y * 0.5
	end
	return 3 -- R6: 2 stud legs + half of a 2 stud torso
end

return CharacterRig
