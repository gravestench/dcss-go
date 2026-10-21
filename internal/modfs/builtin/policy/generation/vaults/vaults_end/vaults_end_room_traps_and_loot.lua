-- Theory of operation: this room helper has no fixed MAP dimensions.
-- It inherits the parent room rectangle, starts as floor, and lets the
-- following source SUBST and shared loot hook vary traps and treasure.
local handler = {}

-- Paint only the assigned parent region; the operation engine masks cells
-- that do not belong to this helper's placeholder glyph.
local function paint(api)
    local width, height = api:map_size()

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            api:set_cell(x, y, ".")
        end
    end
end

handler.paint = paint

return handler
