local menu = require("policy.input.menu")

local pregame = {}

-- Keep a rejected choice on the current screen with a reason instead of
-- changing focus or starting a game from an unsupported key.
local function notice(text)
    return {
        action = "notice",
        text = text,
    }
end

-- Return a focus action rather than mutating the menu; the session then
-- supplies the new focus to both input and presentation on the next frame.
local function focus(index)
    return {
        action = "focus",
        index = index,
    }
end

-- Represent stage changes explicitly so going back can restore the intended
-- focus without reinterpreting the old key in the destination screen.
local function screen(name, index)
    return {
        action = "screen",
        screen = name,
        returnable = false,
        focus = index,
    }
end

-- Translate the terminal's named Space key into a printable character;
-- other character keys can be appended directly to the name buffer.
local function name_character(key)
    if key == "space" then
        return " "
    end

    return key
end

-- Pregame routes keep species, background, weapon, and name choices in session order.
-- Startup keeps name editing and the species/job menu as separate input stages.
-- Example: pregame.startup({ key = "enter", focus = 0, mode_count = 2 })
-- requests a new game; the session owns the actual transition.
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

-- Choice letters are translated against the currently displayed option list.
-- Page offsets ensure a letter from a modded page selects that page's ID,
-- while Enter always confirms the globally focused choice.
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

-- Return IDs from the current catalog choice list, never from screen labels;
-- focus movement and modded pages must agree on the same stable selection.
-- Example: pregame.choice({ key = "enter", screen = "species",
--     ids = species_ids, focus = 0, page_start = 0, page_end = 1 }).
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

-- A starting weapon key is interpreted against the offered set, not against every weapon ID.
-- Example: pregame.weapon({ key = "a", options = offered, focus = 0 })
-- returns the chosen weapon ID only if that option is actually offered.
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

-- Keep name editing as a separate final stage, so Enter starts a game only
-- after species, background, and starting weapon have been chosen.
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
