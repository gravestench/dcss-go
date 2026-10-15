local menu = require("policy.input.menu")

local pregame = {}

local function notice(text)
    return {
        action = "notice",
        text = text,
    }
end

local function focus(index)
    return {
        action = "focus",
        index = index,
    }
end

local function screen(name, index)
    return {
        action = "screen",
        screen = name,
        returnable = false,
        focus = index,
    }
end

local function name_character(key)
    if key == "space" then
        return " "
    end

    return key
end

function pregame.startup(input)
    local key = input.key
    local count = input.mode_count

    if key == "esc" then
        return { action = "quit" }
    elseif key == "up" then
        return focus((input.focus - 1 + count) % count)
    elseif key == "down" then
        return focus((input.focus + 1) % count)
    elseif key == "enter" then
        if input.saved_run and input.focus == count - 1 then
            return { action = "load_saved" }
        end

        if input.focus == 0 then
            return { action = "start_new" }
        end

        return notice("This game mode is unavailable in the Go port.")
    elseif key == "backspace" then
        return {
            action = "name_edit",
            operation = "backspace",
        }
    elseif key == "ctrl+u" then
        return {
            action = "name_edit",
            operation = "clear",
        }
    elseif key == "ctrl+p" then
        return notice("RC file information is unavailable in the Go port.")
    elseif key == "?" then
        return {
            action = "screen",
            screen = "help",
            returnable = true,
        }
    end

    return {
        action = "name_edit",
        operation = "append",
        value = name_character(key),
    }
end

local function choice_index(input)
    if input.key == "enter" then
        return input.focus + 1
    end

    for index = input.page_start + 1, input.page_end do
        if input.key == menu.letter(index - input.page_start) then
            return index
        end
    end

    return nil
end

function pregame.choice(input)
    local key = input.key
    local species = input.screen == "species"
    local alternate = species and "background" or "species"
    local count = #input.ids

    if count == 0 then
        return notice("No character choices are available in this ruleset.")
    end

    if key == "esc" then
        return screen("startup", 0)
    elseif key == "backspace" then
        local next = screen(alternate, 0)
        next.clear_choice = species and "species" or "job"

        return next
    elseif key == "space" then
        return screen(alternate, 0)
    elseif key == "up" then
        return focus((input.focus - 1 + count) % count)
    elseif key == "down" then
        return focus((input.focus + 1) % count)
    elseif key == "left" then
        return focus((input.focus - 9 + count) % count)
    elseif key == "right" then
        return focus((input.focus + 9) % count)
    elseif key == "?" then
        return {
            action = "screen",
            screen = "help",
            returnable = true,
        }
    end

    if key == "+" or key == "#" or key == "%" or
        key == "*" or key == "!" then
        return notice("This character option is unavailable in the Go port.")
    end

    local index = choice_index(input)

    if index and input.ids[index] then
        return {
            action = "select_choice",
            id = input.ids[index],
            index = index - 1,
        }
    end

    return { action = "none" }
end

function pregame.weapon(input)
    local key = input.key
    local count = #input.options

    if key == "esc" or key == "backspace" then
        return { action = "return_weapon" }
    end

    if count == 0 then
        return notice("No weapon choices are available in this ruleset.")
    end

    if key == "up" then
        return focus((input.focus - 1 + count) % count)
    elseif key == "down" then
        return focus((input.focus + 1) % count)
    elseif key == "?" then
        return {
            action = "screen",
            screen = "help",
            returnable = true,
        }
    elseif key == "+" or key == "*" or key == "%" then
        return notice("This weapon option is unavailable in the Go port.")
    end

    local index = nil

    if key == "enter" then
        index = input.focus + 1
    else
        for option = 1, count do
            if key == menu.letter(option) then
                index = option
                break
            end
        end
    end

    if index and input.options[index] then
        return {
            action = "select_weapon",
            id = input.options[index].id,
            index = index - 1,
        }
    end

    return { action = "none" }
end

function pregame.name(input)
    local key = input.key

    if key == "esc" then
        return screen("weapon")
    elseif key == "backspace" then
        return {
            action = "name_edit",
            operation = "backspace",
        }
    elseif key == "enter" then
        return { action = "start_game" }
    end

    return {
        action = "name_edit",
        operation = "append",
        value = name_character(key),
    }
end

return pregame
