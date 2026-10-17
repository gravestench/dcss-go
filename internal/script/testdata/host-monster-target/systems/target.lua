register.system({
    id = "test.monster_target",
    query = { "core.intent" },
    update = function(ctx, entity)
        local intent = ctx:get(entity, "core.intent")

        if intent.target_kind ~= "cell" or
            ctx:id(intent.target_entity) ~= 9 or
            intent.target_level_id ~= 2 or
            intent.target_x ~= 7 or
            intent.target_y ~= 4 then
            error("host target plan did not reach Lua: " ..
                tostring(intent.target_kind) .. "/" ..
                tostring(ctx:id(intent.target_entity)) .. "/" ..
                tostring(intent.target_level_id) .. "/" ..
                tostring(intent.target_x) .. "/" ..
                tostring(intent.target_y))
        end

        intent.target_x = 8
        ctx:set(entity, "core.intent", intent)
    end,
})
