-- Example: Open-path edits remove several blockers before optional gates are selected.
local directives = require("constants.vault_directives")

local handler = {}

-- Open-path edits remove several blockers before optional gates are selected.
local function choose_open_path(api)
    api:emit(directives.SUBST, "GHIJ = x")
    api:emit(directives.SUBST, '" = .')
    api:emit(directives.SUBST, "& = @")

    if api:coinflip() then
        api:emit(directives.SUBST, "' = .")
        api:emit(directives.SUBST, "+ = +:40 .:30 1:5 2:5")

        if not api:one_in(3) then
            api:emit(directives.SHUFFLE, "[({")
        end

        return
    end

    api:emit(directives.SUBST, "'(+ = x")
end

-- Shuffle branch markers only in the branch variant that uses them.
local function choose_branching_zigzag(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "H = x")
        api:emit(directives.SHUFFLE, "GHI")
        api:emit(directives.SUBST, "G = I")
        api:emit(directives.SUBST, "H = x")
        api:emit(directives.SUBST, "I : G:3 1:5 2")
        api:emit(directives.SUBST, "J : x d e A V >:5 2:5 1:1")
        api:emit(directives.SUBST, "e = dx")
    else
        if api:coinflip() then
            api:emit(directives.SUBST, "H : .:20 + 1:1")
            api:emit(directives.SUBST, "J = H")
            api:emit(directives.SUBST, "GI =  x")
        end

        api:emit(directives.SUBST, "GIJ : x b:1")
        api:emit(directives.SUBST, "H : G T V:5 1:5 2:1 A:1")
    end
end

-- The closed variant seals alternate markers before selecting its replacement gates.
local function choose_closed_path(api)
    api:emit(directives.SUBST, '"[\'(& = x')
    api:emit(directives.SUBST, "+ = H")

    if api:coinflip() then
        api:emit(directives.SUBST, "GIJ = G")
        api:emit(directives.SUBST, "G : x.")
        api:emit(directives.SUBST, "H : xGc")

        return
    end

    choose_branching_zigzag(api)
end

-- The open, branching, and closed zigzag paths retain their source branch draw order.
local function choose_zigzag_layout(api)
    if api:one_in(3) then
        choose_open_path(api)
    else
        choose_closed_path(api)
    end
end

-- The second one-in-ten draw only occurs if the one-in-three draw fails.
local function choose_zigzag_growth(api)
    if api:one_in(3) then
        api:emit(directives.SUBST, "G = t")
    elseif api:one_in(10) then
        api:emit(directives.SUBST, "x = t")
        api:emit(directives.SUBST, "1 : 2 T")
    end
end

handler.choose_zigzag_layout = choose_zigzag_layout
handler.choose_zigzag_growth = choose_zigzag_growth

return handler
