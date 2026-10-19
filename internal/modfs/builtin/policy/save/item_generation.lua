local catalog = require("policy.catalog")
local component = require("constants.component")
local history = require("policy.item_generation.artefacts.history")
local ids = require("ids.items")
local item_sets = require("policy.item_generation.item_sets")
local skills = require("ids.skills")

local validation = {}

-- Validate the player's generation ledger before checking individual item provenance.
local function validate_player(ctx)
    local player = ctx:player()

    item_sets.validate(ctx:get(player, component.PLAYER_ITEM_SETS))
    history.validate(ctx:get(player, component.PLAYER_UNIQUE_HISTORY))
end

-- A manual's skill and 2000..3000 point budget must travel with its BOOK_MANUAL item across saves.
local function validate_manual(ctx, entity, item)
    local manual = ctx:get(entity, component.ITEM_MANUAL)

    if not manual then
        if item and item.kind_id == ids.BOOK_MANUAL then
            error("saved manual lacks skill state " .. ctx:id(entity))
        end

        return
    end

    if not item or item.kind_id ~= ids.BOOK_MANUAL or
        skills[manual.skill_id] ~= manual.skill_id or
        manual.skill_id == skills.WEAPON_CHOICE or
        manual.points < 2000 or manual.points > 3000 then
        error("invalid saved item manual " .. ctx:id(entity))
    end
end

-- Random-book spell lists are validated before the book can be restored.
local function validate_random_book(ctx, entity, item)
    local book = ctx:get(entity, component.ITEM_RANDOM_BOOK)

    if not book then
        if item and (item.kind_id == ids.BOOK_RANDART_THEME or
            item.kind_id == ids.BOOK_RANDART_LEVEL) then
            error("saved random book lacks spells " .. ctx:id(entity))
        end

        return
    end

    if not item or (item.kind_id ~= ids.BOOK_RANDART_LEVEL and
        item.kind_id ~= ids.BOOK_RANDART_THEME) or
        #book.spells == 0 or
        book.level < 0 or book.level > 9 then
        error("invalid saved random book " .. ctx:id(entity))
    end

    if item.kind_id == ids.BOOK_RANDART_LEVEL and
        (book.level == 0 or book.theme ~= "") or
        item.kind_id == ids.BOOK_RANDART_THEME and
        (book.level ~= 0 or book.theme == "") then
        error("saved random book has incompatible subtype state " ..
            ctx:id(entity))
    end

    local seen = {}

    for _, spell_id in ipairs(book.spells) do
        local okay, spell = pcall(catalog.get, "spells", spell_id)

        if not okay or spell.status ~= "defined" or seen[spell_id] then
            error("invalid saved random book spell " .. tostring(spell_id))
        end

        seen[spell_id] = true
    end
end

-- Saved generation state preserves manuals and random-book metadata for future item use.
-- Example: validation.run(ctx) rejects a saved random book with an invalid spell payload.
function validation.run(ctx)
    validate_player(ctx)

    for _, entity in ipairs(ctx:query({ component.ITEM })) do
        local item = ctx:get(entity, component.ITEM)

        validate_manual(ctx, entity, item)
        validate_random_book(ctx, entity, item)
    end

    for _, entity in ipairs(ctx:query({ component.ITEM_MANUAL })) do
        if not ctx:has(entity, component.ITEM) then
            error("non-item has saved manual state")
        end
    end

    for _, entity in ipairs(ctx:query({ component.ITEM_RANDOM_BOOK })) do
        if not ctx:has(entity, component.ITEM) then
            error("non-item has saved random book state")
        end
    end

    return {}
end

register.policy({
    id = "save.validate_item_generation",
    run = validation.run,
})

return validation
