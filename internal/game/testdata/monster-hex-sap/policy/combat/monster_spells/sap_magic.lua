-- Exercise a sparse same-path effect replacement through the real turn.
-- The override delegates rule behavior to the bundled named Sap policy.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.sap_magic")
local spells = require("ids.spells")

local sap = {}
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_SAP_MAGIC)

-- Delegate the hex chance and target checks to production rules so the
-- overlay tests resolution behavior rather than a second spell algorithm.
-- Example: sap.plan(ctx, caster, foe).
function sap.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- Mark this overlay's path in the combat log, then apply the planned hex.
-- The message lets the integration test distinguish it from bundled Sap Magic.
function sap.resolve(ctx, caster, foe, _, plan)
    ctx:emit("combat", "Overlay Sap Magic cast.")

    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return sap
