-- Example: The first spiral weights terrain and obstacle glyphs without adding water.
local directives = require("constants.vault_directives")

local handler = {}

-- The first spiral weights terrain and obstacle glyphs without adding water.
local function choose_first_spiral(api)
    api:emit(directives.SUBST, "G : G:20 H:20 T:5 V:5 1:5 2:5 t:5 A:1 B:1 C:1")
    api:emit(directives.SUBST, "c : c:40 x:35 v:15 b:10")
end

-- The second spiral lays water first, then chooses its own obstacle weights.
local function choose_second_spiral(api)
    api:emit(directives.SUBST, ". = W")
    api:emit(directives.SUBST, "' = W.")
    api:emit(directives.SUBST, "G : 2:15 G:10 H:5 1:5 A:1 B:1 C:1")
    api:emit(directives.SUBST, "c : t:60 x:30 c:10")
end

-- Later variants draw fresh one-in-four and one-in-six tests after both main choices fail.
local function choose_other_spiral(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, ". = W")
        api:emit(directives.SUBST, "' = WW.")
    elseif api:one_in(6) then
        api:emit(directives.SUBST, "c = W")
    end

    api:emit(directives.SUBST, "c : t:45")
    api:emit(directives.SUBST, "G : G:40 H:30 2:10 1:5 A:3 B:2")
end

-- The second spiral choice is drawn only when the first coinflip fails, then variants edit glyphs.
local function choose_spiral_variant(api)
    if api:coinflip() then
        choose_first_spiral(api)
    elseif api:coinflip() then
        choose_second_spiral(api)
    else
        choose_other_spiral(api)
    end
end

handler.choose_spiral_variant = choose_spiral_variant

return handler
