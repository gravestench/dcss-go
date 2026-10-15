local spells = require("ids.spells")
local registry = require("policy.magic.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")
local mass = require("policy.magic.effects.statuses.mass_enchantment")
local intoxication = require("policy.magic.effects.statuses.intoxication")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local englaciation = require("policy.magic.effects.statuses.englaciation")
local radiance = require("policy.magic.effects.statuses.toxic_radiance")
local ignite = require("policy.magic.effects.statuses.ignite_poison")
local corpse_rot = require("policy.magic.effects.statuses.corpse_rot")
local infestation = require("policy.magic.effects.statuses.infestation")
local clutch = require("policy.magic.effects.statuses.vile_clutch")
local bog = require("policy.magic.effects.statuses.noxious_bog")
local registrations = {}

function registrations.self_status(ctx, player, _, spell, power)
    statuses.cast(ctx, player, spell.id, power)
end

function registrations.death_door_prepare(ctx, player, spell)
    return statuses.rejection(ctx, player, spell.id)
end

function registrations.mass_enchantment(ctx, player, _, spell, power)
    mass.cast(ctx, player, spell.id, power)
end

function registrations.intoxicate(ctx, player, _, _, power)
    intoxication.cast(ctx, player, power)
end

function registrations.discord(ctx, player, _, _, power)
    allegiance.cast_discord(ctx, player, power)
end

-- Source: spl-selfench.cc:cast_swiftness. Movement timing applies both the
-- quick and sluggish phases through status.move_delay.
registry.add(spells.SPELL_SWIFTNESS, {
    resolve = registrations.self_status,
})

-- Source: spl-selfench.cc:cast_wereblood and mon-death.cc. The combat and
-- death policies consume its slay and kill hooks.
registry.add(spells.SPELL_WEREBLOOD, {
    resolve = registrations.self_status,
})

-- Source: spl-selfench.cc:ice_armour and player.cc:AC calculation.
registry.add(spells.SPELL_OZOCUBUS_ARMOUR, {
    resolve = registrations.self_status,
})

-- Source: spl-selfench.cc:cast_deaths_door and ouch.cc. The damage and
-- regeneration policies consume the active status immediately.
registry.add(spells.SPELL_DEATHS_DOOR, {
    prepare = registrations.death_door_prepare,
    resolve = registrations.self_status,
})

-- Source: spl-selfench.cc:cast_silence and areas.cc. Player cast preflight
-- and monster spell choice consume the shrinking silence radius.
registry.add(spells.SPELL_SILENCE, {
    resolve = registrations.self_status,
})

-- Source: spl-wpnench.cc:cast_confusing_touch and attack.cc:SPWPN_CONFUSE.
-- The melee and monster-decision policies consume the saved enchantment.
registry.add(spells.SPELL_CONFUSING_TOUCH, {
    resolve = registrations.self_status,
})

-- Source: spl-transloc.cc:cast_portal_projectile and throw.cc:throw_it.
-- Projectile preparation and resolution use its saved target and MP hooks.
registry.add(spells.SPELL_PORTAL_PROJECTILE, {
    resolve = registrations.self_status,
})

-- Source: beam.cc:mass_enchantment. Monster decision and player health
-- consume fear retreat and Anguish reflection from saved monster state.
for _, spell_id in ipairs({ spells.SPELL_CAUSE_FEAR, spells.SPELL_ANGUISH }) do
    registry.add(spell_id, {
        resolve = registrations.mass_enchantment,
    })
end

-- Source: spl-other.cc:cast_intoxicate. Monster confusion and player
-- vertigo are saved and used by decision, attack, evasion, and failure rules.
registry.add(spells.SPELL_INTOXICATE, {
    can_target = intoxication.can_target,
    resolve = registrations.intoxicate,
})

-- Source: spl-monench.cc:enfeeble_monster and beam.cc:BEAM_ENFEEBLE.
-- Weak, antimagic, blindness, and daze are each saved monster statuses.
registry.add(spells.SPELL_ENFEEBLE, {
    can_target = enfeeble.can_target,
    resolve = enfeeble.cast,
})

-- Source: actor.cc:can_hibernate and beam.cc:BEAM_HIBERNATION.
-- Monster decisions and damage consume sleep and wake-up hooks.
registry.add(spells.SPELL_HIBERNATION, {
    can_target = stasis.can_target,
    resolve = stasis.cast_hibernation,
})

-- Source: beam.cc:apply_bolt_petrify and monster.cc:hurt. Both stages
-- alter monster actions and incoming damage.
registry.add(spells.SPELL_PETRIFY, {
    can_target = stasis.can_target,
    resolve = stasis.cast_petrify,
})

-- Source: mon-poly.cc:monster_polymorph. The source-traced catalog
-- supplies candidate species; ECS identity, HP, and inventory change.
registry.add(spells.SPELL_POLYMORPH, {
    can_target = polymorph.can_target,
    resolve = polymorph.cast,
})

-- Source: beam.cc:BEAM_CHARM. Charmed monsters select hostile targets.
registry.add(spells.SPELL_CHARMING, {
    can_target = allegiance.can_target_charm,
    resolve = allegiance.cast_charm,
})

-- Source: beam.cc:mass_enchantment(ENCH_INSANE). Frenzied monsters
-- target every nearby actor, gaining source haste and Might effects.
registry.add(spells.SPELL_DISCORD, {
    resolve = registrations.discord,
})

-- Source: spl-monench.cc:cast_englaciation. The cold aura applies source
-- duration to the ordinary saved monster slow component.
registry.add(spells.SPELL_ENGLACIATION, {
    resolve = englaciation.cast,
})

-- Source: spl-damage.cc:toxic_radiance_effect. The aura pulses on casting
-- and on later player actions while its saved duration remains active.
registry.add(spells.SPELL_OLGREBS_TOXIC_RADIANCE, {
    resolve = radiance.cast,
})

-- Source: spl-damage.cc:cast_ignite_poison. Burning poison uses live
-- monster poison degree and clears it after a surviving hit.
registry.add(spells.SPELL_IGNITE_POISON, {
    resolve = ignite.cast,
})

-- Source: spl-selfench.cc:cast_corpse_rot; a saved aura places miasma
-- after eligible visible kills and a separate cloud system applies it.
registry.add(spells.SPELL_CORPSE_ROT, {
    resolve = corpse_rot.cast,
})

-- Source: spl-summoning.cc:cast_infestation; marked monsters burst into
-- friendly death scarabs at the saved death hook.
registry.add(spells.SPELL_INFESTATION, {
    prepare = infestation.prepare,
    resolve = infestation.cast,
})

-- Source: beam.cc:BEAM_VILE_CLUTCH. Saved zombie hands constrain movement
-- and inflict escalating damage after player actions.
registry.add(spells.SPELL_BORGNJORS_VILE_CLUTCH, {
    resolve = clutch.cast,
})

-- Source: spl-damage.cc:cast_noxious_bog and actor_apply_toxic_bog.
-- Temporary terrain markers restore the original feature after expiry.
registry.add(spells.SPELL_NOXIOUS_BOG, {
    prepare = bog.prepare,
    resolve = bog.cast,
})

return registrations
