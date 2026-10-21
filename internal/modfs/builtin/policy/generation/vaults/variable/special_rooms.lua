-- Theory of operation: a source special-room parent builds only geometry.
-- Its O cells are then owned by one tagged child from builder/special_room_*.des.
-- Keeping the choice as SUBVAULT lets that child keep its own source tags,
-- weight, and name in the effective catalog and in saved vault history.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local rooms = {}

-- DCSS random2avg(n, 2) takes two bounded draws and averages them down.
local function average_two(api, bound)
    return math.floor((api:roll(bound) + api:roll(bound)) / 2)
end

-- Paint the source wall ring around a fill that a child can replace. The
-- entrance is assigned after the tagged child has chosen its interior.
local function shell(api, width, height)
    api:resize(width, height, "O")

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if x == 0 or x == width - 1 or
                y == 0 or y == height - 1 then
                api:set_cell(x, y, "x")
            end
        end
    end
end

-- The normal branch room has an exit in one randomly chosen wall. The
-- branch-specific wall material is substituted after the child is placed.
local function normal(api)
    local width = 6 + average_two(api, 3)
    local height = 5 + average_two(api, 5)

    shell(api, width, height)
    api:emit(directives.SUBVAULT, "O : special_room")

    local entrance_x
    local entrance_y

    if api:coinflip() then
        entrance_x = api:coinflip() and 0 or width - 1
        entrance_y = api:random_range(1, height - 2)
    else
        entrance_x = api:random_range(1, width - 2)
        entrance_y = api:coinflip() and 0 or height - 1
    end

    api:set_cell(entrance_x, entrance_y, "@")

    if api:branch_id() == branches.BRANCH_CRYPT then
        api:emit(directives.SUBST, "x = c")
    elseif api:branch_id() == branches.BRANCH_SLIME then
        api:emit(directives.SUBST, "x = X")
    end
end

-- Vaults embeds its room into a primary vault. Its rectangle contains no
-- wall or doorway of its own; the surrounding Vaults layout supplies both.
local function vaults(api)
    local width = 6 + average_two(api, 3)
    local height = 5 + api:roll(5)

    api:resize(width, height, "O")
    api:emit(directives.SUBVAULT, "O : special_room")
end

rooms.normal = normal
rooms.vaults = vaults

return rooms
