-- Awaken Vines chooses one enemy and later creates tethered tree summons.
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local vines = require("policy.combat.monster_plants.vines")
local spells = require("ids.spells")

local effect = {}

-- This is a self-origin spell, but the vine placement depends on the
-- selected foe. Save that foe through the usual direct-spell plan.
function effect.plan(ctx, caster, foe)
    if not foe or #vines.spots(ctx, caster, foe) == 0 then
        return nil
    end

    return direct.plan(ctx, caster, foe, spells.SPELL_AWAKEN_VINES)
end

-- A plan never licenses retargeting after the foe moves or dies.
function effect.resolve(ctx, caster, foe, _, plan)
    direct.require(ctx, caster, foe, plan)

    if not ctx:has(caster, component.ACTOR) then
        return
    end

    vines.awaken(ctx, caster, foe)
end

return effect
