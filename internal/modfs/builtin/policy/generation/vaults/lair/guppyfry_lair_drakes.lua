-- Theory of operation: deeper Lair can roll a drake pool and wetter terrain.
-- The alternative preserves the ordinary shallow arrangement from source.
local directives = require("constants.vault_directives")

local handler = {}

-- Source draws a coin only after depth three; shallow floors stay stable.
local function configure(api)
    if api:depth() > 3 and api:coinflip() then
        api:emit(directives.MONS,
            "rime drake / swamp drake / acid dragon")
        api:emit(directives.MONS, "steam dragon")
        api:emit(directives.MONS, "plant")
        api:emit(directives.SUBST, "-_ = wwWW..%")
        api:emit(directives.SHUFFLE, ".t")
    else
        api:emit(directives.SUBST, "12 = 0, _ = wW.%, 3- = .")
    end
end

handler.configure = configure

return handler
