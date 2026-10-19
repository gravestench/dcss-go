-- Doom Howl calls permanent hostile beasts next to the player. They are
-- ordinary monsters, not temporary summons, and keep a saved pursuit link.
-- Source: spl-summoning.cc:doom_howl.
local clouds = require("policy.clouds.placement")
local component = require("constants.component")
local factory = require("policy.population.factory")
local habitat = require("policy.combat.monster_habitat")
local cloud_ids = require("ids.clouds")
local attitudes = require("constants.attitude")
local ids = require("policy.combat.monster_doom_howl.ids")

local arrivals = {}

-- Source adjacency order is stable before the one random placement draw.
-- A blocked ring consumes the beast draw but creates nothing.
local function available(ctx, position, kind_id)
    local cells = {}

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy

                if habitat.kind_at(ctx, kind_id,
                    position.level_id, x, y) and
                    not ctx:actor_at(position.level_id, x, y) then
                    cells[#cells + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    return cells
end

-- Each call chooses one of five source monsters, then an open adjacent
-- cell. The resulting actor follows the player through saved Haunting.
function arrivals.call(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return nil
    end

    local kind_id = ids.BEASTS[ctx:random("monster_spell", #ids.BEASTS) + 1]
    local cells = available(ctx, position, kind_id)

    if #cells == 0 then
        return nil
    end

    local cell = cells[ctx:random("monster_spell", #cells) + 1]
    local called = factory.spawn(ctx, kind_id,
        position.level_id, cell.x, cell.y, {
            attitude = attitudes.HOSTILE,
        })

    ctx:add(called, component.SUMMON_HAUNTING, {
        target = player,
    })
    ctx:add(called, ids.ARRIVAL, {
        created_aut = ctx:aut(),
    })

    local ai = ctx:get(called, component.AI)

    if ai then
        ai.behavior = "seek"
        ai.target_x = position.x
        ai.target_y = position.y
        ai.memory_until_aut = ctx:aut() + 50
        ctx:set(called, component.AI, ai)
    end

    -- Black smoke is visual atmosphere, with the short source lifetime.
    local duration = (1 + ctx:random("monster_spell", 2)) * 10

    clouds.place(ctx, cloud_ids.CLOUD_BLACK_SMOKE, called,
        position.level_id, cell.x, cell.y, duration)

    return called
end

return arrivals
