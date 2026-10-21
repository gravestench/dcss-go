-- One of three wall positions becomes the keyed door in the iron X.
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve crawl.random2(4): zero joins the source's final else arm.
function handler.configure(api)
    local placement = api:roll(4)

    if placement == 1 then
        api:emit(directives.SUBST, "D = {")
        api:emit(directives.NSUBST, "EFHJKLM = 1=} / .")
    elseif placement == 2 then
        api:emit(directives.SUBST, "F = {")
        api:emit(directives.NSUBST, "DJKLM = 1=} / .")
    else
        api:emit(directives.SUBST, "E = {")
        api:emit(directives.NSUBST, "DHJKLM = 1=} / .")
    end
end

return handler
