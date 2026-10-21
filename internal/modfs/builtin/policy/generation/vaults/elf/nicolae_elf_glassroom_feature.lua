-- This glass room's source furniture becomes richer as Elf deepens.
local directives = require("constants.vault_directives")

local handler = {}

-- Resolve the S glyph at the source script site, before CLEAR removes
-- only its masking underscore and the MAP is projected into the level.
local function configure(api)
    local furniture

    if api:depth() == 1 then
        furniture = ")}]"
    elseif api:depth_fraction() < 1 then
        furniture = "(){}[]"
    else
        furniture = "({["
    end

    api:emit(directives.SUBST, "S = " .. furniture)
end

handler.configure = configure

return handler
