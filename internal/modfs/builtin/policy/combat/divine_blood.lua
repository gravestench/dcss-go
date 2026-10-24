-- Kiku's pain capstone marks nearby eligible floor squares as bloody.
-- Blood is a saved level property, not a terrain ID or a display colour.
local component = require("constants.component")
local solid_area = require("policy.combat.solid_area")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local blood = {}

local cannot_bloodify = {
    [terrain.DNGN_UNSEEN] = true,
    [terrain.DNGN_LAVA] = true,
    [terrain.DNGN_LAVA_SEA] = true,
    [terrain.DNGN_SHALLOW_WATER] = true,
    [terrain.DNGN_DEEP_WATER] = true,
    [terrain.DNGN_TOXIC_BOG] = true,
    [terrain.DNGN_OPEN_SEA] = true,
    [terrain.DNGN_FOUNTAIN_BLUE] = true,
    [terrain.DNGN_FOUNTAIN_MAGIC] = true,
    [terrain.DNGN_FOUNTAIN_DRY] = true,
    [terrain.DNGN_RANDOM_ALTAR] = true,
}

-- Source maybe_bloodify_square rejects water, lava, clean fountains,
-- sanctuary, and good altars. Sanctuary has no live floor property yet;
-- generic altar cells stay clean until their god is exposed as a feature.
local function eligible(ctx, level_id, x, y)
    local feature = ctx:cell(level_id, x, y)

    return feature and not cannot_bloodify[feature] and
        not ctx:cell_blood(level_id, x, y)
end

-- Source maybe_bloodify_square excludes solid cells and tests an
-- independent three-in-four draw for each visible cell in radius two.
function blood.spread(ctx, player, radius)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        error("blood source has no position")
    end

    for dy = -radius, radius do
        for dx = -radius, radius do
            local x = origin.x + dx
            local y = origin.y + dy
            local point = {
                level_id = origin.level_id,
                x = x,
                y = y,
            }

            if solid_area.contains(ctx, origin, point, radius) then
                -- Draw before eligibility, as the source does for every
                -- cell visited by its radius iterator.
                local mark = ctx:random(streams.RELIGION, 4) ~= 0

                if mark and eligible(ctx, origin.level_id, x, y) then
                    ctx:set_cell_blood(origin.level_id, x, y, true)
                end
            end
        end
    end
end

return blood
