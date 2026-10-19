-- An avatar's sustained song calls drowned souls from unoccupied deep
-- water when nearby allies cannot already defend it.
-- Source: mon-ench.cc:_merfolk_avatar_song.
-- Example: souls.apply(ctx, avatar, state) sets `called` once when deep
-- water is found, then may summon one or two souls on later song pulses.
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local monsters = require("ids.monsters")
local monster_stats = require("policy.combat.monster_stats")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local souls = {}
local SIGHT_RADIUS = 7
local MAX_SOULS = 5

-- Source ignores drowned souls when estimating whether ordinary allies
-- already supply enough strength to make another call unnecessary.
local function ally_hit_dice(ctx, caster, origin)
    local total = 0
    local existing_souls = 0

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if entity ~= caster then
            local position = ctx:get(entity, component.POSITION)
            local health = ctx:get(entity, component.HEALTH)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and
                position.level_id == origin.level_id and
                distance <= SIGHT_RADIUS then
                local actor = ctx:get(entity, component.ACTOR)

                if actor.kind_id == monsters.MONS_DROWNED_SOUL then
                    existing_souls = existing_souls + 1
                elseif targets.aligned(ctx, caster, entity) then
                    local definition = catalog.get("monsters",
                        actor.kind_id)
                    local harmless = false

                    for _, flag in ipairs(definition.flags or {}) do
                        harmless = harmless or flag == flags.NO_THREAT
                    end

                    if not harmless then
                        total = total + monster_stats.hit_dice(ctx,
                            entity, definition)
                    end
                end
            end
        end
    end

    return total, existing_souls
end

-- The source selects water in a sight-sized square around the avatar.
-- Scanning coordinates, rather than Lua file order, fixes the candidate set.
local function deep_water(ctx, origin)
    local cells = {}
    local width, height = ctx:level_size(origin.level_id)

    for y = math.max(0, origin.y - SIGHT_RADIUS),
        math.min(height - 1, origin.y + SIGHT_RADIUS) do
        for x = math.max(0, origin.x - SIGHT_RADIUS),
            math.min(width - 1, origin.x + SIGHT_RADIUS) do
            if ctx:cell(origin.level_id, x, y) ==
                terrain.DNGN_DEEP_WATER and
                not ctx:actor_at(origin.level_id, x, y) then
                cells[#cells + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return cells
end

-- Draw one uniformly remaining destination each time, matching a shuffled
-- water list without keeping a second persistent ordering.
local function take_random(ctx, cells)
    local index = ctx:random(streams.MONSTER_SPELL, #cells) + 1
    local chosen = cells[index]

    cells[index] = cells[#cells]
    cells[#cells] = nil

    return chosen
end

-- A source song pulse may call souls even when its initial mesmerism failed.
-- The owner saves `called` so the rising message appears only once.
function souls.apply(ctx, caster, state)
    local origin = ctx:get(caster, component.POSITION)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local allies, existing = ally_hit_dice(ctx, caster, origin)
    local strength = monster_stats.hit_dice(ctx, caster, definition)

    if allies > strength then
        if state.called and senses.player_sees_cell(ctx, origin) then
            ctx:emit(channels.SPELL,
                "The shadowy forms in the deep grow still as others approach.")
        end

        state.called = false

        return
    end

    local cells = deep_water(ctx, origin)

    if #cells == 0 then
        return
    end

    if not state.called and senses.player_sees_cell(ctx, origin) then
        ctx:emit(channels.SPELL,
            "Shadowy forms rise from the deep at its song!")
    end

    state.called = true

    if ctx:random(streams.MONSTER_SPELL, 2) ~= 0 then
        return
    end

    local count = 1 + (ctx:random(streams.MONSTER_SPELL, 4) == 0 and 1 or 0)

    count = math.min(count, MAX_SOULS - existing, #cells)

    for _ = 1, count do
        local cell = take_random(ctx, cells)

        summons.spawn(ctx, caster, spells.SPELL_AVATAR_SONG,
            monsters.MONS_DROWNED_SOUL, 1, nil, {
                exact = cell,
                hd = strength,
            })
    end
end

return souls
