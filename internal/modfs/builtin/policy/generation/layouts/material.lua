-- Source theme.level_material occasionally replaces ordinary rock with
-- stone or metal in deeper branches. This is terrain policy shared by room
-- and open layouts, separate from their geometry and visual tile choices.
local grid = require("policy.generation.grid")

local material = {}

-- Preserve the one-in-twenty source draw and the 2:1 stone-to-metal choice.
-- Lair, Zot, and Dis own different branch material rules.
function material.level(builder, api)
    if api.depth < 4 or api.branch == "Lair" or
        api.branch == "Zot" or api.branch == "Dis" or
        not builder:one_in(20) then
        return
    end

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            if builder:cell(x, y) == "#" then
                builder:set(x, y, builder:roll(3) == 2 and "v" or "c")
            end
        end
    end
end

return material
