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
require("./shop")
require("./net")
require("./hitreg")
require("./pacing")
require("./penetration")
require("./visuals")
require("./arena")
require("./sound")
require("./melee")
require("./settings")
require("./spike")
require("./match")
require("./economy")
require("./groundguns")
require("./scoreboard")
require("./abilities")
require("./cloudburst")
require("./bladestorm")
require("./drift")
require("./dropin")
require("./mapvote")
require("./gungame")

H.finish()
