-- Theory of operation: the hallway contains repeated letter alcoves.
-- Source count cases shuffle selected alcoves, turn them into B sites,
-- then let the common decoration substitution fill the remaining letters.
local count = require("policy.generation.vaults.altar.count")
local directives = require("constants.vault_directives")

local sites = {
    [5] = "DFJ",
    [6] = "EHK",
    [7] = "DEFH",
    [8] = "EFHJ",
    [9] = "DEFHJ",
    [10] = "EFHJK",
    [11] = "DEFHJK",
}

local handler = {}

-- Shuffle only the source count cases that call for it; an extra random
-- draw here would alter the rest of this vault's layout stream.
local function arrange_altars(api)
    local selected = count.selected(api, 5, 11)

    if selected == 7 or selected == 8 then
        api:emit(directives.SHUFFLE, "EFHJK")
    elseif selected == 9 then
        api:emit(directives.SHUFFLE, "FK")
    end

    api:emit(directives.SUBST, sites[selected] .. " : B")
end

handler.arrange_altars = arrange_altars

return handler
