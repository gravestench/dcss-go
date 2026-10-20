-- This small mod layout proves that a new DES file can name a new Lua
-- builder. Its cells are deliberately simple so catalog behavior is clear.
local grid = require("policy.generation.grid")

local layout = {}

-- Carve one connected area; the production stair postpass adds exits.
function layout.layout_modded(api)
    local builder = grid.new(api.ctx)

    for y = 10, 50 do
        for x = 10, 60 do
            builder:set(x, y, ".")
        end
    end

    return {
        builder = builder,
        rows = builder:rows(),
    }
end

return layout
