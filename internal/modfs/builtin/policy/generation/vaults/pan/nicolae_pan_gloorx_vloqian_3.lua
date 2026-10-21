-- Theory of operation: two independent source coinflips reshape this
-- decorative Gloorx map between its authored shuffles. They must remain
-- separate hooks because unconditional substitutions run between them.
local directives = require("constants.vault_directives")

local handler = {}

-- The first branch collapses four cells after the opening shuffle.
local function first_pair(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "d = a, e = b, h = f, i = g")
    end
end

-- The second branch swaps the two surviving groups after the next shuffle.
local function second_pair(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "f = b, g = a")
    end
end

handler.first_pair = first_pair
handler.second_pair = second_pair

return handler
