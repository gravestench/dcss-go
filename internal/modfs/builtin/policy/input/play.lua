local commands = require("policy.input.commands")
local directions = require("policy.input.directions")

local screens = {
    a = {
        name = "abilities",
        returnable = true,
    },
    i = {
        name = "inventory",
        returnable = true,
    },
    m = {
        name = "skills",
        returnable = true,
    },
    A = {
        name = "mutations",
        returnable = true,
    },
    ["?"] = {
        name = "help",
        returnable = true,
    },
    q = {
        name = "quaff",
        returnable = true,
    },
    r = {
        name = "read",
        returnable = true,
    },
    V = {
        name = "evoke_wand",
        returnable = true,
    },
    d = { name = "drop" },
    w = { name = "wield" },
    F = { name = "throw" },
    W = { name = "wear" },
    T = { name = "take_off" },
    P = { name = "put_on" },
    R = { name = "remove_jewellery" },
    z = { name = "spell_cast" },
    Z = { name = "spell_force" },
    M = { name = "spell_memorise" },
}

local play = {}

function play.route(input)
    local key = input.key

    if key == ">" and input.on_shop then
        return {
            action = "screen",
            screen = "shop",
            returnable = false,
        }
    end

    local screen = screens[key]

    if screen then
        return {
            action = "screen",
            screen = screen.name,
            returnable = screen.returnable or false,
        }
    end

    if key == "S" then
        return {
            action = "confirm",
            confirmation = "save",
        }
    elseif key == "ctrl+q" then
        return {
            action = "confirm",
            confirmation = "abandon",
        }
    elseif key == "ctrl+s" then
        return { action = "save_exit" }
    elseif key == "f" then
        return {
            action = "aim",
            kind = commands.fire,
        }
    elseif key == "O" then
        return {
            action = "door",
            kind = commands.open_door,
        }
    elseif key == "C" then
        return {
            action = "door",
            kind = commands.close_door,
        }
    elseif key == "L" then
        return {
            action = "notice",
            text = "Running is unavailable in the Go port.",
        }
    end

    local command = directions.command(key)

    if command then
        return command
    end

    return {
        action = "notice",
        text = string.format("Command %q is unavailable in the Go port.", key),
    }
end

return play
