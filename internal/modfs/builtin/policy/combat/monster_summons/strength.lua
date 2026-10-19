local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_stats = require("policy.combat.monster_stats")
local spells = require("ids.spells")

local strength = {}

-- mon-cast.cc:_mons_power_hd_factor gives only these direct summons a
-- non-default factor. The other direct-creature spells use twelve.
local power_factors = {
    [spells.SPELL_MONSTROUS_MENAGERIE] = 6,
    [spells.SPELL_SUMMON_DRAGON] = 5,
    [spells.SPELL_SUMMON_HYDRA] = 5,
}

-- Monster spell HD includes drain, Wretched, and Aura of Brilliance while
-- leaving its ordinary hit dice and maximum HP unchanged.
function strength.spell_hd(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)

    if not actor then
        error("monster summon caster has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)

    return monster_stats.spell_hit_dice(ctx, caster, definition)
end

-- Source mons_power_for_hd multiplies effective spell HD by the spell's
-- factor. Spell effects decide whether their count uses HD or this power.
function strength.power(ctx, caster, spell_id)
    return strength.spell_hd(ctx, caster) *
        (power_factors[spell_id] or 12)
end

return strength
