-- Theory of operation: a dryad animates at most three heads rooted beside
-- real tree terrain. The dryad owns their timer; each summon owns an anchor
-- and target. Querying those saved ECS records makes death, level changes,
-- and save/restore release the same vines without a global registry.
-- Source: mon-cast.cc:_awaken_vines and mon-death.cc:unawaken_vines.
local component = require("constants.component")
local habitat = require("policy.combat.monster_habitat")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")
local trees = require("policy.combat.monster_plants.trees")

local vines = {}
local SIGHT_RADIUS = 7
local MAX_VINES = 3
local VINE_DURATION_AUT = 200

local compass = {
    { -1, -1 }, { 0, -1 }, { 1, -1 }, { 1, 0 },
    { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 },
}

-- Count only live heads from this caster. Dead vines cease occupying a
-- source slot even before ordinary death cleanup removes their entities.
function vines.count(ctx, caster)
    local count = 0

    for _, vine in ipairs(ctx:query({ component.MONSTER_VINE })) do
        local summon = ctx:get(vine, component.SUMMON)
        local health = ctx:get(vine, component.HEALTH)

        if summon and summon.owner == caster and health and
            health.current > 0 then
            count = count + 1
        end
    end

    return count
end

-- A vine needs a tree to pull against. A sole diagonal tree cannot hold
-- that tether; any cardinal tree or second adjacent tree can.
local function anchored(ctx, level_id, x, y)
    local count = 0
    local cardinal = false

    for _, offset in ipairs(compass) do
        if trees.at(ctx, level_id, x + offset[1], y + offset[2]) then
            count = count + 1
            cardinal = cardinal or offset[1] == 0 or offset[2] == 0
        end
    end

    return cardinal or count > 1
end

