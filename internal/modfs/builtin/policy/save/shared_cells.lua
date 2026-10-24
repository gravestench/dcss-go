-- Source Fedhas permits a player to stand on one stationary plant. Save
-- reconstruction temporarily admits overlaps, then this policy verifies
-- every shared cell before gameplay resumes. It permits a former Fedhas
-- worshiper to leave the shared cell after renouncing but not to reenter.
local component = require("constants.component")
local passage = require("policy.religion.fedhas.pass_through")

local shared = {}

-- Inspect each positioned actor's cell once. A second actor beside the
-- player is valid only if its catalog traits permit plant sharing. Current
-- worship and allegiance may have changed since the player entered.
function shared.validate(ctx)
    local checked = {}
    local player = ctx:player()

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
    })) do
        local position = ctx:get(entity, component.POSITION)
        local key = position.level_id .. ":" .. position.x ..
            ":" .. position.y

        if not checked[key] then
            checked[key] = true

            local occupants = ctx:actors_at(position.level_id,
                position.x, position.y)

            if #occupants > 1 then
                local plant = #occupants == 2 and
                    ctx:get(occupants[2], component.ACTOR)

                if occupants[1] ~= player or not plant or
                    not passage.kind(plant.kind_id) then
                    error("saved actors share an invalid cell " .. key)
                end
            end
        end
    end

    return {}
end

register.policy({
    id = "save.validate_shared_cells",
    run = shared.validate,
})

return shared
