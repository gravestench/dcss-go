-- The overlaid Magic Dart emits a distinct after-hit message to prove its effect module was selected.

local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local magic_dart = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_MAGIC_DART)

-- Reuse production beam targeting so the overlay changes only its hit hook,
-- leaving the line-of-fire and range decisions under test unchanged.
-- Example: magic_dart.plan(ctx, caster, foe).
function magic_dart.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Emit a recognizable message after a hit to prove this layered resolver won
-- over the bundled one without changing how damage itself is resolved.
function magic_dart.after_hit(ctx)
    ctx:emit("combat", "Overlay dart hit.")
end

-- Pass the plan back to the shared beam resolver; planning and resolution
-- must agree on the same target even when a mod overrides this file.
function magic_dart.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, magic_dart)
end

return magic_dart
