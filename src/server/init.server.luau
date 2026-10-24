--!strict
-- Server entry point.

local TestRange = require(script.TestRange)
local MovementServer = require(script.MovementServer)

TestRange.buildIfMissing()
MovementServer.start()
