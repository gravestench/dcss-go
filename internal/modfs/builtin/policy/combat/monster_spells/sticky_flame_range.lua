local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local spells = require("ids.spells")
local sticky = require("policy.combat.sticky_flame")

local sticky_flame_range = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_STICKY_FLAME_RANGE)

function sticky_flame_range.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function sticky_flame_range.before_damage(ctx, caster, defender)
    if ctx:has(defender, component.PLAYER) then
        sticky.apply_player(ctx, caster, defender)
    end
end

function sticky_flame_range.after_hit(ctx, caster, defender, _, outcome)
    local actor = ctx:get(defender, component.ACTOR)

    if not actor then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)

    sticky.apply(ctx, caster, defender, definition, outcome.damage)
end

function sticky_flame_range.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile,
        plan, sticky_flame_range)
end

return sticky_flame_range
