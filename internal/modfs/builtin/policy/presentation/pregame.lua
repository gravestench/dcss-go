local catalog = require("policy.catalog")
local colors = require("policy.presentation.colors")
local source = require("data.presentation")

local pregame = {}

local function write(writes, x, y, text, fg, bg)
    writes[#writes + 1] = {
        x = x,
        y = y,
        text = text,
        fg = fg,
        bg = bg or colors.black,
    }
end

local function letter(index)
    if index < 26 then
        return string.char(string.byte("a") + index)
    end

    return string.char(string.byte("A") + index - 26)
end

local function flatten(groups)
    local ids = {}

    for _, group in ipairs(groups) do
        for _, id in ipairs(group.ids) do
            ids[#ids + 1] = id
        end
    end

    return ids
end

function pregame.welcome(input)
    local who = input.name or ""
    local named = who ~= ""

    if not named then
        if (not input.species_id or input.species_id == "") and
            (not input.job_id or input.job_id == "") then
            return "Welcome."
        end

        who = "unnamed"
    end

    if input.species_id and input.species_id ~= "" then
        if named then
            who = who .. " the"
        end

        who = who .. " " .. catalog.get("species", input.species_id).name
    end

    if input.job_id == "JOB_FIGHTER" then
        who = who .. " Fighter"
    end

    return "Welcome, " .. who .. "."
end

local function group_position(screen, column)
    if screen == "species" then
        return 1 + (column - 1) * 26, 3
    end

    local positions = {
        { x = 1, y = 3 },
        { x = 1, y = 9 },
        { x = 27, y = 3 },
        { x = 27, y = 8 },
        { x = 53, y = 3 },
    }

    return positions[column].x, positions[column].y
end

local function choice_page(groups, focus, screen)
    local base_groups = screen == "species" and 3 or 5
    local page_size = screen == "species" and 27 or 25
    local capacities = screen == "species" and { 9, 9, 9 } or { 5, 4, 4, 5, 7 }

    if #groups <= base_groups then
        return 0, groups
    end

    local base = {}

    for index = 1, base_groups do
        base[index] = groups[index]
    end

    local base_count = #flatten(base)

    if focus < base_count then
        return 0, base
    end

    local added_groups = {}

    for index = base_groups + 1, #groups do
        added_groups[#added_groups + 1] = groups[index]
    end

    local added = flatten(added_groups)
    local page = math.floor((focus - base_count) / page_size)
    local first = page * page_size + 1
    local last = math.min(first + page_size - 1, #added)
    local visible = {}
    local cursor = first

    for _, capacity in ipairs(capacities) do
        if cursor > last then
            break
        end

        local group = { label = cursor == first and "Modded choices" or "", ids = {} }
        local final = math.min(cursor + capacity - 1, last)

        for index = cursor, final do
            group.ids[#group.ids + 1] = added[index]
        end

        visible[#visible + 1] = group
        cursor = final + 1
    end

    return base_count + first - 1, visible
end

local function choice_color(choice, focused, has_other)
    local available = choice and choice.available
    local recommended = choice and choice.restriction == "recommended"
    local fg = colors.light_grey
    local bg = colors.black

    if not available then
        fg = colors.dark_grey
    elseif has_other and recommended then
        fg = colors.white
    end

    if focused then
        fg = colors.white

        if not available then
            bg = colors.dark_grey
        elseif has_other and recommended then
            bg = colors.green
        elseif has_other then
            bg = colors.light_grey
        else
            bg = colors.blue
        end
    end

    return fg, bg
end

local function choice_rows(input, writes, wraps)
    local screen = input.screen
    local species_screen = screen == "species"
    local groups = species_screen and source.species_groups or source.job_groups
    local descriptions = species_screen and source.species_descriptions or source.job_descriptions
    local choice_title = species_screen and "species" or "background"
    local other_title = species_screen and "background" or "species"
    local other_id = species_screen and input.job_id or input.species_id
    local other_selected = other_id ~= nil and other_id ~= ""
    local page_start, visible = choice_page(groups, input.focus, screen)
    local index = page_start

    write(writes, 0, 0, pregame.welcome(input), colors.brown)
    write(writes, 1, 1, "Please select your " .. choice_title .. ".", colors.light_grey)

    for column, group in ipairs(visible) do
        local x, y = group_position(screen, column)
        write(writes, x, y, group.label, colors.light_blue)

        for offset, id in ipairs(group.ids) do
            local definition = catalog.get(species_screen and "species" or "jobs", id)
            local fg, bg = choice_color((input.choices or {})[id], index == input.focus,
                other_selected)
            local label = letter(index - page_start) .. " - " .. definition.name
            write(writes, x, y + offset, label, fg, bg)
            index = index + 1
        end
    end

    local all = flatten(groups)
    local selected = all[input.focus + 1]

    if selected then
        wraps[#wraps + 1] = {
            x = 1,
            y = 19,
            width = input.width - 2,
            height = 4,
            text = descriptions[selected],
            fg = colors.brown,
        }
    end

    local left_hints = {
        "+ - Recommended " .. choice_title,
        "# - Recommended character",
        "% - List aptitudes",
        "? - Help",
    }

    for row, label in ipairs(left_hints) do
        write(writes, 1, 13 + row, label, colors.light_grey)
    end

    local change = other_selected and "Space - Change " or "Space - Pick "
    local right_hints = {
        "    * - Random " .. choice_title,
        "    ! - Random character",
        change .. other_title .. (other_selected and "" or " first"),
    }

    for row, label in ipairs(right_hints) do
        write(writes, 40, 13 + row, label, colors.light_grey)
    end
end

local function weapon_rows(input, writes)
    local species = catalog.get("species", input.species_id)
    write(writes, 0, 0, pregame.welcome(input), colors.brown)
    write(writes, 1, 1, "Please select your starting weapon.", colors.light_grey)

    for index, option in ipairs(input.options) do
        local aptitude = species.aptitudes.SK_UNARMED_COMBAT.value

        if option.id ~= "WPN_UNARMED" then
            local item = catalog.get("items", option.id)
            aptitude = species.aptitudes[item.weapon_skill].value
        end

        local recommended = option.restriction == "recommended"
        local fg = recommended and colors.white or colors.dark_grey
        local bg = colors.black

        if index - 1 == input.focus then
            fg = colors.white
            bg = recommended and colors.green or colors.light_grey
        end

        local label = string.format("%s - %-18s (%+d apt)",
            letter(index - 1), option.name, aptitude)
        write(writes, 2, 2 + index, label, fg, bg)
    end

    write(writes, 1, 11, "+ - Recommended random choice     * - Random weapon", colors.light_grey)
    write(writes, 1, 12, "% - List aptitudes               ? - Help", colors.light_grey)
    write(writes, 1, 13, "Bksp - Return to character menu", colors.light_grey)
end

local function startup_rows(input, writes)
    write(writes, 0, 0,
        "Hello, welcome to Dungeon Crawl Stone Soup " .. source.source_version .. "!",
        colors.yellow)
    write(writes, 0, 1,
        "(c) Copyright 1997-2002 Linley Henzell, 2002-2022 Crawl DevTeam",
        colors.brown)
    write(writes, 1, 3, "Enter your name: " .. (input.name or ""), colors.light_grey)
    write(writes, 1, 5, "Choices:", colors.light_grey)

    for index, mode in ipairs(source.startup_modes) do
        write(writes, 2, 5 + index, mode.label,
            index - 1 == input.focus and colors.white or colors.light_grey)
    end

    if input.saved_run then
        write(writes, 1, 15, "Saved games:", colors.light_grey)
        write(writes, 2, 16, "Continue saved game", colors.white)
    end

    write(writes, 1, 18, "[ctrl-p] view rc file information and log", colors.light_grey)

    if input.focus < #source.startup_modes then
        write(writes, 1, 20, source.startup_modes[input.focus + 1].description, colors.brown)
    end

    local changes = input.changes or {}
    local status = input.vanilla and "Rules: bundled " or "Rules: modified "

    if not input.vanilla and #changes > 0 then
        local changed = "Changed Lua: " .. changes[1]

        if #changes > 1 then
            changed = changed .. " (+" .. (#changes - 1) .. " more)"
        end

        write(writes, 1, 21, changed, colors.brown)
    end

    write(writes, 1, 22, status .. input.rules_hash:sub(1, 12), colors.light_grey)
end

function pregame.rows(input)
    local writes = {}
    local wraps = {}

    if input.screen == "startup" then
        startup_rows(input, writes)
    elseif input.screen == "species" or input.screen == "background" then
        choice_rows(input, writes, wraps)
    elseif input.screen == "weapon" then
        weapon_rows(input, writes)
    elseif input.screen == "name" then
        write(writes, 0, 0, pregame.welcome(input), colors.brown)
        write(writes, 1, 2, "Enter your name: " .. (input.name or ""), colors.light_grey)
    else
        error("unknown pregame screen " .. tostring(input.screen))
    end

    if input.notice and input.notice ~= "" then
        write(writes, 1, 23, input.notice, colors.light_red)
    end

    return { writes = writes, wraps = wraps }
end

register.policy({
    id = "presentation.pregame",
    run = function(_, input)
        return pregame.rows(input)
    end,
})

register.policy({
    id = "presentation.welcome",
    run = function(_, input)
        return { text = pregame.welcome(input) }
    end,
})

register.policy({
    id = "presentation.choice_color",
    run = function(_, input)
        local fg, bg = choice_color(input.choice, input.focused, input.has_other)

        return { fg = fg, bg = bg }
    end,
})

return pregame
