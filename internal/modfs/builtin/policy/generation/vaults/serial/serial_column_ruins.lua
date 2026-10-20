-- Theory of operation: one CHANCE on an open Dungeon or Depths layout
-- builds a ruined-city district. A rare roll changes the whole level's
-- tile scheme and scatters pillars; otherwise it picks portal, fancy,
-- and simple pieces in the source order. Every child is tag-only content.
local branches = require("ids.branches")
local tags = require("constants.vault_tags")
local handler = {}

-- Preserve the source draw order, including counts that are not used in
-- the rare pillar mode. This keeps saved layout streams reproducible.
local function place_column_ruins(api)
    local portal_count = 0

    if api.context.branch_id == branches.BRANCH_DEPTHS and api:one_in(2) then
        portal_count = 1
    end

    local fancy_count = api:roll(3)
    local simple_count = 3 + api:roll(3) + api:roll(3)
    local pillar_count = 10 + api:roll(11)

    if api:one_in(33) then
        api:level_tiles("floor_rough_brown", "wall_catacombs")
        api:place_maps(tags.COLUMN_RUINS_PILLAR, pillar_count)
        api:place_maps(tags.COLUMN_RUINS_PORTAL, portal_count)

        return
    end

    api:place_maps(tags.COLUMN_RUINS_PORTAL, portal_count)
    api:place_maps(tags.COLUMN_RUINS_FANCY, fancy_count)
    api:place_maps(tags.COLUMN_RUINS_SIMPLE, simple_count)
end

handler.place_column_ruins = place_column_ruins

return handler
