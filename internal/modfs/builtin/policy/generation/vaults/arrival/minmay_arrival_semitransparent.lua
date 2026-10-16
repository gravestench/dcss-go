local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/small.des:381-386.
local function choose_wall_opacity(api)
    if api:coinflip() == true then
        api:emit(directives.SUBST, "x : cccb")
        api:emit(directives.SUBST, "m : n")
    else
        api:emit(directives.SUBST, "x : xxxb")
    end
end

handler.choose_wall_opacity = choose_wall_opacity

return handler
