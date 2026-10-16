local source = require("data.presentation")
local group_names = require("constants.menu_groups")
local catalog = require("policy.catalog")

local menu = {}

local species_layout = {
    category = "species",
    labels = group_names.species,
    capacities = group_names.species_capacities,
    group_field = "difficulty",
    order_field = "difficulty_priority",
    added_label = group_names.MODDED_SPECIES,
    descending = true,
}

local job_layout = {
    category = "jobs",
    labels = group_names.jobs,
    capacities = group_names.jobs_capacities,
    group_field = "menu_group",
    order_field = "menu_order",
    added_label = group_names.MODDED_BACKGROUNDS,
    descending = false,
}

local function choices(layout, definitions)
    local groups = {}
    local descriptions = {}
    local by_label = {}

    for _, label in ipairs(layout.labels) do
        local group = {
            label = label,
            ids = {},
            rows = {},
        }

        groups[#groups + 1] = group
        by_label[label] = group
    end

    local added = {
        label = layout.added_label,
        ids = {},
    }

    for _, definition in ipairs(definitions or catalog.all(layout.category)) do
        if definition.selectable then
            local group = by_label[definition[layout.group_field]]
            local id = definition.id

            descriptions[id] = definition.description or definition.name

            if group then
                group.rows[#group.rows + 1] = definition
            else
                added.ids[#added.ids + 1] = id
            end
        end
    end

    for index, group in ipairs(groups) do
        table.sort(group.rows, function(left, right)
            if layout.descending then
                return left[layout.order_field] > right[layout.order_field]
            end

            return left[layout.order_field] < right[layout.order_field]
        end)

        for row, definition in ipairs(group.rows) do
            if row <= layout.capacities[index] then
                group.ids[#group.ids + 1] = definition.id
            else
                -- The original screen reserves a fixed number of rows here.
                added.ids[#added.ids + 1] = definition.id
            end
        end

        group.rows = nil
    end

    if #added.ids > 0 then
        groups[#groups + 1] = added
    end

    return groups, descriptions
end

function menu.species_choices(definitions)
    return choices(species_layout, definitions)
end

function menu.job_choices(definitions)
    return choices(job_layout, definitions)
end

function menu.presentation()
    local species_groups, species_descriptions = menu.species_choices()
    local job_groups, job_descriptions = menu.job_choices()

    return {
        startup_modes = source.startup_modes,
        skill_columns = source.skill_columns,
        species_groups = species_groups,
        job_groups = job_groups,
        species_descriptions = species_descriptions,
        job_descriptions = job_descriptions,
    }
end

function menu.run_presentation()
    return menu.presentation()
end

register.policy({
    id = "character.menu",
    run = menu.run_presentation,
})

return menu
