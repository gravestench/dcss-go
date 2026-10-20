-- Theory of operation: the source bayou controller has no MAP cells. Its
-- one-percent chance starts a small group of tagged ponds, fords, and
-- lakes. Their DES files own water terrain and keyed plant placement.
local handler = {}

local CHILD_TAG = "coolio_serial_bayou"

-- Multiplying two bounded draws favors four placements while allowing
-- as many as six, matching the source's uneven bayou density.
local function place_serial_bayou(api)
    local count = 4 + api:roll(3) * api:roll(2)

    api:place_maps(CHILD_TAG, count)
end

handler.place_serial_bayou = place_serial_bayou

return handler
