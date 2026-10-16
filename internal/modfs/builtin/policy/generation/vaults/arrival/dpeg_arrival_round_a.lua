local directives = require("constants.vault_directives")

local handler = {}

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

local function choose_second_ring(api)
    if api:roll(3) == 0 then
        api:emit(directives.SUBST, "B = .")
        api:emit(directives.SUBST, "b = x")

        return
    end

    api:emit(directives.SUBST, "B = '")
    api:emit(directives.SUBST, "b = x")
end

-- Port of arrival/small.des:1715-1735. The second draw always follows the first.
local function choose_round_layout(api)
    choose_first_ring(api)
    choose_second_ring(api)
end

handler.choose_round_layout = choose_round_layout

return handler
