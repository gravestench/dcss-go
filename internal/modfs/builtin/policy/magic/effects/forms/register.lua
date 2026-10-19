local spells = require("ids.spells")
local forms = require("policy.magic.effects.forms.player")
local registry = require("policy.magic.effects.registry")
local registrations = {}

-- Reject impossible transformations before the common cast path spends MP or time.
function registrations.prepare(ctx, player, spell)
    return forms.rejection(ctx, player, spell.id)
end

-- The shared form resolver delegates duration and body changes by catalog spell ID.
function registrations.resolve(ctx, player, _, spell, power)
    forms.cast(ctx, player, spell.id, power)
end

-- Source: spl-selfench.cc:cast_transform and transform.cc:transform. Each
-- effect owns its no-time dry run before the common cast spends MP.
-- Example: Registering Spider Form gives its catalog ID the shared preparation and resolution callbacks.
-- Give each form spell the same dry-run and cast callbacks while retaining its catalog ID.
function registrations.add(spell_id)
    registry.add(spell_id, {
        prepare = registrations.prepare,
        resolve = registrations.resolve,
    })
end

registrations.add(spells.SPELL_SPIDER_FORM)
registrations.add(spells.SPELL_BEASTLY_APPENDAGE)
registrations.add(spells.SPELL_BLADE_HANDS)
registrations.add(spells.SPELL_STATUE_FORM)
registrations.add(spells.SPELL_ICE_FORM)
registrations.add(spells.SPELL_DRAGON_FORM)
registrations.add(spells.SPELL_NECROMUTATION)
registrations.add(spells.SPELL_STORM_FORM)

return registrations
