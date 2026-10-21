-- Theory of operation: Hell has no scheduled parent branch. Its only first
-- floor is the source's encompassing PLACE: Hell map, including five tagged
-- wings. The normal stair scheduler would fabricate an ordinary parent
-- link, so this policy builds the map directly and turns its authored upward
-- exits into typed gates back to the latest outside entrance.
local branches = require("ids.branches")
local terrain = require("constants.terrain")
local levels = require("policy.generation.branch_levels")
local layouts = require("policy.generation.layouts.catalog")
local features = require("content.terrain_features")
local nearest = require("policy.generation.nearest")
local monster_budget = require("policy.generation.monster_budget")

local vestibule = {}

-- Preserve every authored return arch while keeping the source map's
-- ordinary upward glyphs out of generic linked-stair travel.
local function return_arches(cells)
    local count = 0

    for _, row in ipairs(cells) do
        for x, feature in ipairs(row) do
            if feature == terrain.DNGN_STONE_STAIRS_UP_I then
                row[x] = terrain.DNGN_EXIT_HELL
                count = count + 1
            end
        end
    end

    if count == 0 then
        error("authored Vestibule has no return arch")
    end
end

-- Stage one complete source Vestibule. A revisit uses the saved level and
-- never calls this method, so wing choices and Geryon's actor stay fixed.
function vestibule.generate(ctx, input)
    local id = "vestibule_of_hell_subvaulted"
    local definition = layouts.get(id)
    local layout = layouts.execute(ctx, definition,
        branches.BRANCH_VESTIBULE, 1, {
            up = 0,
            down = 0,
        }, input.prior_vault_ids)
    local cells = features.decode_source_rows(layout.builder:rows())
    local records = features.apply_vault_terrain(cells,
        layout.records, ctx, 1)

    return_arches(cells)

    -- Source Geryon pieces own one or several return exits. Enter at the
    -- arch nearest the center, with row/column order breaking equal ties.
    local entry = nearest.open_feature(cells, {
        x = 40,
        y = 35,
    }, terrain.DNGN_EXIT_HELL)

    return {
        level = {
            id = levels.id(branches.BRANCH_VESTIBULE, 1),
            branch_id = branches.BRANCH_VESTIBULE,
            local_depth = 1,
            cells = cells,
            stairs = {},
            entry_x = entry.x,
            entry_y = entry.y,
            initial_monsters = monster_budget.roll(ctx,
                branches.BRANCH_VESTIBULE, 1),
            vault_id = id,
            vault_ids = layout.vault_ids,
            vault_records = records,
        },
    }
end

return vestibule
