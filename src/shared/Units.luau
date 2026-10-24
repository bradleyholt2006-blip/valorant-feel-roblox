--!strict
-- Unit conversion between the simulation (metres, Luau `vector`) and Roblox
-- (studs, Vector3). At runtime both are the same native vector type; the casts
-- only keep the type checker happy at the boundary.
-- Roblox documents 1 stud = 28 cm (create.roblox.com/docs/physics/units).

local Units = {}

Units.METRES_PER_STUD = 0.28
Units.STUDS_PER_METRE = 1 / Units.METRES_PER_STUD

function Units.toStuds(metres: vector): Vector3
	return ((metres * Units.STUDS_PER_METRE) :: any) :: Vector3
end

function Units.toMetres(studs: Vector3): vector
	return ((studs * Units.METRES_PER_STUD) :: any) :: vector
end

-- Same-unit casts, for sizes and offsets.
function Units.asVector3(v: vector): Vector3
	return (v :: any) :: Vector3
end

function Units.asVector(v: Vector3): vector
	return (v :: any) :: vector
end

return Units
