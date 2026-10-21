-- Theory of operation: the source calls this room diamond, but its actual
-- iterator paints alternating coin and floor cells. Keeping that exact
-- parity matters more than the descriptive name.
local handler = {}

-- Source coordinates start at zero; even parity receives the coin glyph.
local function paint(api)
    local width, height = api:map_size()

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local glyph = (x + y) % 2 == 0 and "$" or "."

            api:set_cell(x, y, glyph)
        end
    end
end

handler.paint = paint

return handler
