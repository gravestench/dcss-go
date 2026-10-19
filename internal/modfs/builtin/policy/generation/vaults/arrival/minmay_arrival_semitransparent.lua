-- Example: A coinflip changes the wall glyph mix while keeping the authored transparent map footprint.
local directives = require("constants.vault_directives")

local handler = {}

-- A coinflip changes the wall glyph mix while keeping the authored transparent map footprint.
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
