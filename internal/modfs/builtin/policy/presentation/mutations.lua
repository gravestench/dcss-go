local activity = require("policy.mutations.activity")
local activity_levels = require("constants.mutation_activity")
local catalog = require("policy.catalog")
local capabilities = require("constants.mutation_capabilities")
local colors = require("policy.presentation.colors")
local enum = require("data.mutation_enum")
local effects = require("policy.mutations.effects.registry")
local fakes = require("policy.presentation.mutation_fakes")
local levels = require("policy.mutations.levels")
local mutation_ids = require("ids.mutations")
local records = require("policy.mutations.records")

local mutations = {}

local title = "Innate Abilities, Weirdness & Mutations"
local AC_SCALE = 100
local SH_DISPLAY_SCALE = 2

-- Use DCSS's mutation-screen letters so the option key remains stable while
-- rows are split into innate, acquired, and temporary groups.
local function letter(index)
    if index <= 26 then
        return string.char(string.byte("a") + index - 1)
    end

    return string.char(string.byte("A") + index - 27)
end

-- Build renderer cells instead of printing directly; the terminal can then
-- clip or page the same mutation information at any supported size.
local function write(writes, x, y, text, color)
    writes[#writes + 1] = {
        x = x,
        y = y,
        text = text,
        fg = color,
    }
end

