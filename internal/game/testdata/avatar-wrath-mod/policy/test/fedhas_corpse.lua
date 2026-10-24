-- Place an ordinary source-valid corpse next to the player, then invoke
-- the production Fedhas corpse-spore owner across the game transaction.
local component = require("constants.component")
local corpses = require("policy.religion.wrath.fedhas.corpses")
local items = require("ids.items")
local monsters = require("ids.monsters")
local range = require("constants.spell_range")

local test = {}

-- Find a real open floor cell so the exact spore placement, corpse
-- conversion, and subsequent save all use the game's grid service.
function test.run(ctx)
    local player = ctx:player()
    local origin = ctx:get(player, component.POSITION)

    for dy = -2, 2 do
        for dx = -2, 2 do
            local x = origin.x + dx
            local y = origin.y + dy

            if (dx ~= 0 or dy ~= 0) and
                ctx:walkable(origin.level_id, x, y) and
                not ctx:actor_at(origin.level_id, x, y) and
                ctx:visible_no_trans(origin.level_id,
                    origin.x, origin.y, range.LOS_RADIUS, x, y) then
                local body = ctx:create()

                ctx:add(body, component.ITEM, {
                    kind_id = items.CORPSE_BODY,
                    quantity = 1,
                })
                ctx:add(body, component.CORPSE, {
                    monster_id = monsters.MONS_RAT,
                    freshness = 110,
                    appearance = 1,
                })
                ctx:add(body, component.POSITION, {
                    level_id = origin.level_id,
                    x = x,
                    y = y,
                })

                if not corpses.apply(ctx, player) then
                    error("Fedhas found no corpse on an open cell")
                end

                return {}
            end
        end
    end

    error("scenario has no open corpse cell")
end

register.policy({
    id = "test.fedhas_corpse_spore",
    run = test.run,
})

return test
