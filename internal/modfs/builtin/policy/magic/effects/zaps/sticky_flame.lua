local catalog = require("policy.catalog")
local component = require("constants.component")
local projectile = require("policy.magic.effects.zaps.projectile")
local spells = require("ids.spells")
local sticky = require("policy.combat.sticky_flame")

local effect = {}

-- Example: A damaging Sticky Flame hit attaches the timed burning state to its target.
-- Only a landed projectile delegates lingering Sticky Flame to the combat status policy.
function effect.after_hit(ctx, source, target, _, dealt)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    sticky.apply(ctx, source, target, definition, dealt)
end

projectile.register(spells.SPELL_STICKY_FLAME, {
    name = "sticky flame",
    cap = 100,
    auto_hit = true,
    damage = {
        kind = "dicedef",
        count = 2,
        base = 3,
        numerator = 1,
        denominator = 12,
    },
    hit = {
        base = 0,
        numerator = 0,
        denominator = 1,
    },
    element = "MR_RES_FIRE",
    after_hit = effect.after_hit,
})

return sticky
