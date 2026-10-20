-- Theory of operation: Nemelex's dance club features one equipped dancer.
-- The source uses an orc through local D:4 and an ogre afterward; a separate
-- endoplasm slot remains unconditional in the .des file.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the depth choice in the first MONS slot before endoplasms are added.
local function choose_dancer(api)
    if api:depth() <= 4 then
        api:emit(directives.MONS, "orc ; club")
    else
        api:emit(directives.MONS, "ogre ; giant club")
    end
end

handler.choose_dancer = choose_dancer

return handler
