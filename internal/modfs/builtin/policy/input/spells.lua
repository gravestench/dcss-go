local catalog = require("policy.catalog")
local commands = require("policy.input.commands")
local menu = require("policy.input.menu")

local spells = {}

local function memorise_before(left, right)
    local a = catalog.get("spells", left.id)
    local b = catalog.get("spells", right.id)

    if a.level ~= b.level then
        return a.level < b.level
    end

    return a.name < b.name
end

local function known_before(left, right)
    return left.letter_slot < right.letter_slot
end

local function choices(input)
    local selected = {}
    local learning = input.mode == "spell_memorise"

    for _, record in ipairs(input.spells or {}) do
        if (learning and record.in_library and record.known_slot == 0) or
            (not learning and record.known_slot > 0) then
            selected[#selected + 1] = record
        end
    end

    if learning then
        table.sort(selected, memorise_before)
    else
        table.sort(selected, known_before)
    end

    return selected
end

spells.choices = choices

local function needs_aim(spell)
    for _, flag in ipairs(spell.flags or {}) do
        if flag == "target" or flag == "dir" or
            flag == "dir_or_target" then
            return true
        end
    end

    return false
end

function spells.route(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    local mode = input.mode

    if mode ~= "spell_cast" and mode ~= "spell_force" and
        mode ~= "spell_memorise" then
        error("unknown spell input mode " .. tostring(mode))
    end

    local available = choices(input)
    local chosen

    if input.key == "enter" and mode ~= "spell_memorise" then
        for _, record in ipairs(available) do
            if record.id == input.last_spell_id then
                chosen = record
                break
            end
        end
    else
        for index, record in ipairs(available) do
            local letter = mode == "spell_memorise" and
                menu.letter(index) or menu.letter(record.letter_slot)

            if input.key == letter then
                chosen = record
                break
            end
        end
    end

    if not chosen then
        return {
            action = "notice",
            text = mode == "spell_memorise" and
                "Choose a spell from your library." or
                "You don't know that spell.",
        }
    end

    local kind = commands.cast

    if mode == "spell_force" then
        kind = commands.force_cast
    elseif mode == "spell_memorise" then
        kind = commands.memorise
    end

    local definition = catalog.get("spells", chosen.id)

    if mode ~= "spell_memorise" and needs_aim(definition) then
        return {
            action = "aim",
            kind = kind,
            spell_id = chosen.id,
        }
    end

    return {
        action = "spell_step",
        kind = kind,
        spell_id = chosen.id,
    }
end

return spells
