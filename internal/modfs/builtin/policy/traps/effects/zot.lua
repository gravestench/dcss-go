-- Source: traps.cc:_zot_trap and trap_def::trigger.
local catalog = require("policy.traps.zot.catalog")
local streams = require("constants.rng_streams")

local effect = {}

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
