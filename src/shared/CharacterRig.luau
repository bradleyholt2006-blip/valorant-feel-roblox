--!strict
-- Where the HumanoidRootPart sits relative to the simulated feet position.

local CharacterRig = {}

function CharacterRig.rootOffset(character: Model, root: BasePart): number
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
		return humanoid.HipHeight + root.Size.Y * 0.5
	end
	return 3 -- R6: 2 stud legs + half of a 2 stud torso
end

return CharacterRig
