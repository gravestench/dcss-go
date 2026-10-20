-- Theory of operation: this one-percent DES controller has no terrain.
-- Once selected on a rooms layout, it asks the shared serial controller
-- API to place a small group of weighted Core Xii hall maps. Individual
-- DES files own the statue substitutions and geometry of each child.
local handler = {}

-- The source multiplies two 0..2 draws, favoring two halls while allowing
-- up to six. The shared API counts only children that fit the level.
local function place_serial_corexii_hall(api)
    -- Hooks are validated while the vault catalog loads, so resolve the
    -- effective ID only when the controller actually runs.
    local ids = require("ids.vaults")
    local count = 2 + api:roll(3) * api:roll(3)

    api:place_maps(ids.serial_corexii_hall, count)
end

handler.place_serial_corexii_hall = place_serial_corexii_hall

return handler
