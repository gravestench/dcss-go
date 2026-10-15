local abyss = {}

function abyss.validate(level)
    local exit = level.stairs[1]

    if #level.rows ~= 70 or #level.rows[1] ~= 80 or
        #level.stairs ~= 1 or not exit or exit.x ~= 40 or exit.y ~= 35 or
        exit.to_level_id ~= 0 or exit.unavailable == "" or
        level.initial_monsters ~= 0 or
        level.initial_actors ~= 0 or
        level.rows[36]:sub(41, 41) ~= "<" then
        error("saved Abyss level has invalid geometry or portal")
    end
end

return abyss
