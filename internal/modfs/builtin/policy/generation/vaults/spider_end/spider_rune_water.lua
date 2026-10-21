-- Theory of operation: the water ending varies one flooded channel with
-- one fair source coin toss. The authored MAP and other substitutions stay
-- in DES; only this choice belongs in Lua at its original directive site.
local directives = require("constants.vault_directives")

local handler = {}

-- A rare open channel and a denser flooded one each keep shallow-water rules.
local function choose_water(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "W = WW.")
    else
        api:emit(directives.SUBST, "W = W..")
    end
end

handler.choose_water = choose_water

return handler
