local abyss = {}

-- Saved Abyss level records are validated before branch restoration uses them.
-- Example: abyss.validate(level) rejects an exit outside the fixed centre portal.
function abyss.validate(level)
    local exit = level.stairs[1]

    if #level.cells ~= 70 or #level.cells[1] ~= 80 or
        #level.stairs ~= 1 or not exit or exit.x ~= 40 or exit.y ~= 35 or
        exit.to_level_id ~= 0 or exit.unavailable == "" or
        level.initial_monsters ~= 0 or
        level.initial_actors ~= 0 or
        level.cells[36][41] ~= "DNGN_STONE_STAIRS_UP_I" then
        error("saved Abyss level has invalid geometry or portal")
    end
end

return abyss
