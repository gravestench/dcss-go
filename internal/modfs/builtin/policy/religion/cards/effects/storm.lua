-- Storm first scatters actors and clouds with the common Wind Blast owner,
-- then samples distant cells for separate electrical explosions.
local actors = require("policy.combat.monster_wind_actors")
local blast = require("policy.magic.effects.summons.blast")
local clouds = require("policy.combat.monster_wind_clouds")
local component = require("constants.component")
local explosion = require("policy.combat.explosion")
local noise = require("policy.world.noise")
local resistances = require("constants.resistance_ids")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local storm = {}

storm.uses_tier = true

local distant_passable = {
    [terrain.DNGN_DEEP_WATER] = true,
    [terrain.DNGN_LAVA] = true,
    [terrain.DNGN_OPEN_SEA] = true,
}

local adjectives = {
    "mighty",
    "violent",
    "cataclysmic",
}

-- Wind Blast uses a full circle for this untargeted card. Supplying the
-- card stream makes its displacement and collision rolls replay with draws.
local function scatter(ctx, player, origin, tier)
    local power = (tier + 1) * 66
    local radius = 5
    local moved, blocked = actors.push(ctx, player, origin,
        nil, radius, power, streams.CARDS)

    clouds.push(ctx, origin, nil, radius)
    noise.emit(ctx, origin, 8, player)
    actors.collisions(ctx, player, blocked, power, streams.CARDS)
    actors.land(ctx, moved)
end

-- The source runs one reservoir sampler per explosion slot while visiting
-- each LOS_NO_TRANS cell. Duplicate chosen cells produce one actual blast.
local function targets(ctx, origin, count)
    local draws = {}
    local valid = 0

    -- radius_iterator in coordit.cc visits southeast, northeast, southwest,
    -- northwest for each x before increasing y. Keep that RNG visit order.
    local function consider(x, y)
        local distance = math.max(math.abs(x - origin.x),
            math.abs(y - origin.y))
        local feature = ctx:cell(origin.level_id, x, y)

        if distance > 3 and feature and
            (ctx:walkable(origin.level_id, x, y) or
                distant_passable[feature]) and
            ctx:visible_no_trans(origin.level_id, origin.x,
                origin.y, 7, x, y) then
            valid = valid + 1

            for index = 1, count do
                if ctx:random(streams.CARDS, valid) == 0 then
                    draws[index] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    for index = 1, count do
        draws[index] = origin
    end

    for dy = 0, 7 do
        for dx = 0, 7 do
            consider(origin.x + dx, origin.y + dy)

            if dy > 0 then
                consider(origin.x + dx, origin.y - dy)
            end

            if dx > 0 then
                consider(origin.x - dx, origin.y + dy)

                if dy > 0 then
                    consider(origin.x - dx, origin.y - dy)
                end
            end
        end
    end

    local chosen = {}
    local unique = {}

    for _, point in ipairs(draws) do
        if point ~= origin then
            local key = point.x .. ":" .. point.y

            if not chosen[key] then
                chosen[key] = true
                unique[#unique + 1] = point
            end
        end
    end

    table.sort(unique, function(left, right)
        if left.y ~= right.y then
            return left.y < right.y
        end

        return left.x < right.x
    end)

    return unique
end

-- Each blast rolls its own 3d(9 + 9*tier) against every actor reached by
-- the shared wall-aware explosion footprint and electrical resistance path.
local function discharge(ctx, player, origin, point, tier)
    for _, cell in ipairs(explosion.cells(ctx, origin.level_id,
        point.x, point.y, 3)) do
        local victim = ctx:actor_at(origin.level_id, cell.x, cell.y)
        local health = victim and ctx:get(victim, component.HEALTH)

        if health and health.current > 0 then
            local raw = 0

            for _ = 1, 3 do
                raw = raw + 1 + ctx:random(streams.CARDS,
                    9 + 9 * tier)
            end

            blast.hit(ctx, victim, raw, resistances.ELECTRICITY,
                player, streams.CARDS)
        end
    end

    local _, heard = noise.emit(ctx, {
        level_id = origin.level_id,
        x = point.x,
        y = point.y,
    }, 12, player)

    return heard
end

-- Explosion count rises from 1–3 through 4–6 to 7–9. The source wind
-- resolves before the reservoir, so moved monsters occupy their final cells.
function storm.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Storm requires a source power tier")
    end

    local origin = ctx:get(player, component.POSITION)

    scatter(ctx, player, origin, tier)

    local count = tier * 3 + 1 + ctx:random(streams.CARDS, 3)
    local chosen = targets(ctx, origin, count)
    local heard = false

    for _, point in ipairs(chosen) do
        heard = discharge(ctx, player, origin, point, tier) or heard
    end

    if #chosen > 0 then
        local verb = heard and "hear" or "feel"
        local article = #chosen == 1 and "a " or ""
        local plural = #chosen == 1 and "" or "s"

        ctx:emit("religion", "You " .. verb .. " " .. article ..
            adjectives[tier + 1] .. " peal" .. plural .. " of thunder!")
    end
end

return storm