-- Preserve the authored mutation display sequence, then append mod-added IDs
-- from the sorted catalog. This is presentation order, independent of which
-- file was discovered or registered first.
local function display_order()
    local ordered = {}
    local seen = {}

    for _, id in ipairs(enum) do
        ordered[#ordered + 1] = id
        seen[id] = true
    end

    -- New mod definitions follow source IDs without editing the source enum.
    for _, definition in ipairs(catalog.all("mutations")) do
        if not seen[definition.id] then
            ordered[#ordered + 1] = definition.id
        end
    end

    return ordered
end

-- Group actual mutation records by origin while keeping the display sequence
-- inside each group. The screen needs innate facts ahead of temporary ones.
local function ordered_records(ctx, owner)
    local by_id = {}
    local groups = {
        {},
        {},
        {},
    }

    for _, entry in ipairs(records.list(ctx, owner)) do
        by_id[entry.state.mutation_id] = entry.state
    end

    for _, id in ipairs(display_order()) do
        local state = by_id[id]

        if state then
            local group = 2

            if state.innate > 0 then
                group = 1
            elseif state.temporary > 0 then
                group = 3
            end

            groups[group][#groups[group] + 1] = state
        end
    end

    local ordered = {}

    for _, group in ipairs(groups) do
        for _, state in ipairs(group) do
            ordered[#ordered + 1] = state
        end
    end

    return ordered
end

-- Read the definition's use tags instead of guessing from its displayed
-- name; mods can change wording without changing its adverse classification.
local function bad_mutation(definition)
    for _, use in ipairs(definition.uses) do
        if use == "bad" then
            return true
        end
    end

    return false
end

-- Ask the registered effect for a live value rather than duplicating its
-- combat formula in the screen; a missing effect is a broken definition.
local function effect_value(ctx, owner, id, capability, level)
    local handlers = effects.get(id)
    local handler = handlers and handlers[capability]

    if not handler then
        error("mutation " .. id .. " has no display effect")
    end

    return handler(level, ctx, owner)
end

-- Source: mutation.cc:mutation_desc appends live values to these three
-- deliberately unfinished `have` strings. AC uses hundredths and SH uses
-- twice the displayed value in player.cc.
-- Ice Mail displays the current partial AC because equipment and mutation
-- activity can change the value after the mutation was first gained.
local function icemail_description(ctx, owner, level, definition)
    local id = mutation_ids.MUT_ICEMAIL
    local effective = levels.effective(ctx, owner, id)
    local bonus = effect_value(ctx, owner, id,
        capabilities.AC_PARTIAL_X100, effective) / AC_SCALE

    return definition.have[math.min(level, definition.max_level)] ..
        bonus .. ")"
end

-- Condensation Shield stores shield class at twice the printed value, so
-- divide only after asking the live effect for its current contribution.
local function condensation_description(ctx, owner, level, definition)
    local id = mutation_ids.MUT_CONDENSATION_SHIELD
    local effective = levels.effective(ctx, owner, id)
    local bonus = effect_value(ctx, owner, id,
        capabilities.SHIELD_CLASS_BONUS, effective) / SH_DISPLAY_SCALE

    return definition.have[math.min(level, definition.max_level)] ..
        bonus .. ")"
end

-- Sanguine Armour uses its full level for the live AC figure; the acquired
-- record level alone would understate a partially suppressed mutation.
local function sanguine_description(ctx, owner, level, definition)
    local id = mutation_ids.MUT_SANGUINE_ARMOUR
    local full = levels.full(ctx, owner, id)
    local bonus = effect_value(ctx, owner, id,
        capabilities.AC_FULL_X100, full) / AC_SCALE

    return definition.have[math.min(level, definition.max_level)] ..
        bonus .. ")"
end

local dynamic_descriptions = {
    [mutation_ids.MUT_ICEMAIL] = icemail_description,
    [mutation_ids.MUT_CONDENSATION_SHIELD] = condensation_description,
    [mutation_ids.MUT_SANGUINE_ARMOUR] = sanguine_description,
}

-- Combine source text, activity suppression, temporary brackets, and color
-- in one place so every mutation row tells the same story as its mechanics.
local function description(ctx, owner, state)
    local id = state.mutation_id
    local definition = catalog.get("mutations", id)
    local base = state.innate + state.acquired + state.temporary
    local mode = activity.level(ctx, owner, id, base)
    local level = levels.effective(ctx, owner, id)

    if mode == activity_levels.INACTIVE then
        level = base
    end

    local text = definition.have[math.min(level, definition.max_level)]

    if dynamic_descriptions[id] then
        text = dynamic_descriptions[id](ctx, owner, level, definition)
    end

    if not text or text == "" then
        text = definition.short_description
    end

    if mode == activity_levels.INACTIVE then
        text = "((" .. text .. "))"
    elseif mode == activity_levels.PARTIAL then
        text = "(" .. text .. ")"
    end

    if state.temporary > 0 then
        text = "[" .. text .. "]"
    end

    local color = colors.light_grey

    if bad_mutation(definition) then
        color = colors.red
    end

    if state.innate > 0 then
        color = colors.light_blue
    elseif state.temporary > 0 then
        color = colors.magenta
    end

    if mode == activity_levels.INACTIVE then
        color = colors.dark_grey
    elseif mode == activity_levels.PARTIAL then
        color = colors.brown
    end

    return text, color, mode
end

-- Wrap detail text on word boundaries when possible, but still split a long
-- unbroken token so narrow terminals cannot overflow their cell canvas.
local function wrapped_lines(text, width)
    local lines = {}

    for source_line in (text .. "\n"):gmatch("(.-)\n") do
        while #source_line > width do
            local part = source_line:sub(1, width)
            local split = part:match("^.*() ")

            if not split or split < 2 then
                split = width + 1
            end

            lines[#lines + 1] = source_line:sub(1, split - 1)
            source_line = source_line:sub(split):gsub("^ +", "")
        end

        lines[#lines + 1] = source_line
    end

    return lines
end

-- Resolve the selected record before paginating its description. Rejecting
-- unknown IDs keeps a stale selection key from showing another mutation.
local function detail_rows(ctx, owner, input, ordered)
    local selected

    for _, state in ipairs(ordered) do
        if state.mutation_id == input.selected then
            selected = state
            break
        end
    end

    if not selected then
        error("cannot examine an unknown player mutation")
    end

    local definition = catalog.get("mutations", selected.mutation_id)
    local text = definition.description

    if not text or text == "" then
        text = description(ctx, owner, selected)
    end

    local writes = {}
    local height = input.height or 24
    local width = math.max(1, (input.width or 79) - 2)
    local lines = wrapped_lines(text, width)
    local capacity = math.max(1, height - 3)
    local pages = math.max(1, math.ceil(#lines / capacity))
    local page = math.max(0, math.min(input.page or 0, pages - 1))
    local first = page * capacity + 1
    local last = math.min(#lines, first + capacity - 1)

    write(writes, 0, 0, definition.short_description .. " mutation", colors.white)

    for index = first, last do
        write(writes, 1, index - first + 2, lines[index], colors.light_grey)
    end

    local footer = "Esc - Return to mutations"

    if pages > 1 then
        footer = string.format("PgUp/PgDn - Page %d/%d    %s",
            page + 1, pages, footer)
    end

    write(writes, 0, height - 1, footer, colors.brown)

    return {
        writes = writes,
        pages = pages,
        options = {},
    }
end

-- Build the screen from current ECS records and species-derived fake rows.
-- Example: runtime.Policy("presentation.mutations", { height = 24, page = 0 })
-- returns writes and only the visible page's selectable mutation IDs.
function mutations.rows(ctx, input)
    local owner = input.owner or ctx:player()
    local writes = {}
    local height = input.height or 24
    local ordered = ordered_records(ctx, owner)
    local fake_entries = fakes.rows(ctx, owner)

    if input.selected and input.selected ~= "" then
        return detail_rows(ctx, owner, input, ordered)
    end

    write(writes, 0, 0, title, colors.white)

    if #ordered == 0 and #fake_entries == 0 then
        write(writes, 1, 2, "You are rather mundane.", colors.light_grey)
    end

    local partial = false
    local inactive = false
    local temporary = false

    local entries = {}

    for _, entry in ipairs(fake_entries) do
        entries[#entries + 1] = entry
    end

    for index, state in ipairs(ordered) do
        local text, color, mode = description(ctx, owner, state)

        entries[#entries + 1] = {
            id = state.mutation_id,
            key = letter(index),
            text = text,
            color = color,
        }

        partial = partial or mode == activity_levels.PARTIAL
        inactive = inactive or mode == activity_levels.INACTIVE
        temporary = temporary or state.temporary > 0
    end

    local legend = {}

    if partial then
        legend[#legend + 1] = "() : Partially suppressed."
    end

    if inactive then
        legend[#legend + 1] = "(()) : Completely suppressed."
    end

    if temporary then
        legend[#legend + 1] = "[] : Transient mutations."
    end

    local capacity = math.max(1, math.min(52, height - 3 - #legend))
    local pages = math.max(1, math.ceil(#entries / capacity))
    local page = math.max(0, math.min(input.page or 0, pages - 1))
    local first = page * capacity + 1
    local last = math.min(#entries, first + capacity - 1)
    local options = {}

    for index = first, last do
        local entry = entries[index]
        local text = entry.text

        if entry.key then
            text = entry.key .. " - " .. text
            options[#options + 1] = {
                key = entry.key,
                id = entry.id,
            }
        end

        write(writes, 1, index - first + 2, text, entry.color)
    end

    for index, line in ipairs(legend) do
        write(writes, 0, height - #legend - 2 + index, line, colors.brown)
    end

    local footer = "? - Help    Esc - Return"

    if pages > 1 then
        footer = string.format("PgUp/PgDn - Page %d/%d    %s",
            page + 1, pages, footer)
    end

    write(writes, 0, height - 1, footer, colors.brown)

    return {
        writes = writes,
        pages = pages,
        options = options,
    }
end

-- Keep the registered callback a thin adapter so direct screen tests and the
-- terminal use exactly the same pagination and legend logic.
function mutations.run(ctx, input)
    return mutations.rows(ctx, input)
end

register.policy({
    id = "presentation.mutations",
    run = mutations.run,
})

return mutations
