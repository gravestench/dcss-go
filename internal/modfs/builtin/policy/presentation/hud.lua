local time = require("constants.time")
local colors = require("policy.presentation.colors")
local abyss = require("policy.world.abyss")

local hud = {}

local function letter(index)
    if index < 26 then
        return string.char(string.byte("a") + index)
    end

    return string.char(string.byte("A") + index - 26)
end

local function vital_color(current, maximum, yellow_at, red_at)
    if maximum <= 0 then
        return colors.light_grey
    end

    local percent = math.floor(current * 100 / maximum)

    if percent <= red_at then
        return colors.red
    elseif percent <= yellow_at then
        return colors.yellow
    end

    return colors.light_grey
end

local function weapon_label(inventory)
    for index, item in ipairs(inventory) do
        if item.slot == "weapon" then
            return string.format("%s) %+d %s", letter(index - 1), item.plus, item.name)
        end
    end

    return "-) Unarmed"
end

function hud.rows(view)
    local writes = {}
    local meters = {}

    local function write(x, y, text, fg)
        writes[#writes + 1] = { x = x, y = y, text = text, fg = fg }
    end

    write(0, 0, view.player_name .. " the Shield-Bearer", colors.yellow)
    write(0, 1, view.species_name, colors.yellow)

    local vitals = {
        { y = 2, label = "Health: ", current = view.player_hp,
            maximum = view.player_max_hp, yellow_at = 70, red_at = 40,
            filled = colors.light_green },
        { y = 3, label = "Magic:  ", current = view.player_mp,
            maximum = view.player_max_mp, yellow_at = 50, red_at = 25,
            filled = colors.light_blue },
    }

    for _, vital in ipairs(vitals) do
        local current = tostring(vital.current)
        write(0, vital.y, vital.label, colors.brown)
        write(#vital.label, vital.y, current,
            vital_color(vital.current, vital.maximum, vital.yellow_at, vital.red_at))
        write(#vital.label + #current, vital.y, "/" .. vital.maximum, colors.light_grey)
        meters[#meters + 1] = {
            x = 18,
            y = vital.y,
            width = 24,
            current = vital.current,
            maximum = vital.maximum,
            filled = vital.filled,
            empty = colors.dark_grey,
        }
    end

    local ac, ev, sh = "AC: --", "EV: --", "SH: --"

    if view.defense_known then
        ac = "AC: " .. view.player_ac
        ev = "EV: " .. view.player_ev
        sh = "SH: " .. view.player_sh
    end

    write(0, 4, ac, colors.brown)
    write(0, 5, ev, colors.brown)
    write(0, 6, sh, colors.brown)

    for _, stat in ipairs({
        { y = 4, label = "Str: ", value = view.attributes.strength },
        { y = 5, label = "Int: ", value = view.attributes.intelligence },
        { y = 6, label = "Dex: ", value = view.attributes.dexterity },
    }) do
        write(18, stat.y, stat.label, colors.brown)
        write(18 + #stat.label, stat.y, tostring(stat.value),
            stat.value < 3 and colors.red or colors.light_grey)
    end

    write(0, 7, string.format("XL: %2d Next: %2d%%",
        view.experience_level, view.next_level_percent), colors.brown)
    local place = view.level_id == abyss.level_id and "Abyss" or
        "D:" .. view.level_id
    write(18, 7, "Place: " .. place, colors.brown)
    write(0, 8, "Noise: --", colors.brown)
    write(18, 8, string.format("Time: %.1f",
        view.current_aut / time.AUT_PER_TURN), colors.brown)
    write(0, 9, weapon_label(view.inventory), colors.light_grey)
    write(0, 10, "Quiver: --", colors.brown)

    if view.might_aut > 0 then
        write(0, 11, "Might", colors.light_blue)
    end

    if view.poison_amount_scaled > 0 then
        write(10, 11, "Poisoned", colors.light_green)
    end

    if view.haste_aut > 0 then
        write(20, 11, "Fast", colors.light_blue)
    end

    if view.constricted then
        write(26, 11, "Constr", colors.light_red)
    end

    return { writes = writes, meters = meters }
end

function hud.run(_, input)
    return hud.rows(input.view)
end

register.policy({
    id = "presentation.hud",
    run = hud.run,
})

return hud
