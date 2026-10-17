local catalog = require("policy.catalog")
local flags = require("constants.monster_spell_flags")
local spell_flags = require("constants.spell_flags")

local prospect = {}

local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function allowed_by_silence(slot, condition)
    if not condition.silenced then
        return true
    end

    -- Source MON_SPELL_SILENCE_MASK leaves natural and magical abilities.
    return not has(slot.flags, flags.WIZARD) and
        not has(slot.flags, flags.PRIEST) and
        not has(slot.flags, flags.VOCAL)
end

local function eligible(slot, condition)
    if not allowed_by_silence(slot, condition) then
        return false
    end

    if has(slot.flags, flags.EMERGENCY) and
        condition.hp >= math.floor(condition.max_hp / 3) then
        return false
    end

    if has(slot.flags, flags.SHORT_RANGE) and
        condition.distance >= 3.5 then
        return false
    end

    if has(slot.flags, flags.LONG_RANGE) and
        condition.distance <= 3.5 then
        return false
    end

    return true
end

local function matching_spell(slot, wanted)
    local definition = catalog.get("spells", slot.spell_id)

    return has(definition.flags, wanted)
end

local function preferred_slot(book, condition, random, wanted)
    local selected = nil
    local selected_index = nil
    local weight = 0

    for index, slot in ipairs(book.slots) do
        if allowed_by_silence(slot, condition) and
            matching_spell(slot, wanted) then
            weight = weight + slot.frequency

            -- Source _pick_spell_from_list uses reservoir weighting.
            if random(weight) < slot.frequency then
                selected = slot
                selected_index = index
            end
        end
    end

    return selected, selected_index
end

local function normal_slot(book, condition, random)
    local remaining = random(200)

    for index, slot in ipairs(book.slots) do
        if eligible(slot, condition) then
            -- Source _find_spell_prospect uses an inclusive comparison.
            if slot.frequency >= remaining then
                return slot, index
            end

            remaining = remaining - slot.frequency
        end
    end

    return nil
end

function prospect.choose(book, condition, random, preferred)
    if preferred then
        return preferred_slot(book, condition, random, preferred)
    end

    if condition.fleeing then
        return preferred_slot(book, condition, random, spell_flags.ESCAPE)
    end

    return normal_slot(book, condition, random)
end

return prospect
