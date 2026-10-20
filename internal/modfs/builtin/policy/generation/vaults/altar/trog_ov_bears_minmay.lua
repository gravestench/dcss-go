-- Theory of operation: the bear altar is eligible after D:4. Its first
-- monster slot upgrades from a black bear to a polar bear at absolute depth
-- ten; the second bush slot remains an unconditional source declaration.
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve the source threshold without changing the bush slot order.
local function choose_bear(api)
    if api:absolute_depth() < 10 then
        api:emit(directives.MONS, "black bear")
    else
        api:emit(directives.MONS, "polar bear")
    end
end

handler.choose_bear = choose_bear

return handler
