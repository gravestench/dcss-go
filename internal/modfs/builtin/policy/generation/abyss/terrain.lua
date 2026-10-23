-- Build one typed 80x70 window from the Lua source-layout sampler. The
-- temporary result is not published until its vaults, actors, and state
-- have passed the game's generic region transaction.
local constants = require("constants.abyss")
local sampler = require("policy.generation.abyss.sampler")
local terrain = require("constants.terrain")

local window = {}

-- Copy state fields without moving the caller's queue or advancing the
-- source morph clock. A failed later vault hook can discard this copy.
local function copy_state(state)
    local copied = {}

    for key, value in pairs(state) do
        copied[key] = value
    end

    copied.sample_queue = {}

    return copied
end

-- The source sample queue is ordered by next change point. Stable
-- coordinate ties keep save bytes independent from Lua table iteration.
local function earlier(left, right)
    if left.change ~= right.change then
        return left.change < right.change
    end

    if left.y ~= right.y then
        return left.y < right.y
    end

    return left.x < right.x
end

-- Sample every interior coordinate once. The perimeter remains solid
-- because source map generation never carves outside MAPGEN_BORDER.
function window.build(ctx, state)
    local cells = {}
    local updated = copy_state(state)

    for y = 0, constants.HEIGHT - 1 do
        local row = {}

        for x = 0, constants.WIDTH - 1 do
            local boundary = x == 0 or y == 0 or
                x == constants.WIDTH - 1 or
                y == constants.HEIGHT - 1

            if boundary then
                row[x + 1] = terrain.DNGN_ROCK_WALL
            else
                local feature, change = sampler.sample(ctx, state, x, y)

                if not feature or not change or change < state.morph_depth then
                    error("Abyss sampler returned an invalid cell")
                end

                row[x + 1] = feature
                updated.sample_queue[#updated.sample_queue + 1] = {
                    x = x,
                    y = y,
                    change = change,
                    feature = feature,
                }
            end
        end

        cells[y + 1] = row
    end

    table.sort(updated.sample_queue, earlier)

    return cells, updated
end

return window
