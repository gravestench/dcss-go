-- Monsters launch the same persistent Orb of Destruction as players. The
-- source mon-cast.cc assigns eight power per live spell HD; the shared orb
-- owner handles motion, collision, explosion, and save/restore thereafter.
local catalog = require("policy.catalog")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local iood = require("policy.magic.effects.zaps.iood")
local monster_stats = require("policy.combat.monster_stats")
local rng_streams = require("constants.rng_streams")
local spells = require("ids.spells")

local effect = {}
local POWER_PER_HD = 8

-- An orb needs a live visible target on this level before the caster can
-- commit a spell turn; the saved entity is used for later homing.
function effect.plan(ctx, caster, foe)
    return direct.plan(ctx, caster, foe, spells.SPELL_IOOD)
end

-- A moved foe changes the initial aim but remains the same homing target.
-- The orb may still strike terrain or another actor along its route.
function effect.resolve(ctx, caster, foe, _, plan)
    local destination = direct.require(ctx, caster, foe, plan)
    local origin = ctx:get(caster, component.POSITION)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local hd = monster_stats.spell_hit_dice(ctx, caster, definition)

    iood.launch(ctx, caster, destination.x - origin.x,
        destination.y - origin.y, hd * POWER_PER_HD,
        foe, rng_streams.MONSTER_SPELL)
end

return effect
