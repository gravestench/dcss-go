-- Theory of operation: fixed book definitions decide which spells players
-- can find in books. The registry closes after all mod layers load, so a
-- derived membership set can be reused during repeated spell-scope checks.
-- An accessor replacement invalidates that set in registry-overlay tests.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")

local books = {}
local cached_ids
local cached_get
local cached_list

-- Return a copy so callers cannot alter the shared derived membership set.
local function copy_ids(ids)
    local result = {}

    for id in pairs(ids) do
        result[id] = true
    end

    return result
end

-- Collect one set from all fixed book templates. Resolve every reference
-- through the spell catalog so a misspelled mod ID fails where it enters
-- the pool, not much later during a gift or cast.
function books.ids()
    if register.frozen() and cached_ids and
        cached_get == register.get and
        cached_list == register.ids then
        return copy_ids(cached_ids)
    end

    local selected = {}

    for _, item in ipairs(catalog.all(categories.ITEMS)) do
        if item.class == classes.OBJ_BOOKS then
            local generation = item.generation or {}

            for _, id in ipairs(generation.spells or {}) do
                catalog.get(categories.SPELLS, id)
                selected[id] = true
            end
        end
    end

    if register.frozen() then
        cached_ids = selected
        cached_get = register.get
        cached_list = register.ids
    end

    return copy_ids(selected)
end

-- DCSS scans its numeric spell enum for seeded candidate draws. Unnumbered
-- mod spells follow in ID order so adding a Lua file cannot perturb source
-- candidate order based on file names or filesystem enumeration.
function books.ordered()
    local selected = books.ids()
    local result = {}

    for _, spell in ipairs(catalog.all(categories.SPELLS)) do
        if selected[spell.id] and spell.status == "defined" then
            result[#result + 1] = spell
        end
    end

    table.sort(result, function(left, right)
        local left_order = left.numeric_id or math.huge
        local right_order = right.numeric_id or math.huge

        if left_order == right_order then
            return left.id < right.id
        end

        return left_order < right_order
    end)

    return result
end

return books
