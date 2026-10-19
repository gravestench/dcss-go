local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.sap_magic")
local spells = require("ids.spells")

local sap = {}
-- Sap Magic uses a hex rule that extends the defender's magic-sapping duration.
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_SAP_MAGIC)

-- Example: sap.plan(ctx, caster, foe) with viable foe -> entity plan for the magic-sapping hex
-- Targets a defender for an extended magic-sapping status.
function sap.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

-- The successful hex extends magic-sapping duration without shortening existing state.
function sap.resolve(ctx, caster, foe, _, plan)
    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return sap
