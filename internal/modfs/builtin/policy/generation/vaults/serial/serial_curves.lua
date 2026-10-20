-- Theory of operation: the source serial_curves CHANCE declaration first
-- wins an independent chance roll. This hook then draws the source count
-- and asks the shared controller API for that many weighted tagged maps.
-- The DES map owns eligibility and the four child maps own their geometry.
local handler = {}

-- Multiplying two small draws favors the minimum count, matching the
-- source's nonuniform two-to-four curved-corridor distribution.
local function place_serial_curves(api)
    -- Resolve the source name only when the hook runs: catalog load validates
    -- this module before the effective ID registry has been finalized.
    local ids = require("ids.vaults")
    local count = 2 + api:roll(3) * api:roll(2)

    api:place_maps(ids.serial_curves, count)
end

handler.place_serial_curves = place_serial_curves

return handler
