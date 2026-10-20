-- Theory of operation: this arena can hold one, two, or three overflow
-- altars. Each smaller group removes an authored B position before the
-- arena's shared decoration and marker rules are interpreted.
local count = require("policy.generation.vaults.altar.count")
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the source's one- and two-altar substitutions at the block position.
local function arrange_altars(api)
    local selected = count.selected(api, 1, 3)

    if selected == 1 then
        api:emit(directives.SUBST, "h = a")
    elseif selected == 2 then
        api:emit(directives.SUBST, "B = a")
    end
end

handler.arrange_altars = arrange_altars

return handler
