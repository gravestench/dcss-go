local catalog = require("policy.catalog")
local colors = require("policy.presentation.colors")
local failure = require("policy.magic.failure")
local menu = require("policy.input.menu")
local spell_input = require("policy.input.spells")

local function write(writes, x, y, text, color)
    writes[#writes + 1] = {
        x = x,
        y = y,
        text = text,
        fg = color,
    }
end

local spells = {}

function spells.run(ctx, input)
    local mode = input.mode
    local learning = mode == "spell_memorise"
    local selected = spell_input.choices(input)
    local writes = {}
    local title = learning and "Memorise which spell?" or "Cast which spell?"

    if mode == "spell_force" then
        title = "Force cast which spell?"
    end

    write(writes, 0, 0, title, colors.white)
    write(writes, 0, 1,
        "        Spell                    Type                 Failure  Level",
        colors.light_blue)

    for index, record in ipairs(selected) do
        local y = index + 2

        if y >= input.height - 2 then
            break
        end

        local spell = catalog.get("spells", record.id)
        local letter = learning and menu.letter(index) or
            menu.letter(record.letter_slot)
        local schools = table.concat(spell.schools or {}, "/")
        local chance = "--"

        if not learning then
            local profile = failure.profile(ctx, ctx:player(), spell)
            chance = profile.percent .. "%"
        end

        local label = string.format("  %s - %-25.25s %-20.20s %7s %6d",
            letter, spell.name, schools, chance, spell.level)

        write(writes, 0, y, label, colors.light_grey)
    end

    if #selected == 0 then
        local empty = learning and "Your spell library is empty." or
            "You do not know any spells."

        write(writes, 0, 3, empty, colors.brown)
    end

    write(writes, 0, input.height - 2,
        "Esc - Cancel    ? - Help", colors.brown)

    return { writes = writes }
end

register.policy({
    id = "presentation.spells",
    run = spells.run,
})

return spells
