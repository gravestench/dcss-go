-- Theory of operation: the statue room has a central B pair and two C
-- candidates. Two gods use only B; larger groups open the C sites first.
local count = require("policy.generation.vaults.altar.count")
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve source directive order: open C sites, then select B positions.
local function arrange_altars(api)
    local selected = count.selected(api, 2, 4)

    if selected == 2 then
        api:emit(directives.SUBST, "C = .")
    else
        api:emit(directives.SUBST, "C = B")
    end

    api:emit(directives.NSUBST,
        "B = " .. selected .. ":B / *:.")
end

handler.arrange_altars = arrange_altars

return handler
