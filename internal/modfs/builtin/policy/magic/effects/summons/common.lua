local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local catalog = require("policy.catalog")
local energy = require("policy.monster_energy")
local hit_points = require("policy.population.hit_points")
local allies = require("policy.character.allies")
local categories = require("constants.catalog")

local summons = {}

local offsets = {
    {
        dx = -1,
        dy = -1,
    },
    {
        dx = 0,
        dy = -1,
    },
    {
        dx = 1,
        dy = -1,
    },
    {
        dx = -1,
        dy = 0,
    },
    {
        dx = 1,
        dy = 0,
    },
    {
        dx = -1,
        dy = 1,
    },
    {
        dx = 0,
        dy = 1,
    },
    {
        dx = 1,
        dy = 1,
    },
}

local abjuration_duration_aut = {
    [1] = 90,
    [2] = 180,
    [3] = 270,
    [4] = 360,
    [5] = 810,
    [6] = 1710,
}

function summons.roll(ctx, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random("spell", bound)
end

-- Source: random.cc:div_rand_round for nonnegative monster power values.
function summons.divide(ctx, numerator, denominator)
    if numerator < 0 then
        return math.ceil(numerator / denominator)
    end

    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and summons.roll(ctx, denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

function summons.expire(ctx, entity)
    local position = ctx:get(entity, component.POSITION)

    for _, ally in ipairs(ctx:query({ component.SUMMON_BOND })) do
        local bond = ctx:get(ally, component.SUMMON_BOND)

        if bond.guardian == entity then
            ctx:remove(ally, component.SUMMON_BOND)
        end
    end

    for _, item in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(item, component.CARRIED_BY)

        if carrier.holder == entity then
            ctx:destroy(item)
        end
    end

    if position then
        ctx:remove_actor(entity, position.level_id)
    end

    ctx:destroy(entity)
end

local function earlier_expiry(left, right)
    if left.expires_aut == right.expires_aut then
        return left.entity_id < right.entity_id
    end

    return left.expires_aut < right.expires_aut
end

local function cap_oldest(ctx, owner, source_category, source_id, cap)
    local existing = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if not ctx:has(entity, component.SUMMON_SEGMENT) and
            state.owner == owner and
            state.source_category == source_category and
            state.source_id == source_id then
            existing[#existing + 1] = {
                entity = entity,
                entity_id = ctx:id(entity),
                expires_aut = state.expires_aut,
            }
        end
    end

    table.sort(existing, earlier_expiry)

    for index = 1, math.max(0, #existing - cap) do
        summons.expire(ctx, existing[index].entity)
    end
end

local function open_cell(ctx, position)
    local start = summons.roll(ctx, #offsets) + 1

    for index = 0, #offsets - 1 do
        local offset = offsets[(start + index - 1) % #offsets + 1]
        local x = position.x + offset.dx
        local y = position.y + offset.dy

        if ctx:walkable(position.level_id, x, y) and
            not ctx:actor_at(position.level_id, x, y) then
            return x, y
        end
    end

    return nil, nil
end

-- Source: spl-summoning.cc:_summon_data and mon-ench.cc:ENCH_ABJ.
-- The source applies broad random fuzz to these nominal durations; this
-- runtime preserves the source degree's nominal aut until that RNG exists.
function summons.spawn(ctx, owner, source_id, kind_id, degree, cap, options)
    local origin = options and options.anchor or ctx:get(owner, component.POSITION)
    local x, y

    if options and options.exact then
        x, y = options.exact.x, options.exact.y

        if (not ctx:walkable(origin.level_id, x, y) and
            ctx:cell(origin.level_id, x, y) ~= terrain_ids.DNGN_MALIGN_GATEWAY) or
            ctx:actor_at(origin.level_id, x, y) then
            return nil
        end
    else
        x, y = open_cell(ctx, origin)
    end

    if not x then
        ctx:emit("spell", "Nothing happens.")

        return nil
    end

    local definition = catalog.get("monsters", kind_id)
    local hp = options and options.hp or hit_points.roll(ctx, definition.average_hp_10x)
    local hostile = allies.hostile_spawn(ctx, owner, definition)

    if options and options.hostile ~= nil then
        hostile = options.hostile
    end
    local actor = ctx:create()

    ctx:add(actor, component.ACTOR, {
        kind_id = kind_id,
        speed = definition.speed,
    })
    ctx:add(actor, "core.monster_energy", {
        points = options and options.passive and 0 or energy.initial,
    })
    ctx:add(actor, component.HEALTH, {
        current = hp,
        max = hp,
    })
    ctx:add(actor, "core.combat", { shield_blocks = 0 })
    ctx:add(actor, component.AI, { behavior = "wander" })
    local source_category = options and options.source_category or
        categories.SPELLS

    ctx:add(actor, component.SUMMON, {
        owner = owner,
        source_category = source_category,
        source_id = source_id,
        expires_aut = options and options.expires_aut or
            (degree == 0 and 0 or ctx:aut() +
                abjuration_duration_aut[degree]),
        heads = options and options.heads or 0,
        hostile = hostile,
    })

    if options and options.hd then
        ctx:add(actor, component.SUMMON_STATS, { hd = options.hd })
    end
    ctx:place_actor(actor, origin.level_id, x, y)

    if hostile then
        ctx:emit("monster", "The " .. definition.name ..
            " feels only hate for you!")
    end

    if not (options and options.segment) then
        cap_oldest(ctx, owner, source_category, source_id, cap)
    end

    return actor
end

return summons