-- Reject a plant that would split its neighboring walkable ring into
-- separate passages. This is the source's local connectivity safeguard.
local function preserves_passage(ctx, level_id, x, y)
    local transitions = 0
    local previous = ctx:walkable(level_id,
        x + compass[#compass][1], y + compass[#compass][2])

    for _, offset in ipairs(compass) do
        local current = ctx:walkable(level_id,
            x + offset[1], y + offset[2])

        if current and not previous then
            transitions = transitions + 1
        end

        previous = current
    end

    return transitions <= 1
end

-- The source scatters heads, leaving at least three cells between them.
local function separated(ctx, level_id, x, y)
    for _, vine in ipairs(ctx:query({ component.MONSTER_VINE })) do
        local position = ctx:get(vine, component.POSITION)
        local health = ctx:get(vine, component.HEALTH)

        if position and health and health.current > 0 and
            position.level_id == level_id and
            math.max(math.abs(position.x - x),
                math.abs(position.y - y)) <= 3 then
            return false
        end
    end

    return true
end

-- Planning checks possible placements without touching RNG. Resolution
-- repeats the check because the foe or another actor may have moved.
function vines.spots(ctx, caster, foe)
    local origin = ctx:get(caster, component.POSITION)
    local victim = ctx:get(foe, component.POSITION)
    local found = {}

    if not origin or not victim or origin.level_id ~= victim.level_id or
        not targets.enemy(ctx, caster, foe) or
        vines.count(ctx, caster) >= MAX_VINES then
        return found
    end

    for y = origin.y - SIGHT_RADIUS, origin.y + SIGHT_RADIUS do
        for x = origin.x - SIGHT_RADIUS, origin.x + SIGHT_RADIUS do
            if habitat.kind_at(ctx, monsters.MONS_SNAPLASHER_VINE,
                origin.level_id, x, y) and
                ctx:visible_no_trans(origin.level_id,
                origin.x, origin.y, SIGHT_RADIUS, x, y) and
                ctx:visible_no_trans(origin.level_id,
                    x, y, SIGHT_RADIUS, victim.x, victim.y) and
                not ctx:actor_at(origin.level_id, x, y) and
                anchored(ctx, origin.level_id, x, y) and
                preserves_passage(ctx, origin.level_id, x, y) and
                separated(ctx, origin.level_id, x, y) then
                found[#found + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return found
end

-- Source shuffles eligible cells before trying them. Fisher-Yates keeps
-- a fixed RNG stream, independent of Lua table iteration order.
local function shuffle(ctx, spots)
    for index = #spots, 2, -1 do
        local swap = ctx:random(streams.MONSTER_SPELL, index) + 1

        spots[index], spots[swap] = spots[swap], spots[index]
    end
end

-- A successful cast draws its number of heads and their positions only
-- after the target and at least one legal tree cell have committed.
function vines.awaken(ctx, caster, foe)
    local spots = vines.spots(ctx, caster, foe)

    if #spots == 0 then
        return false
    end

    shuffle(ctx, spots)

    local remaining = math.min(1 + ctx:random(streams.MONSTER_SPELL, 3),
        MAX_VINES - vines.count(ctx, caster))
    local origin = ctx:get(caster, component.POSITION)
    local created = 0

    for _, spot in ipairs(spots) do
        if remaining == 0 then
            break
        end

        if separated(ctx, origin.level_id, spot.x, spot.y) then
            local vine = summons.spawn(ctx, caster,
                spells.SPELL_AWAKEN_VINES,
                monsters.MONS_SNAPLASHER_VINE, 0, nil, {
                    exact = {
                        x = spot.x,
                        y = spot.y,
                    },
                    expires_aut = ctx:aut() + VINE_DURATION_AUT,
                })

            if vine then
                ctx:add(vine, component.MONSTER_VINE, {
                    target = foe,
                    anchor_x = spot.x,
                    anchor_y = spot.y,
                })
                remaining = remaining - 1
                created = created + 1
            end
        end
    end

    if created == 0 then
        return false
    end

    -- The source refreshes one caster enchant for all of its heads.
    -- Give existing summons the same saved upper bound after a recast.
    for _, vine in ipairs(ctx:query({ component.MONSTER_VINE })) do
        local summon = ctx:get(vine, component.SUMMON)

        if summon and summon.owner == caster then
            summon.expires_aut = ctx:aut() + VINE_DURATION_AUT
            ctx:set(vine, component.SUMMON, summon)
        end
    end

    local state = {
        remaining_aut = VINE_DURATION_AUT,
    }

    if ctx:has(caster, component.MONSTER_AWAKE_VINES) then
        ctx:set(caster, component.MONSTER_AWAKE_VINES, state)
    else
        ctx:add(caster, component.MONSTER_AWAKE_VINES, state)
    end
    ctx:emit("spell", "Vines fly forth from the trees!")

    return true
end

-- The source enchant ends all heads together. The ordinary summon owner
-- also catches a dryad removed by death or a level transition.
function vines.release(ctx, caster)
    local count = 0

    for _, vine in ipairs(ctx:query({ component.MONSTER_VINE })) do
        local summon = ctx:get(vine, component.SUMMON)

        if summon and summon.owner == caster then
            summons.expire(ctx, vine)
            count = count + 1
        end
    end

    ctx:remove(caster, component.MONSTER_AWAKE_VINES)

    if count > 0 then
        ctx:emit("spell", "The vines fall limply to the ground.")
    end
end

-- The dryad's action clock advances the shared duration, as source
-- ENCH_AWAKEN_VINES does. An absent or dead dryad releases every head.
function vines.tick(ctx, caster, aut)
    local state = ctx:get(caster, component.MONSTER_AWAKE_VINES)

    if not state then
        return
    end

    local health = ctx:get(caster, component.HEALTH)

    if not health or health.current <= 0 then
        vines.release(ctx, caster)

        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        vines.release(ctx, caster)
    else
        ctx:set(caster, component.MONSTER_AWAKE_VINES, state)
    end
end

-- A vine outside its awakener's sight dies rather than becoming a free
-- roaming monster. Its owner relation remains the summon record.
function vines.check_head(ctx, vine)
    local summon = ctx:get(vine, component.SUMMON)
    local origin = summon and ctx:get(summon.owner, component.POSITION)
    local position = ctx:get(vine, component.POSITION)

    if not origin or not position or
        origin.level_id ~= position.level_id or
        not ctx:visible_no_trans(origin.level_id,
            origin.x, origin.y, SIGHT_RADIUS,
            position.x, position.y) then
        summons.expire(ctx, vine)

        return false
    end

    return true
end

return vines
