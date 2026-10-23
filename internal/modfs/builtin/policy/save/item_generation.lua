local catalog = require("policy.catalog")
local component = require("constants.component")
local history = require("policy.item_generation.artefacts.history")
local monster_history = require("policy.population.unique_history")
local runes = require("policy.character.runes")
local endgame = require("policy.character.endgame")
local phases = require("constants.endgame")
local branch_levels = require("policy.generation.branch_levels")
local branches = require("ids.branches")
local ids = require("ids.items")
local classes = require("ids.object_classes")
local item_sets = require("policy.item_generation.item_sets")
local skills = require("ids.skills")
local tithe_states = require("constants.zin_tithe_state")
local abyss = require("constants.abyss")

local validation = {}

-- Validate the player's generation ledger before checking individual item provenance.
local function validate_player(ctx)
    local player = ctx:player()

    item_sets.validate(ctx:get(player, component.PLAYER_ITEM_SETS))
    history.validate(ctx:get(player, component.PLAYER_UNIQUE_HISTORY))
    monster_history.validate(ctx:get(player, component.PLAYER_UNIQUE_HISTORY))
    runes.validate(ctx:get(player, component.PLAYER_RUNES))
    endgame.validate(ctx:get(player, component.PLAYER_ENDGAME))
end

-- The Orb is a single physical floor item until pickup changes the saved
-- chapter. A carried Orb or a second copy could otherwise create a false win
-- after restore, so validate its relationship to that chapter explicitly.
local function validate_orb(ctx)
    local phase = endgame.phase(ctx, ctx:player())
    local count = 0

    for _, entity in ipairs(ctx:query({ component.ITEM })) do
        local item = ctx:get(entity, component.ITEM)

        if item.kind_id == ids.ORB_ZOT then
            count = count + 1

            if ctx:has(entity, component.CARRIED_BY) then
                error("Orb of Zot cannot be carried as an item")
            end
        end
    end

    if count > 1 or
        (count ~= 0 and
            (phase == phases.ESCAPING or phase == phases.WON)) then
        error("saved Orb item conflicts with player endgame phase")
    end

    -- After Zot:5 is generated, its authored Orb must still exist until
    -- pickup. Its disappearance during exploration is a damaged save, not
    -- an implicit chapter transition. An Orb-less loss leaves it in place.
    local hall_id = branch_levels.id(branches.BRANCH_ZOT, 5)
    local hall_width = ctx:level_size(hall_id)

    if hall_width and
        (phase == phases.EXPLORING or phase == phases.LEFT) and
        count ~= 1 then
        error("generated Hall is missing its Orb of Zot")
    end
end

-- The Abyssal rune is a single floor entity until pickup transfers its
-- identity to permanent player progress. A spare copy on another level
-- or after collection would grant a second rune on restore.
function validation.abyssal_rune(ctx)
    local collected = runes.has(ctx, ctx:player(), ids.RUNE_ABYSSAL)
    local count = 0

    for _, entity in ipairs(ctx:query({ component.ITEM })) do
        local item = ctx:get(entity, component.ITEM)

        if item.kind_id == ids.RUNE_ABYSSAL then
            count = count + 1
            local position = ctx:get(entity, component.POSITION)

            if not position or
                position.level_id ~= abyss.LEVEL_ID or
                ctx:has(entity, component.CARRIED_BY) or
                not ctx:session_state(abyss.SESSION_STATE) then
                error("saved Abyssal rune has no active floor")
            end
        end
    end

    if count > 1 or (count > 0 and collected) then
        error("saved Abyssal rune conflicts with player progress")
    end
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

-- A saved gold tag must belong to a real gold item and name one source
-- tithe state. Otherwise restore could silently change tax or piety later.
local function validate_gold_tithe(ctx, entity, item)
    local tithe = ctx:get(entity, component.GOLD_TITHE)

    if not tithe then
        return
    end

    local state = tithe.state
    local known = state == tithe_states.DEFAULT or
        state == tithe_states.NO_PIETY or
        state == tithe_states.FULL_TITHE or
        state == tithe_states.NO_TITHE

    if not item or
        catalog.get("items", item.kind_id).class ~= classes.OBJ_GOLD or
        not known then
        error("invalid saved gold tithe state " .. ctx:id(entity))
    end
end

-- Saved generation state preserves manuals and random-book metadata for future item use.
-- Example: validation.run(ctx) rejects a saved random book with an invalid spell payload.
function validation.run(ctx)
    validate_player(ctx)
    validate_orb(ctx)
    validation.abyssal_rune(ctx)

    for _, entity in ipairs(ctx:query({ component.ITEM })) do
        local item = ctx:get(entity, component.ITEM)

        validate_manual(ctx, entity, item)
        validate_random_book(ctx, entity, item)
        validate_gold_tithe(ctx, entity, item)
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

    for _, entity in ipairs(ctx:query({ component.GOLD_TITHE })) do
        if not ctx:has(entity, component.ITEM) then
            error("non-item has saved gold tithe state")
        end
    end

    return {}
end

register.policy({
    id = "save.validate_item_generation",
    run = validation.run,
})

return validation
