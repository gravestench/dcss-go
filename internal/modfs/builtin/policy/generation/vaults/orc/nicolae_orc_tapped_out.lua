-- Shafts cannot descend past the last Orc floor. The source replaces the
-- shaft candidate glyph before the common trap resolution on Orc:2.
local directives = require("constants.vault_directives")

local handler = {}

-- Change only the final-floor substitutions; Orc:1 retains its source
-- shaft chance and uses the same static KFEAT declaration.
local function suppress_final_shaft(api)
    if api:depth() == api:branch_bottom() then
        api:emit(directives.SUBST, "^ = .:5 d:4")
    end
end

handler.suppress_final_shaft = suppress_final_shaft

return handler
