-- Example: One four-way draw fixes the inner ring before outer-ring randomness.
local directives = require("constants.vault_directives")

local handler = {}

-- One four-way draw fixes the inner ring before outer-ring randomness.
local function choose_first_ring(api)
    local roll = api:roll(4)

    if roll == 0 then
        api:emit(directives.SUBST, "? = x")
        api:emit(directives.SUBST, "A = .")
        api:emit(directives.SUBST, "a = +")
    elseif roll == 1 then
        api:emit(directives.SUBST, "? = +")
        api:emit(directives.SUBST, "A = .")
        api:emit(directives.SUBST, "a = x")
    else
        api:emit(directives.SUBST, "? = +")
        api:emit(directives.SUBST, "A = '")
        api:emit(directives.SUBST, "a = +")
    end
end

-- The separate three-way draw chooses whether B is open floor or translucent floor.
local function choose_second_ring(api)
    if api:roll(3) == 0 then
        api:emit(directives.SUBST, "B = .")
        api:emit(directives.SUBST, "b = x")

        return
    end

    api:emit(directives.SUBST, "B = '")
    api:emit(directives.SUBST, "b = x")
end

-- The first ring chooses walls, doors, or translucent floor before the independent outer ring draw.
local function choose_round_layout(api)
    choose_first_ring(api)
    choose_second_ring(api)
end

handler.choose_round_layout = choose_round_layout

return handler
