-- Minmay's castle chooses electricity half the time; if that fails, a
-- second coinflip chooses ice or fire. The two independent draws match
-- source probability and random-stream consumption.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit one coherent monster, terrain, cloud, and loot set. Conditional
-- source directives cannot stay bare in DES or all three sets would run.
local function choose_element(api)
    if api:coinflip() then
        api:emit(directives.MONS,
            "titan, storm dragon, electric golem")
        api:emit(directives.SUBST, "F = 3")
        api:emit(directives.ITEM,
            "lightning rod, book of lightning, staff of air, " ..
            "book of storms")

        return
    end

    if api:coinflip() then
        api:emit(directives.MONS, "frost giant, ice dragon")
        api:emit(directives.KMONS, "F = shard shrike")
        api:emit(directives.MARKER,
            'F = lua:fog_machine { cloud_type = "freezing vapour", ' ..
            'pow_min = 5, pow_max = 15, delay = 10, size = 2, ' ..
            'walk_dist = 0, spread_rate = 0 }')
        api:emit(directives.ITEM,
            "wand of iceblast, staff of cold, book of winter, " ..
            "ozocubu's autobiography")
        api:emit(directives.SUBST, "w = l")
        api:emit(directives.SUBST, "W = l..")

        return
    end

    api:emit(directives.MONS, "fire giant, fire dragon")
    api:emit(directives.KMONS, "F = balrug")
    api:emit(directives.MARKER,
        'F = lua:fog_machine { cloud_type = "flame", pow_min = 5, ' ..
        'pow_max = 15, delay = 10, size = 2, walk_dist = 0, ' ..
        'spread_rate = 0 }')
    api:emit(directives.ITEM,
        "book of the dragon, staff of fire, book of fire, " ..
        "book of annihilations")
end

handler.choose_element = choose_element

return handler
