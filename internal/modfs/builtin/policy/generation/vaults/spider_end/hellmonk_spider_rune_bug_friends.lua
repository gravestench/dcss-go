-- Theory of operation: this Spider ending deliberately has no ordinary
-- spiders. Two independent three-way source choices set large-monster
-- density and ruin density before the authored MAP is transformed.
local directives = require("constants.vault_directives")

local handler = {}

-- Sequential source chances bias the 7 monster slots without a third draw.
local function choose_monsters(api)
    if api:one_in(3) then
        api:emit(directives.SUBST, "7 = 44456")
    elseif api:one_in(2) then
        api:emit(directives.SUBST, "7 = 45556")
    else
        api:emit(directives.SUBST, "7 = 45666")
    end
end

-- Ruination is a separate choice, so monster and terrain rolls can combine.
local function choose_ruins(api)
    if api:one_in(3) then
        api:emit(directives.SUBST, "A = cc.")
    elseif api:one_in(2) then
        api:emit(directives.SUBST, "A = c.")
    else
        api:emit(directives.SUBST, "A = c..")
    end
end

handler.choose_monsters = choose_monsters
handler.choose_ruins = choose_ruins

return handler
