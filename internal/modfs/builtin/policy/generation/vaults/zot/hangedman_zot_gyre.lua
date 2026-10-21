-- The Gyre offers a smaller exit set on Zot's final floor. The map owns
-- its stair glyphs; this method only supplies the source depth choice.
local directives = require("constants.vault_directives")

local handler = {}

-- On Zot:5 a stair can only return upward. Earlier floors may also carry
-- down exits, so the same source MAP serves both contexts.
local function choose_final_stairs(api)
    if api:depth() == api:branch_bottom() then
        api:emit(directives.SUBST, "{ = {([<")
    else
        api:emit(directives.SUBST, "{ = {([<})]>%")
    end
end

handler.choose_final_stairs = choose_final_stairs

return handler
