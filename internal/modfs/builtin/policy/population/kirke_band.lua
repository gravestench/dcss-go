local component = require("constants.component")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")
local streams = require("constants.rng_streams")
local tactical = require("constants.monster_tactical")

local band = {}

-- C++ mon-place.cc chooses three to eight followers in Kirke's BAND_HOGS.
-- Generate candidate cells once so a deterministic RNG can still fill every
-- available square. A failed placement reduces the band rather than moving
-- a hog onto a blocked, occupied, or authored no-spawn cell.
local function candidates(ctx, level, origin, excluded)
    local cells = {}

    for y = origin.y - 3, origin.y + 3 do
        for x = origin.x - 3, origin.x + 3 do
            if ctx:walkable(level.id, x, y) and
                not excluded[x .. ":" .. y] and
                not ctx:actor_at(level.id, x, y) and
                ctx:visible(level.id, origin.x, origin.y, 7, x, y) then
                cells[#cells + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return cells
end

-- Theory of operation: Kirke's initial hogs are ordinary, persistent ECS
-- actors. Their marker records why they must become humans on her death;
-- the follower link is only for live band AI and may break during travel.
-- Example: band.spawn(ctx, kirke, level, excluded) creates the band around
-- either an ambient Kirke or a Kirke materialized from an authored vault.
function band.spawn(ctx, leader, level, excluded)
    local actor = ctx:get(leader, component.ACTOR)

    if not actor or actor.kind_id ~= monsters.MONS_KIRKE then
        return 0
    end

    local origin = ctx:get(leader, component.POSITION)
    local count = ctx:random(streams.BANDS, 6) + 3
    local placed = 0

    for _ = 1, count do
        local cells = candidates(ctx, level, origin, excluded or {})

        if #cells == 0 then
            break
        end

        local cell = cells[ctx:random(streams.PLACEMENT, #cells) + 1]
        local hog = factory.spawn(ctx, monsters.MONS_HOG, level.id,
            cell.x, cell.y)

        ctx:add(hog, tactical.KIRKE_BAND, {
            band_member = true,
        })
        ctx:add(hog, component.FOLLOWER, {
            leader = leader,
        })
        placed = placed + 1
    end

    return placed
end

return band
