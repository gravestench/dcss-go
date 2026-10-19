-- Monster Spellforged Servitor snapshots eligible caster spells onto its own
-- ECS actor. The ordinary monster spellbook and AI owners then run its turns.
-- Source: mon-cast.cc:SPELL_SPELLFORGED_SERVITOR, spl-summoning.cc.
local self_target = require("policy.combat.monster_support.self_target")
local servitor = require("policy.magic.effects.summons.spellforged_servitor")
local strength = require("policy.combat.monster_summons.strength")

local effect = {}

-- The source chooses placement during the cast; no cell or RNG is frozen in
-- the target plan. The caster identity still guards resolution.
function effect.plan(_, caster)
    return self_target.plan(caster)
end

-- Source initialization uses six times the effective spell HD, then rolls
-- the servant's own HD, HP, and prioritized custom spell frequencies.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local power = 6 * strength.spell_hd(ctx, caster)

    servitor.spawn_monster(ctx, caster, power)
end

return effect
