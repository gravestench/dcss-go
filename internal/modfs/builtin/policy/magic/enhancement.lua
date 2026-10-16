local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local brilliance = require("policy.potions.brilliance")
local equipment = require("policy.combat.equipment")
local staves = require("policy.inventory.staves")

local enhancement = {}

-- Source: spl-cast.cc:_apply_enhancement. School enhancers apply one at a
-- time with integer truncation; all sources together cap at three levels.
function enhancement.apply(ctx, player, spell, centis)
    local levels = effects.sum(ctx, player,
        capabilities.SPELL_ENHANCER, spell)
    local worn = equipment.worn(ctx, player, { weapon = true })

    if worn.weapon then
        levels = levels + staves.enhances(worn.weapon.definition, spell)
    end

    if brilliance.active(ctx, player) then
        levels = levels + 1
    end
    levels = math.max(-3, math.min(3, levels))

    if levels > 0 then
        for _ = 1, levels do
            centis = math.floor(centis * 15 / 10)
        end
    elseif levels < 0 then
        for _ = levels, -1 do
            centis = math.floor(centis / 2)
        end
    end

    return centis
end

return enhancement
