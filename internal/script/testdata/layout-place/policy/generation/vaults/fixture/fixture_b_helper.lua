-- The second helper must observe the first helper's nested tag.
local handler = {}

-- If the shared state is absent, fail rather than silently masking a seed drift.
local function paint(api)
    assert(api:has_placed_tag("fixture_inner"), "nested helper tag was not shared")
    assert(api:has_tag("fixture_helper"), "current helper tags were not exposed")

    local width, height = api:map_size()

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            api:set_cell(x, y, ".")
        end
    end
end

handler.paint = paint
return handler
