-- Theory of operation: the source one-percent serial_rivers controller has
-- no MAP cells. Once selected, it requests four to six independently
-- weighted stream pieces. Each child DES file controls its own terrain,
-- water mask, and any substitution before geometric placement.
local handler = {}

-- One 0..2 draw varies the number of stream pieces without changing the
-- controller's independent CHANCE declaration.
local function place_serial_rivers(api)
    -- Resolve the effective ID after catalog load has finalized the
    -- registry; hook validation imports this module earlier.
    local ids = require("ids.vaults")
    local count = 4 + api:roll(3)

    api:place_maps(ids.serial_rivers, count)
end

handler.place_serial_rivers = place_serial_rivers

return handler
