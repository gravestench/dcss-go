local catalog = require("policy.catalog")
local component = require("constants.component")
local monsters = require("ids.monsters")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local streams = require("constants.rng_streams")
local stats = require("policy.combat.monster_stats")

local shapeshifter = {}

-- Natural species and Chaos use one durable identity. The first body change
-- happens immediately, as in DCSS placement, before any AI action can run.
function shapeshifter.attach(ctx, monster, variant_id)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor or ctx:has(monster, component.MONSTER_SHAPESHIFTER) then
        return false
    end

    if variant_id ~= monsters.MONS_SHAPESHIFTER and
        variant_id ~= monsters.MONS_GLOWING_SHAPESHIFTER then
        error("unknown shapeshifter variant " .. tostring(variant_id))
    end

    local form = ctx:get(monster, component.MONSTER_POLYMORPH)
    local original = form and form.original_kind_id or actor.kind_id

    ctx:add(monster, component.MONSTER_SHAPESHIFTER, {
        variant_id = variant_id,
        original_kind_id = original,
    })

    local source = catalog.get("monsters", actor.kind_id)

    return polymorph.random_shifter(ctx, monster, source,
        streams.MONSTER_SPELL)
end

-- The permanent component, not the current borrowed kind, defines a shifter.
function shapeshifter.active(ctx, monster)
    return ctx:has(monster, component.MONSTER_SHAPESHIFTER)
end

-- DCSS checks the permanent enchantment before AI chooses a monster action.
-- A blocked action does not spend shape RNG or erase the borrowed body.
function shapeshifter.tick(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_SHAPESHIFTER)

    if not state or ctx:has(monster, component.PARALYSIS) then
        return false
    end

    local stasis = ctx:get(monster, component.MONSTER_STASIS)

    if stasis and (stasis.hibernating or stasis.petrifying_aut > 0 or
        stasis.petrified_aut > 0) then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local health = ctx:get(monster, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local base = actor.kind_id == state.variant_id

    if not base then
        if state.variant_id == monsters.MONS_GLOWING_SHAPESHIFTER then
            if ctx:random(streams.MONSTER_SPELL, 4) ~= 0 then
                return false
            end
        else
            local hd = stats.hit_dice(ctx, monster, definition)
            local denominator = math.floor(15 * math.max(1, hd) / 5)
            local threshold = math.floor(1000 / denominator)

            if ctx:random(streams.MONSTER_SPELL, 1000) >= threshold then
                return false
            end
        end
    end

    return polymorph.random_shifter(ctx, monster, definition,
        streams.MONSTER_SPELL)
end

return shapeshifter
