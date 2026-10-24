--!strict
-- Minimal test harness shared by the offline suites.

local Harness = {}

local passes = 0
local failures = 0

function Harness.check(name: string, ok: boolean, detail: string?)
	if ok then
		passes += 1
		print("  PASS " .. name)
	else
		failures += 1
		print("  FAIL " .. name .. (if detail then " (" .. detail .. ")" else ""))
	end
end

function Harness.near(a: number, b: number, tol: number): boolean
	return math.abs(a - b) <= tol
end

function Harness.section(title: string)
	print()
	print("== " .. title .. " ==")
end

function Harness.fmt(v: number?, unit: string, scale: number?): string
	if v == nil then
		return "n/a"
	end
	return string.format("%.0f %s", v * (scale or 1), unit)
end

function Harness.finish()
	print()
	print(string.format("%d passed, %d failed", passes, failures))
	if failures > 0 then
		error("tests failed")
	end
end

return Harness
