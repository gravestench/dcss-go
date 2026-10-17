local time = require("constants.time")
local colors = require("policy.presentation.colors")
local abyss = require("policy.world.abyss")
local agility = require("policy.character.agility")
local safety = require("policy.character.damage_safety")
local restrictions = require("constants.safety_restrictions")
local powered = require("policy.character.powered_by_death")
local flight = require("policy.combat.flight")
local curl = require("policy.character.curl")
local horror = require("policy.character.horror")
local rage = require("policy.character.rage")
local component = require("constants.component")

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
            return string.format("%s) %s", letter(index - 1), item.name)
        end
    end

    return "-) Unarmed"
end

function hud.rows(view, extras)
    local writes = {}
    local meters = {}

    local function write(x, y, text, fg)
        writes[#writes + 1] = {
            x = x,
            y = y,
            text = text,
            fg = fg,
        }
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
    write(18, 10, "Gold: " .. (view.gold or 0), colors.brown)

    local statuses = {}

    if extras.berserk then
        statuses[#statuses + 1] = {
            label = "Berserk",
            color = colors.blue,
        }
    elseif extras.berserk_cooldown then
        statuses[#statuses + 1] = {
            label = "-Berserk",
            color = colors.yellow,
        }
    end

    if view.might_aut > 0 then
        statuses[#statuses + 1] = {
            label = "Might",
            color = colors.light_blue,
        }
    end

    if extras.agile then
        statuses[#statuses + 1] = {
            label = "Agi",
            color = colors.light_blue,
        }
    end

    if extras.death_power > 0 then
        statuses[#statuses + 1] = {
            label = "Regen (" .. extras.death_power .. ")",
            color = colors.light_magenta,
        }
    end

    if extras.flying then
        statuses[#statuses + 1] = {
            label = "Fly",
            color = extras.permanent_flight and colors.white or colors.blue,
        }
    end

    if extras.curled then
        statuses[#statuses + 1] = {
            label = "Curl",
            color = colors.blue,
        }
    end

    if extras.horror > 0 then
        local color = colors.yellow

        if extras.horror >= 5 then
            color = colors.red
        elseif extras.horror >= 3 then
            color = colors.light_red
        end

        statuses[#statuses + 1] = {
            label = "Horr(-" .. extras.horror .. ")",
            color = color,
        }
    end

    if view.poison_amount_scaled > 0 then
        statuses[#statuses + 1] = {
            label = "Poisoned",
            color = colors.light_green,
        }
    end

    if view.haste_aut > 0 then
        statuses[#statuses + 1] = {
            label = "Fast",
            color = colors.light_blue,
        }
    end

    if extras.petrifying then
        statuses[#statuses + 1] = {
            label = "Petr",
            color = colors.light_red,
        }
    elseif extras.petrified then
        statuses[#statuses + 1] = {
            label = "Stone",
            color = colors.red,
        }
    end

    if view.constricted then
        statuses[#statuses + 1] = {
            label = "Constr",
            color = colors.light_red,
        }
    end

    if extras.no_potions then
        statuses[#statuses + 1] = {
            label = "-Potion",
            color = colors.red,
        }
    end

    if extras.no_scrolls then
        statuses[#statuses + 1] = {
            label = "-Scroll",
            color = colors.red,
        }
    end

    if extras.vampire_alive then
        statuses[#statuses + 1] = {
            label = "Alive",
            color = colors.green,
        }
    elseif extras.vampire_bloodless then
        statuses[#statuses + 1] = {
            label = "Bloodless",
            color = colors.light_red,
        }
    end

    local x = 0
    local y = 11
    local width = 42

    for _, status in ipairs(statuses) do
        if x + #status.label > width then
            x = 0
            y = y + 1
        end

        write(x, y, status.label, status.color)
        x = x + #status.label + 1
    end

    return { writes = writes, meters = meters }
end

function hud.run(ctx, input)
    local player = ctx:player()
    local status = player and ctx:get(player,
        component.PLAYER_PETRIFICATION)
    local rage_state = player and ctx:get(player, component.RAGE)
    local vampire_state = player and ctx:get(player, component.VAMPIRE)
    local extras = {
        berserk = player and rage.active(ctx, player) or false,
        berserk_cooldown = rage_state and rage_state.cooldown_aut > 0 or false,
        agile = player and agility.active(ctx, player) or false,
        no_potions = player and
            safety.active(ctx, player, restrictions.POTIONS) or false,
        no_scrolls = player and
            safety.active(ctx, player, restrictions.SCROLLS) or false,
        death_power = player and powered.strength(ctx, player) or 0,
        flying = player and flight.active(ctx, player) or false,
        permanent_flight = player and
            flight.permanent(ctx, player) or false,
        curled = player and curl.active(ctx, player) or false,
        horror = player and horror.penalty(ctx, player) or 0,
        petrifying = status and status.petrifying_aut > 0 or false,
        petrified = status and status.petrified_aut > 0 or false,
        vampire_alive = vampire_state and vampire_state.alive or false,
        vampire_bloodless = vampire_state and
            not vampire_state.alive or false,
    }

    return hud.rows(input.view, extras)
end

register.policy({
    id = "presentation.hud",
    run = hud.run,
})

return hud
