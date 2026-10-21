-- A malformed helper demonstrates that paint coordinates stay local.
local handler = {}

-- Width is already outside zero-based bounds; the API should reject it.
local function paint(api)
    local width = api:map_size()
    api:set_cell(width, 0, ".")
end

handler.paint = paint
return handler
