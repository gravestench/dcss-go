local source = require("data.presentation")

local menu = {}

local function choices(category, source_groups, source_descriptions, added_label)
    local groups = {}
    local descriptions = {}
    local seen = {}

    for _, source_group in ipairs(source_groups) do
        local group = {
            label = source_group.label,
            ids = {},
        }

        for _, id in ipairs(source_group.ids) do
            local definition = register.get(category, id)

            if definition.selectable then
                group.ids[#group.ids + 1] = id
                descriptions[id] = definition.description or source_descriptions[id]
                seen[id] = true
            end
        end

        groups[#groups + 1] = group
    end

    local added = {
        label = added_label,
        ids = {},
    }

    for _, id in ipairs(register.ids(category)) do
        local definition = register.get(category, id)

        if definition.selectable and not seen[id] then
            added.ids[#added.ids + 1] = id
            descriptions[id] = definition.description or definition.name
        end
    end

    if #added.ids > 0 then
        groups[#groups + 1] = added
    end

    return groups, descriptions
end

function menu.presentation()
    local species_groups, species_descriptions = choices(
        "species", source.species_groups, source.species_descriptions,
        "Modded species")
    local job_groups, job_descriptions = choices(
        "jobs", source.job_groups, source.job_descriptions,
        "Modded backgrounds")

    return {
        startup_modes = source.startup_modes,
        skill_columns = source.skill_columns,
        species_groups = species_groups,
        job_groups = job_groups,
        species_descriptions = species_descriptions,
        job_descriptions = job_descriptions,
    }
end

register.policy({
    id = "character.menu",
    run = function()
        return menu.presentation()
    end,
})

return menu
