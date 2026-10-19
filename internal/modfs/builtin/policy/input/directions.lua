local commands = require("policy.input.commands")

-- Vi keys and named cursor keys resolve to the same eight movement offsets.
local directions = {
    h = {
        dx = -1,
        dy = 0,
    },
    left = {
        dx = -1,
        dy = 0,
    },

    j = {
        dx = 0,
        dy = 1,
    },
    down = {
        dx = 0,
        dy = 1,
    },

    k = {
        dx = 0,
        dy = -1,
    },
    up = {
        dx = 0,
        dy = -1,
    },

    l = {
        dx = 1,
        dy = 0,
    },
    right = {
        dx = 1,
        dy = 0,
    },

    y = {
        dx = -1,
        dy = -1,
    },
    home = {
        dx = -1,
        dy = -1,
    },

    u = {
        dx = 1,
        dy = -1,
    },
    pgup = {
        dx = 1,
        dy = -1,
    },

    b = {
        dx = -1,
        dy = 1,
    },
    ["end"] = {
        dx = -1,
        dy = 1,
    },

    n = {
        dx = 1,
        dy = 1,
    },
    pgdown = {
        dx = 1,
        dy = 1,
    },
}

local input = {}

-- Directional key decoding is shared by movement and targeted terminal prompts.
function input.command(key)
    local direction = directions[key]

    -- Example: `h` and `left` both become the same westward move intent.
    if direction then
        return {
            action = "step",
            kind = commands.move,
            dx = direction.dx,
            dy = direction.dy,
        }
    end

    local kind

    if key == "." or key == "s" then
        kind = commands.wait
    elseif key == "g" or key == "," then
        kind = commands.pickup
    elseif key == "<" then
        kind = commands.upstairs
    elseif key == ">" then
        kind = commands.downstairs
    end

    if kind then
        return {
            action = "step",
            kind = kind,
        }
    end

    return nil
end

return input
