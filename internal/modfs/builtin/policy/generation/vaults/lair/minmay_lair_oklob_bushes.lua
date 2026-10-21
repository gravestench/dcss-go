-- Theory of operation: one source draw opens zero to three layers of brush.
-- The authored map remains legible in DES; only the random clearing is Lua.
local directives = require("constants.vault_directives")

local handler = {}

-- Retain the source's ordered thresholds and its possibility of no clearing.
local function configure(api)
    local size = api:roll(10)

    if size > 8 then
        api:emit(directives.SUBST, "`'\" = .")
    elseif size > 6 then
        api:emit(directives.SUBST, "`' = .")
    elseif size > 3 then
        api:emit(directives.SUBST, "` = .")
    end
end

handler.configure = configure

return handler
