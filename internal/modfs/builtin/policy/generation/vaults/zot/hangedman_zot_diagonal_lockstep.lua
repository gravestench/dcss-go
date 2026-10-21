-- Lockstep's optional exit and trap positions change at Zot:1 and Zot:5.
-- Its other substitutions remain in the DES where a modder sees the MAP.
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve the source order: the terminal floor has no down exit; the
-- first floor has a different weighted entrance set from middle floors.
local function choose_depth_stairs(api)
    if api:depth() == api:branch_bottom() then
        api:emit(directives.SUBST, "{ = {([ <:5 Z:5")
    elseif api:depth() == 1 then
        api:emit(directives.SUBST, "{ = {:40 })]> d:20 Z:20")
    else
        api:emit(directives.SUBST, "{ = {([<})]> d:20 Z:20")
    end
end

handler.choose_depth_stairs = choose_depth_stairs

return handler
