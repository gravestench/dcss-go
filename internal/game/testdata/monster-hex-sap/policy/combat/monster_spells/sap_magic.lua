-- Exercise a sparse same-path effect replacement through the real turn.
-- The override delegates rule behavior to the bundled named Sap policy.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local hexes = require("policy.combat.monster_hexes")
local rule = require("policy.combat.monster_hexes.sap_magic")
local spells = require("ids.spells")

local sap = {}
local profile = catalog.get(categories.MONSTER_BEAMS, spells.SPELL_SAP_MAGIC)

function sap.plan(ctx, caster, foe)
    return hexes.plan(ctx, caster, foe, profile, rule)
end

function sap.resolve(ctx, caster, foe, _, plan)
    ctx:emit("combat", "Overlay Sap Magic cast.")

    return hexes.resolve(ctx, caster, foe, profile, plan, rule)
end

return sap
