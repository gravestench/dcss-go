local directives = require("constants.vault_directives")

local setup = {}

-- Focused port of dat/dlua/vault.lua:34-94. Emission order matters because
-- each substitution sees the cells left by the preceding substitution.
function setup.random_room(api)
    api:emit(directives.TAGS, "no_pool_fixup transparent")

    if api:one_in(2) then
        api:emit(directives.SUBST, "D : +")
        api:emit(directives.SUBST, "E : .")

        if api:one_in(2) then
            api:emit(directives.SUBST, "F : +")
            api:emit(directives.SUBST, "H : .")
        else
            api:emit(directives.SUBST, "F : c")
            api:emit(directives.SUBST, "H : w")
        end
    else
        api:emit(directives.SUBST, "DF : c")
        api:emit(directives.SUBST, "EH : w")
    end

    api:emit(directives.SUBST, "w : w.")
    api:emit(directives.SUBST, "w : wwwWWqq")

    local variant = api:roll(3)

    if variant == 0 then
        api:emit(directives.SUBST, "t : x")
        api:emit(directives.SUBST, "x : cvbttm")
    elseif variant == 1 then
        api:emit(directives.SUBST, "x : ..wW")
        api:emit(directives.SUBST, "t : .TmbttwG")
    else
        api:emit(directives.SUBST, "t : .TttG")
        api:emit(directives.SUBST, "x : cvbtt")
    end

    api:emit(directives.SUBST, "q : t")
    api:emit(directives.SUBST, "c : ccccxxxxvb")

    if api:one_in(3) then
        api:emit(directives.SUBST, "Wwt : l")
        api:emit(directives.SUBST, "T : V")
    end
end

-- Focused port of the shop-only function in builder/shops.des:26-53.
function setup.shop_or_temple(api, decoration)
    if api:validating() then
        api:emit(directives.SUBST, "O = B")

        return
    end

    local tag = api:map_tag()

    if tag == "shop" then
        api:emit(directives.KFEAT, "O = any shop")
    elseif tag and tag:find("temple_overflow_generic_", 1, true) then
        api:emit(directives.SUBST, "O = B")
    else
        api:emit(directives.TAGS, "extra decor")
        api:emit(directives.SUBST, "O = " .. decoration)
    end
end

return setup
