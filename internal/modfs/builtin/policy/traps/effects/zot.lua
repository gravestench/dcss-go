-- Source: traps.cc:_zot_trap and trap_def::trigger.
local catalog = require("policy.traps.zot.catalog")
local streams = require("constants.rng_streams")

local effect = {}

-- Monsters rarely activate Zot, but a successful trigger still targets the player outcome table.
-- Example: effect.trigger(ctx, nil, player) draws one Zot outcome after player activation.
function effect.trigger(ctx, _, actor)
    if actor ~= ctx:player() then
        ctx:emit("trap", "You hear a loud \"Zot\"!")

        if ctx:random(streams.TRAPS, 5) ~= 0 then
            return
        end
    else
        ctx:emit("trap", "You enter the Zot trap.")
    end

    ctx:emit("trap", "The power of Zot is invoked against you!")
    local outcome = catalog.choose(ctx)

    require(outcome.module).apply(ctx, ctx:player())
end

return effect
