-- Theory of operation: this glass display starts as a sealed loot case.
-- Before deep Dungeon it always stays loot; later, a depth comparison can
-- open its inner floor and place awake unseen horrors with one of two loot
-- patterns. Each source draw happens only on the branch that needs it.
local directives = require("constants.vault_directives")
local handler = {}

-- Keep shallow displays harmless and avoid a depth roll before D:11.
local function loot_only(api, depth)
    if depth < 11 or api:roll(27) > depth then
        api:emit(directives.SUBST, "a = %")
        api:emit(directives.SUBST, "b = %**")

        return true
    end

    return false
end

-- Source chooses between two item classes after opening the interior.
local function place_loot(api)
    if api:roll(2) == 0 then
        api:emit(directives.KITEM, "a = * / %")
        api:emit(directives.KITEM, "b = *")
    else
        api:emit(directives.KITEM, "a = % / | w:1")
        api:emit(directives.KITEM, "b = |")
    end
end

-- The squared weight makes an inner unseen horror increasingly likely as
-- depth rises; the outer b glyph always requests one on the danger path.
local function place_horrors(api, depth)
    local weight = (depth - 10) * (depth - 10)

    api:emit(directives.KMONS, "a = generate_awake unseen horror w:" ..
        weight .. " / nothing w:40")
    api:emit(directives.KMONS, "b = generate_awake unseen horror")
end

-- Keep generated floor, loot, and monsters in the source operation order.
local function configure(api)
    local depth = api:absolute_depth()

    if loot_only(api, depth) then
        return
    end

    api:emit(directives.KFEAT, "a = .")
    api:emit(directives.KFEAT, "b = .")
    place_loot(api)
    place_horrors(api, depth)
end

handler.configure = configure

return handler
