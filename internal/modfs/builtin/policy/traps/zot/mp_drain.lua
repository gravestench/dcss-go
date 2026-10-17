-- Source: traps.cc:zot_effects[4].
local component = require("constants.component")

local effect = {}

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
