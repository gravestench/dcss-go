-- This Geryon wing decides whether its center is water or lava. The DES
-- file owns the shape and the Geryon spawn; only the choice belongs here.
local directives = require("constants.vault_directives")

local handler = {}

-- Draw once at the source script site, before the MAP is substituted.
-- The one-in-three water branch also floods some surrounding lava cells.
local function geryon_pool(api)
    if api:one_in(3) then
        api:emit(directives.KFEAT, "1 = w")
        api:emit(directives.SUBST, "l : w")

        return
    end

    api:emit(directives.KFEAT, "1 = l")
end

handler.geryon_pool = geryon_pool

return handler
