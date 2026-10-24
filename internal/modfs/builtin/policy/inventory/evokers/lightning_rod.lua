-- The rod uses the same Thunderbolt arc as the spell. The arc's saved
-- previous aim is separate from the rod's four XP charges: interrupting
-- the sequence loses the widened arc without refunding a charge.
local catalog = require("policy.catalog")
local effects = require("policy.inventory.evokers.effects")
local items = require("ids.items")
local power = require("policy.magic.power")
local skills = require("ids.skills")
local spells = require("ids.spells")
local thunderbolt = require("policy.magic.effects.zaps.thunderbolt")

local rod = {}
local spell = catalog.get("spells", spells.SPELL_THUNDERBOLT)

-- Use Thunderbolt's actual path and range preflight so a rejected ray
-- costs no turn or charge before the action begins.
function rod.prepare(ctx, player, dx, dy)
    return thunderbolt.prepare(ctx, player, spell, dx, dy)
end

-- The item contributes 5 + three power per Evocations level, while the
-- shared zap owner handles previous aim, target cells, and electric damage.
function rod.resolve(ctx, player, chosen)
    local skill = power.training(ctx, player, skills.SK_EVOCATIONS, 1)

    thunderbolt.resolve(ctx, player, chosen, spell, 5 + 3 * skill)

    return {
        charge = true,
        practice = 1,
    }
end

effects.add(items.MISC_LIGHTNING_ROD, rod)

return rod
