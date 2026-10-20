-- The damp pantheon has three count sizes. At two sizes, one coin flip
-- swaps which damp wing holds altars and which holds decoration.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Choose one complete source substitution after the static wing shuffle.
-- The twenty-altar form uses its sole authored arrangement without a draw.
local function configure(api)
    local selected = tonumber(count.selected(api))

    if selected == 12 then
        if api:roll(2) == 0 then
            api:emit(directives.SUBST, "DE = B, FHJ = T")
        else
            api:emit(directives.SUBST, "DFH = B, EJ = T")
        end
    elseif selected == 16 then
        if api:roll(2) == 0 then
            api:emit(directives.SUBST, "DEF = B, JH = T")
        else
            api:emit(directives.SUBST, "DFHJ = B, E = T")
        end
    else
        api:emit(directives.SUBST, "DEFH = B, J = T")
    end
end

handler.configure = configure

return handler
