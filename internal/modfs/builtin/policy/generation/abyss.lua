local abyss = {}
local world_abyss = require("policy.world.abyss")
local branches = require("ids.branches")

local width = 80
local height = 70
local portal_x = 40
local portal_y = 35

function abyss.generate(ctx)
    local rows = {}
    local seed = ctx:random("abyss-layout", 1000000000)
    local open_row = "#" .. string.rep(".", width - 2) .. "#"

    for y = 0, height - 1 do
        if y == 0 or y == height - 1 then
            rows[#rows + 1] = string.rep("#", width)
        else
            local row = open_row

            for rock = 1, 7 do
                local x = 1 + (seed + y * 19349663 + rock * 73856093 +
                    y * rock * 83492791) % (width - 2)
                local near_portal = y >= portal_y - 2 and y <= portal_y + 2 and
                    x >= portal_x - 2 and x <= portal_x + 2

                if not near_portal then
                    row = row:sub(1, x) .. "#" .. row:sub(x + 2)
                end
            end

            if y == portal_y then
                row = row:sub(1, portal_x) .. "<" .. row:sub(portal_x + 2)
            end

            rows[#rows + 1] = row
        end
    end

    return {
        id = world_abyss.level_id,
        branch_id = branches.BRANCH_ABYSS,
        rows = rows,
        stairs = {
            {
                x = portal_x,
                y = portal_y,
                to_level_id = 0,
                to_x = 0,
                to_y = 0,
                unavailable = "The exit follows your banishment origin.",
            },
        },
        entry_x = portal_x,
        entry_y = portal_y,
        initial_monsters = 0,
    }
end

return abyss
