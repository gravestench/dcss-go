local catalog = require("policy.catalog")
local effects = require("policy.combat.monster_spells")
local book_ids = require("ids.monster_spellbooks")

local coverage = {}

-- Keep book, slot, and reason together so missing resolver reports identify the broken content.
local function add(missing, monster_id, book_id, spell_id, reason)
    missing[#missing + 1] = {
        monster_id = monster_id,
        book_id = book_id,
        spell_id = spell_id,
        reason = reason,
    }
end

-- Coverage requires both plan and resolve methods for every slot in a registered monster spellbook.
local function inspect_book(missing, monster_id, book_id)
    local okay, book = pcall(catalog.get, "monster_spellbooks", book_id)

    if not okay then
        add(missing, monster_id, book_id, "", "missing spellbook")

        return
    end

    for _, slot in ipairs(book.slots) do
        local effect_ok, effect = pcall(effects.effect, slot.spell_id)

        if not effect_ok then
            add(missing, monster_id, book_id, slot.spell_id,
                "missing effect module")
        elseif type(effect) ~= "table" or
            type(effect.plan) ~= "function" then
            add(missing, monster_id, book_id, slot.spell_id,
                "effect has no plan method")
        elseif type(effect.resolve) ~= "function" then
            add(missing, monster_id, book_id, slot.spell_id,
                "effect has no resolve method")
        end
    end
end

-- Example: coverage.missing(monster_ids) with missing spell resolver -> entry identifying monster and spell
-- Sort monster ids so missing-effect reports are stable across Lua table iteration orders.
function coverage.missing(monster_ids)
    local ids = {}
    local missing = {}

    for id, allowed in pairs(monster_ids) do
        if allowed then
            ids[#ids + 1] = id
        end
    end

    table.sort(ids)

    for _, id in ipairs(ids) do
        local monster = catalog.get("monsters", id)
        local book_id = monster.spellbook_id

        if book_id and book_id ~= "" and
            book_id ~= book_ids.MST_NO_SPELLS then
            inspect_book(missing, id, book_id)
        end
    end

    return missing
end

return coverage
