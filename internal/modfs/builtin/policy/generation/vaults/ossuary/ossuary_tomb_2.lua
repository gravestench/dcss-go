-- The second Tomb map has a rare dense-hall variant and a usual shuffled
-- variant. One source draw chooses the entire set of substitutions.
local directives = require("constants.vault_directives")

local tomb = {}

-- Preserve the source 1-in-10 choice and directive ordering before the
-- ordinary substitutions later in the same DES definition.
local function choose_tomb(api)
    if api:one_in(10) then
        api:emit(directives.SUBST, "' = 1")
        api:emit(directives.SUBST, "1 = 1:20 2:10 .:80")

        return
    end

    api:emit(directives.SHUFFLE, "1'")
    api:emit(directives.SUBST, "1 = 1:20 2:10 .:20")
end

tomb.choose_tomb = choose_tomb

return tomb
