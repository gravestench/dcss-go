-- Theory of operation: a source CHANCE on early Dungeon or Lair floors
-- creates a cluster of forest pieces. Independent draws keep its group size
-- near four; child weights choose corridors, rooms, and vegetation clumps.
local tags = require("constants.vault_tags")
local handler = {}

-- The two source 0..3 draws make a four-to-ten piece cluster.
local function place_forest(api)
    local count = 4 + api:roll(4) + api:roll(4)

    api:place_maps(tags.SERIAL_FOREST, count)
end

handler.place_forest = place_forest

return handler
