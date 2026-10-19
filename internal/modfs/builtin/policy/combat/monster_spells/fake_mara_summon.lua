-- Mara becomes three apparent Maras by making at most two half-life copies
-- of itself. Each copy is a saved summon and cannot repeat this spell.
-- Source: mon-cast.cc:SPELL_FAKE_MARA_SUMMON.
local component = require("constants.component")
local mirror = require("policy.combat.monster_summons.mirror")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")

local effect = {}
local MAX_FAKES = 2

-- The source AI refuses a fake or a full set of two aligned copies before
-- selecting the spell. A change of side can free a slot without deleting old
-- hostile copies immediately.
function effect.plan(ctx, caster)
    if ctx:has(caster, component.SUMMON_MIRROR) or
        mirror.fake_count(ctx, caster) >= MAX_FAKES then
        return nil
    end

    return self_target.plan(caster)
end

-- Each attempt copies the original's current state and current position.
-- Placement failure may leave fewer than two fakes, as in the source.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local attempts = MAX_FAKES - mirror.fake_count(ctx, caster)

    for _ = 1, attempts do
        mirror.spawn(ctx, caster, caster,
            spells.SPELL_FAKE_MARA_SUMMON, 50, MAX_FAKES)
    end
end

return effect
