-- Theory of operation: a selected exit MAP owns the minotaur and final
-- terrain. Most exits share the source's seven-to-sixteen-item reward
-- pile at the < glyph. The exceptional dead-adventurer exit has its own
-- hook because its corpse themes and items are authored differently.
local directives = require("constants.vault_directives")

local shared = {}

local standard_loot =
    "superb_item w:49 / any armour w:7 / " ..
    "any wand w:14 / any scroll"

-- random2avg(10, 2) draws [0, 10), then [0, 11), and floors their
-- average. Keep the source draw count so reward counts stay seed-stable.
function shared.loot(api)
    local count = 7 + math.floor((api:roll(10) + api:roll(11)) / 2)
    local items = {}

    for _ = 1, count do
        if api:one_in(3) then
            items[#items + 1] = "star_item"
        else
            items[#items + 1] = standard_loot
        end
    end

    api:emit(directives.KITEM,
        "< = " .. table.concat(items, ", "))
end

-- The source mini-maze retries its letter shuffle until one < remains.
-- Placement calls this after all keyed substitutions, before commit.
function shared.has_exit(api)
    for _, row in ipairs(api.cells) do
        for _, glyph in ipairs(row) do
            if glyph == "<" then
                return true
            end
        end
    end

    return false
end

return shared
