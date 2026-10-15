local skills = require("ids.skills")
local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local colors = require("policy.presentation.colors")
local presentation = require("data.presentation")
local distributed = require("policy.character.distributed_training")

local skills_policy = {}

local special_names = {
    [skills.SK_MACES_FLAILS] = "Maces & Flails",
    [skills.SK_UNARMED_COMBAT] = "Unarmed Combat",
    [skills.SK_SHORT_BLADES] = "Short Blades",
    [skills.SK_LONG_BLADES] = "Long Blades",
}

local function capitalize(word)
    return word:sub(1, 1):upper() .. word:sub(2)
end

local function skill_name(id)
    if special_names[id] then
        return special_names[id]
    end

    local name = id:gsub("^SK_", ""):gsub("_", " "):lower()

    return name:gsub("%a+", capitalize)
end

local function letter(index)
    if index < 26 then
        return string.char(string.byte("a") + index)
    end

    return string.char(string.byte("A") + index - 26)
end

local function write(writes, x, y, text, fg)
    writes[#writes + 1] = { x = x, y = y, text = text, fg = fg }
end

function skills_policy.rows(ctx, input)
    local writes = {}
    write(writes, 0, 0, "Skills", colors.white)
    write(writes, 1, 2, "Skill                 Level Apt Train", colors.light_blue)
    write(writes, 40, 2, "Skill                 Level Apt Train", colors.light_blue)
    local species = catalog.get("species", input.species_id)
    local player = ctx:player()
    local levels = {}
    local settings = {}

    for _, skill in ipairs(input.skills) do
        if not species.aptitudes[skill.id] then
            write(writes, 0, 0, "Skills unavailable: invalid species skill", colors.light_red)
            return { writes = writes }
        end

        local aptitude = formulas.effective_skill_aptitude(ctx, player,
            species, skill.id)
        levels[skill.id] = formulas.scaled_skill(skill, 10, aptitude)
    end

    for _, setting in ipairs(input.skill_training.settings) do
        settings[setting.id] = setting
    end

    local index = 0

    for column, ids in ipairs(presentation.skill_columns) do
        local x = 1 + (column - 1) * 39

        for row, id in ipairs(ids) do
            if id ~= "" then
                local aptitude = formulas.effective_skill_aptitude(ctx,
                    player, species, id)
                local level = levels[id] or 0
                local setting = settings[id] or {}
                local training = "--"

                if setting.enabled then
                    training = (input.skill_percent[id] or 0) .. "%"
                end

                if setting.focused then
                    training = "*" .. training
                end

                local label = string.format("%s - %-18s %4.1f %+2d %5s",
                    letter(index), skill_name(id), level / 10, aptitude, training)
                local color = level > 0 and colors.light_grey or colors.dark_grey
                write(writes, x, 2 + row, label, color)
                index = index + 1
            end
        end
    end

    if distributed.active(ctx, player) then
        write(writes, 0, input.height - 4,
            "! - view    ? - help    Esc - Return", colors.brown)
        write(writes, 0, input.height - 3,
            "Gnolls train all skills equally", colors.brown)
    else
        write(writes, 0, input.height - 5,
            "/ - mode    | - skill    * - skills    ! - view", colors.brown)
        write(writes, 0, input.height - 4,
            "= - target    ? - help    Esc - Return", colors.brown)
        local mode = input.skill_training.manual and
            "Manual training" or "Automatic training"
        local action = input.focus_action and "focus" or "toggle"
        write(writes, 0, input.height - 3,
            mode .. " | Skill letters: " .. action, colors.brown)
    end

    return { writes = writes }
end

function skills_policy.run(ctx, input)
    return skills_policy.rows(ctx, input)
end

register.policy({
    id = "presentation.skills",
    run = skills_policy.run,
})

return skills_policy
