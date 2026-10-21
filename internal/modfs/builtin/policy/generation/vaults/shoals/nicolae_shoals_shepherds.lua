-- Theory of operation: one coinflip assigns either centaur or faun leaders
-- to the same authored sheep pasture. The remaining sheep and plants stay
-- in DES because their positions do not depend on the choice.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the two linked monster slots from one draw, never two independent rolls.
local function configure_herd(api)
    if api:coinflip() then
        api:emit(directives.KMONS, "1 = centaur")
        api:emit(directives.KMONS, "2 = centaur warrior")
    else
        api:emit(directives.KMONS, "1 = faun / nothing w:5")
        api:emit(directives.KMONS, "2 = satyr")
    end
end

handler.configure_herd = configure_herd

return handler
