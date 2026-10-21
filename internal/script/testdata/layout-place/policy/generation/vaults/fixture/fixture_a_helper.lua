-- Paint the exact assigned helper rectangle before placing an inner child.
local directives = require("constants.vault_directives")
local handler = {}

-- An empty MAP inherits the parent region's size, so no source geometry is duplicated.
local function paint(api)
    local width, height = api:map_size()

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            api:set_cell(x, y, ".")
        end
    end

    api:set_cell(0, 0, "C")
    api:emit(directives.SUBVAULT, "C : fixture_inner")
end

handler.paint = paint
return handler
