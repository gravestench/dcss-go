-- Theory of operation: this source room helper inherits the chosen room's
-- rectangle. Its floor border protects access while the inner region gets
-- treasure glyphs before the shared loot substitutions run.
local handler = {}

-- The source iterator paints the outermost row and column as passable floor.
local function paint(api)
    local width, height = api:map_size()

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local border = x == 0 or y == 0 or
                x == width - 1 or y == height - 1
            local glyph = border and "." or "*"

            api:set_cell(x, y, glyph)
        end
    end
end

handler.paint = paint

return handler
