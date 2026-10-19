-- Example: Two copies of a spell on different owners do not share a memorisation slot.
local catalog = require("policy.catalog")
local player_scope = require("policy.magic.player_scope")

local records = {}

-- Collect only spell entities owned by this player before slot or library decisions.
function records.list(ctx, owner)
    local found = {}

    for _, entity in ipairs(ctx:query({ "character.spell" })) do
        local record = ctx:get(entity, "character.spell")

        if record.owner == owner then
            found[#found + 1] = {
                entity = entity,
                state = record,
            }
        end
    end

    return found
end

-- Find a spell within the owner-filtered list so identical spells on another actor cannot leak.
function records.find(ctx, owner, spell_id)
    for _, entry in ipairs(records.list(ctx, owner)) do
        if entry.state.spell_id == spell_id then
            return entry
        end
    end

    return nil
end

-- Choose the first unused hotkey slot rather than renumbering existing spells.
function records.next_slot(ctx, owner, field)
    local used = {}

    for _, entry in ipairs(records.list(ctx, owner)) do
        if entry.state[field] > 0 then
            used[entry.state[field]] = true
        end
    end

    for slot = 1, 52 do
        if not used[slot] then
            return slot
        end
    end

    error("no free " .. field .. " for a spell")
end

-- Djinni level grants consume the spell schedule committed at start instead of drawing a new spell.
function records.grant_scheduled(ctx, owner, level)
    for _, entry in ipairs(records.list(ctx, owner)) do
        if entry.state.future_level == level and
            entry.state.known_slot == 0 then
            entry.state.known_slot = records.next_slot(ctx, owner, "known_slot")
            entry.state.letter_slot = records.next_slot(ctx, owner, "letter_slot")
            ctx:set(entry.entity, "character.spell", entry.state)

            local spell = catalog.get("spells", entry.state.spell_id)
            ctx:emit("spell-learn", "You learn " .. spell.name .. ".")
        end
    end
end

-- Starting spell knowledge is assembled before entities are created. This
-- keeps one durable record per spell even when the job both knows it and has
-- it in its library.
-- Merge known, library, and future innate data before creating one record per spell.
function records.start(ctx, owner, library, known, future)
    local by_id = {}
    local ordered = {}

    -- Validate book-scope spell IDs before creating durable spell records.
    local function entry(id)
        catalog.get("spells", id)

        if player_scope.of(id) ~= "book" then
            error("invalid starting player spell " .. id)
        end

        local record = by_id[id]

        if record then
            return record
        end

        record = {
            owner = owner,
            spell_id = id,
            in_library = false,
            known_slot = 0,
            letter_slot = 0,
            future_level = 0,
        }

        by_id[id] = record
        ordered[#ordered + 1] = record

        return record
    end

    for _, id in ipairs(library) do
        entry(id).in_library = true
    end

    for slot, id in ipairs(known) do
        local record = entry(id)

        if record.known_slot ~= 0 then
            error("duplicate known starting spell " .. id)
        end

        record.known_slot = slot
        record.letter_slot = slot
    end

    -- Source: ng-setup.cc:_setup_innate_spells. Djinni receive the saved
    -- sequence at XL 3 and every odd XL through 27.
    for index, id in ipairs(future) do
        local record = entry(id)

        if record.future_level ~= 0 then
            error("duplicate future innate spell " .. id)
        end

        record.future_level = 2 * index + 1
    end

    for _, record in ipairs(ordered) do
        local entity = ctx:create()
        ctx:add(entity, "character.spell", record)
    end

    ctx:add(owner, "character.spellcasting", {})
end

-- Reject duplicate records and inconsistent slot ownership during restore validation.
function records.validate(ctx, owner)
    local casting = ctx:get(owner, "character.spellcasting")

    if not casting then
        error("player lacks spellcasting state")
    end

    local ids = {}
    local slots = {}
    local letters = {}

    for _, entity in ipairs(ctx:query({ "character.spell" })) do
        local record = ctx:get(entity, "character.spell")

        if record.owner ~= owner then
            error("spell record has an invalid owner")
        end

        if record.spell_id == "" or ids[record.spell_id] then
            error("duplicate or empty player spell record")
        end

        local spell = catalog.get("spells", record.spell_id)

        if spell.status ~= "defined" then
            error("invalid player spell " .. record.spell_id)
        end

        if player_scope.of(record.spell_id) == "none" then
            error("invalid player spell " .. record.spell_id)
        end

        ids[record.spell_id] = record

        if record.known_slot < 0 or record.known_slot > 52 then
            error("invalid known spell slot for " .. record.spell_id)
        end

        if record.known_slot > 0 then
            if slots[record.known_slot] then
                error("duplicate known spell slot " .. record.known_slot)
            end

            slots[record.known_slot] = true
        end

        if record.letter_slot < 0 or record.letter_slot > 52 or
            (record.known_slot == 0 and record.letter_slot ~= 0) or
            (record.known_slot > 0 and record.letter_slot == 0) then
            error("invalid spell letter slot for " .. record.spell_id)
        end

        if record.letter_slot > 0 then
            if letters[record.letter_slot] then
                error("duplicate spell letter slot " .. record.letter_slot)
            end

            letters[record.letter_slot] = true
        end

        if record.future_level ~= 0 and
            (record.future_level < 3 or record.future_level > 27 or
                record.future_level % 2 == 0) then
            error("invalid future innate spell level for " .. record.spell_id)
        end
    end

    if casting.last_spell_id ~= "" and
        (not ids[casting.last_spell_id] or
            ids[casting.last_spell_id].known_slot == 0) then
        error("last cast spell is not known")
    end

    if casting.learning_remaining < 0 or
        (casting.learning_remaining == 0 and casting.learning_spell_id ~= "") or
        (casting.learning_remaining > 0 and
            (not ids[casting.learning_spell_id] or
                not ids[casting.learning_spell_id].in_library or
                ids[casting.learning_spell_id].known_slot > 0)) then
        error("invalid spell memorisation delay")
    end
end

return records
