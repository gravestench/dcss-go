-- Major and Legendary Destruction choose ordinary projectile spells.
-- Source: mon-cast.cc:_major_destruction_spell and
-- _legendary_destruction_spell. The choices are fixed by source order,
-- never by file discovery order, so seeded runs remain stable.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local draining = require("policy.combat.monster_beams.draining")
local kinds = require("constants.target_kind")
local spells = require("ids.spells")
local sticky = require("policy.combat.monster_spells.sticky_flame_range")
local streams = require("constants.rng_streams")

local destruction = {}

local major_choices = {
    spells.SPELL_BOLT_OF_FIRE,
    spells.SPELL_FIREBALL,
    spells.SPELL_LIGHTNING_BOLT,
    spells.SPELL_STICKY_FLAME,
    spells.SPELL_IRON_SHOT,
    spells.SPELL_BOLT_OF_DRAINING,
    spells.SPELL_ORB_OF_ELECTRICITY,
}

local legendary_choices = {
    {
        id = spells.SPELL_FIREBALL,
        weight = 25,
    },

    {
        id = spells.SPELL_ICEBLAST,
        weight = 20,
    },

    {
        id = spells.SPELL_GHOSTLY_FIREBALL,
        weight = 15,
    },
}

-- A uniform choice has seven source bands, including the orb and the
-- automatic-hit adjacent Sticky Flame zap.
function destruction.major_choice(ctx)
    local index = ctx:random(streams.MONSTER_SPELL,
        #major_choices) + 1

    return major_choices[index]
end

-- Legendary Destruction uses 25:20:15 explosion weights. Each of its
-- two blasts makes an independent draw during resolution.
function destruction.legendary_choice(ctx)
    local draw = ctx:random(streams.MONSTER_SPELL, 60)

    for _, choice in ipairs(legendary_choices) do
        draw = draw - choice.weight

        if draw < 0 then
            return choice.id
        end
    end

    error("legendary destruction draw exceeded its weighted pool")
end

-- The selected zap supplies damage, hit and blast geometry. The wrapper
-- spell retains its own six- or five-cell source casting range.
local function profile_for(child_id, wrapper_id)
    local child = catalog.get(categories.MONSTER_BEAMS, child_id)
    local profile = {}

    for key, value in pairs(child) do
        profile[key] = value
    end

    profile.id = wrapper_id

    return profile
end

-- Negative bolts drain and Sticky Flame attaches a saved ongoing effect.
-- Their other contact mechanics already live in the shared beam owner.
local function hook_for(child_id)
    if child_id == spells.SPELL_BOLT_OF_DRAINING or
        child_id == spells.SPELL_GHOSTLY_FIREBALL then
        return draining
    end

    if child_id == spells.SPELL_STICKY_FLAME then
        return sticky
    end

    return nil
end

-- Major Destruction's source tracer selects a projectile before the cast.
-- A later cast may draw a different child, so the target intent stores a
-- foe and direction that either a ray or explosion can use.
function destruction.plan_major(ctx, caster, foe)
    local child_id = destruction.major_choice(ctx)
    local profile = profile_for(child_id,
        spells.SPELL_MAJOR_DESTRUCTION)
    local plan = beam.plan(ctx, caster, foe, profile)

    if not plan then
        return nil
    end

    return {
        kind = kinds.ENTITY,
        entity = foe,
        dx = plan.dx,
        dy = plan.dy,
    }
end

-- Actual casting rerolls the source child after targeting, then resolves
-- that child through its own contact hook and the wrapper's range.
function destruction.resolve_major(ctx, caster, foe, plan)
    local child_id = destruction.major_choice(ctx)
    local profile = profile_for(child_id,
        spells.SPELL_MAJOR_DESTRUCTION)

    return beam.resolve(ctx, caster, foe, profile, plan,
        hook_for(child_id))
end

-- All Legendary choices explode, so a cell plan carries the fixed blast
-- endpoint and prevents a foe moving between the two blasts from retargeting.
function destruction.plan_legendary(ctx, caster, foe)
    local child_id = destruction.legendary_choice(ctx)
    local profile = profile_for(child_id,
        spells.SPELL_LEGENDARY_DESTRUCTION)

    return beam.plan(ctx, caster, foe, profile)
end

-- The source attempts a second independent blast only while its foe still
-- lives. Each blast may choose a different elemental profile.
function destruction.resolve_legendary(ctx, caster, foe, plan)
    for _ = 1, 2 do
        local health = ctx:get(foe, component.HEALTH)

        if not health or health.current <= 0 then
            break
        end

        local child_id = destruction.legendary_choice(ctx)
        local profile = profile_for(child_id,
            spells.SPELL_LEGENDARY_DESTRUCTION)

        beam.resolve(ctx, caster, foe, profile, plan,
            hook_for(child_id))
    end
end

return destruction
