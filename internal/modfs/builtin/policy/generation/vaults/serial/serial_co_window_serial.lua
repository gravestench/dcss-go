-- Theory of operation: a rare source controller distributes glass-walled
-- pieces across four named pools. Small and common pieces are frequent;
-- rare pieces and additional glass pieces receive independent bounded rolls.
-- A missing glass pool currently contributes zero maps and becomes available
-- automatically when tagged glass definitions are imported.
local tags = require("constants.vault_tags")
local handler = {}

-- Source count expressions are deliberately separate: multiplying draws
-- changes the distribution and makes the smallest counts more likely.
local function place_co_window_serial(api)
    local small = 5 + api:roll(3) * api:roll(3)
    local common = 3 + api:roll(5)
    local rare = api:roll(3)
    local glass = api:roll(6)

    api:place_maps(tags.SERIAL_CO_WINDOW_SMALL, small)
    api:place_maps(tags.SERIAL_CO_WINDOW_COMMON, common)
    api:place_maps(tags.SERIAL_CO_WINDOW_RARE, rare)
    api:place_maps(tags.SERIAL_GLASS, glass)
end

handler.place_co_window_serial = place_co_window_serial

return handler
