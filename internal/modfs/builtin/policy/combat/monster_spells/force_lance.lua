local beam = require("policy.combat.monster_beams")
local beam_power = require("policy.combat.monster_beams.power")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local displacement = require("policy.combat.monster_beams.displacement")
local spells = require("ids.spells")

local force_lance = {}
-- Force Lance adds a post-hit displacement hook to ordinary beam damage resolution.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FORCE_LANCE)

-- Example: force_lance.plan(ctx, caster, foe) with clear path -> entity plan for a possible post-hit push
-- Precedes a post-hit push, which requires a landed beam.
function force_lance.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Push distance depends on dealt damage and caster power after a successful contact.
function force_lance.after_hit(ctx, caster, defender, _, outcome, incoming)
    local power = beam_power.caster_power(ctx, caster, profile)

    displacement.push(ctx, caster, defender, outcome.damage, power,
        incoming)
end

-- Use the hook only after shared contact reports a hit, so missed beams cannot push.
function force_lance.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, force_lance)
end

return force_lance
