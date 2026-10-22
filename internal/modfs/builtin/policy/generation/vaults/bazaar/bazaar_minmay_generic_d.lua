-- The D-shaped market flips its liquid and shop-symbol arrangement.
-- This source coinflip runs before its authored shop and colour directives.
local directives = require("constants.vault_directives")

local handler = {}

-- Swap the two edge liquids and shop markers as one source decision.
local function swap_liquid_and_shops(api)
    if api:coinflip() then
        api:emit(directives.SUBST, [=["=l , '=. , A=l , B=!]=])
    else
        api:emit(directives.SUBST, [=["=. , '=l , A=! , B=l]=])
    end
end

handler.swap_liquid_and_shops = swap_liquid_and_shops

return handler
