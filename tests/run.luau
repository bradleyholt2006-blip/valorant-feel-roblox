--!strict
-- Offline tests for the shared simulation code. Run from the repo root:
--   luau tests/run.luau
-- Prints metrics reports (the numbers to compare against reference footage)
-- and pass/fail results. Exits non-zero on failure.

local H = require("./Harness")

require("./movement")
require("./weapons")
require("./accuracy")
require("./arsenal")
require("./combat")
require("./net")
require("./hitreg")
require("./pacing")
require("./penetration")
require("./visuals")
require("./arena")
require("./sound")

H.finish()
