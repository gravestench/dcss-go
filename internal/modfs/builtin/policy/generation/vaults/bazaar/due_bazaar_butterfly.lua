-- The butterfly market alternates which wing walls open into doors.
-- Its other shop and stair substitutions remain authored DES.
local directives = require("constants.vault_directives")

local handler = {}

-- A single source coinflip decides the open wing and solid opposite wall.
local function choose_wings(api)
    if api:coinflip() then
        api:emit(directives.SUBST, [=['=+, "=x, :=x]=])
    else
        api:emit(directives.SUBST, [=['=x, "=., :=.]=])
    end
end

handler.choose_wings = choose_wings

return handler
