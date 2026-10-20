-- The tempest star has two arrangements of its outer and inner points.
-- One source coin flip chooses the arrangement after the initial shuffle.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Keep each outer-star choice and its count-dependent inner-star choice
-- together; independent rolls would create a pattern the source cannot use.
local function configure(api)
    local selected = tonumber(count.selected(api))

    if api:roll(2) == 0 then
        api:emit(directives.SUBST, "'bFGz = x, d = ., e = y")

        if selected == 12 then
            api:emit(directives.SUBST, "CD = B, E = .")
        else
            api:emit(directives.SUBST, "CDE = B")
        end

        return
    end

    api:emit(directives.SUBST,
        "'e = ., d = y, z : cWwl., bG = B, DE = .")

    if selected == 12 then
        api:emit(directives.SHUFFLE, "FG")
        api:emit(directives.SUBST, "CF = .")
    else
        api:emit(directives.SUBST, "CF = B")
    end
end

handler.configure = configure

return handler
