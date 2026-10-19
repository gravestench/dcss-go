-- Source: traps.cc:zot_effects[4].
local component = require("constants.component")

local effect = {}

-- Set MP to zero through the saved magic component so later spell checks see the drain.
-- Example: effect.apply(ctx, player) subtracts magic points without dropping below zero.
function effect.apply(ctx, player)
    local magic = ctx:get(player, component.MAGIC)

    if not magic then
        error("Zot MP drain needs player magic")
    end

    magic.current = 0
    ctx:set(player, component.MAGIC, magic)
    ctx:emit("trap", "Your magic is drained!")
end

return effect
