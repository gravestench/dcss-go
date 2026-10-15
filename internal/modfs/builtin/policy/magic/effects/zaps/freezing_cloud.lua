local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local cloud = require("policy.magic.effects.zaps.cloud")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")

local freezing_cloud = {}

local directions = {
    { -1, -1 }, { 0, -1 }, { 1, -1 },
    { -1, 0 },               { 1, 0 },
    { -1, 1 },  { 0, 1 },  { 1, 1 },
}

local function key(x, y)
    return x .. ":" .. y
end

function freezing_cloud.prepare(ctx, player, spell, dx, dy)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + dx
    local y = origin.y + dy
    local reach = range.for_spell(ctx, player, spell)

    if math.max(math.abs(dx), math.abs(dy)) > reach or
        not ctx:walkable(origin.level_id, x, y) or
        not ctx:projectile_clear(origin.level_id,
            origin.x, origin.y, x, y) or
        cloud.at(ctx, origin.level_id, x, y) then
        return "You cannot place a freezing cloud there."
    end
end

local function duration(ctx, power)
    local spread = math.floor(power / 4)
    local amount = 3

    if spread > 0 then
        for _ = 1, 3 do
            amount = amount + ctx:random("spell", spread)
        end
    end

    return amount * 10
end

function freezing_cloud.resolve(ctx, player, intent, _, power)
    local origin = ctx:get(player, component.POSITION)
    local level = origin.level_id
    local x = origin.x + intent.dx
    local y = origin.y + intent.dy
    local count = 8 + ctx:random("spell", 3)
    local seen = { [key(x, y)] = true }
    local queue = { { x = x, y = y } }
    local placed = 0

    -- targeter_cloud builds rings of cloudable cells; apply_area_cloud
    -- chooses a random cell from each ring until its cloud budget is spent.
    while #queue > 0 and placed < count do
        for index = #queue, 2, -1 do
            local other = 1 + ctx:random("spell", index)

            queue[index], queue[other] = queue[other], queue[index]
        end

        local next_ring = {}

        for _, cell in ipairs(queue) do
            if placed < count then
                if cloud.place(ctx, zap_ids.cloud.COLD, player, level,
                    cell.x, cell.y, duration(ctx, power)) then
                    placed = placed + 1
                end
            end

            for _, direction in ipairs(directions) do
                local next_x = cell.x + direction[1]
                local next_y = cell.y + direction[2]
                local id = key(next_x, next_y)

                if not seen[id] then
                    seen[id] = true

                    if ctx:walkable(level, next_x, next_y) and
                        not cloud.at(ctx, level, next_x, next_y) and
                        ctx:projectile_clear(level, origin.x, origin.y,
                            next_x, next_y) then
                        next_ring[#next_ring + 1] = {
                            x = next_x,
                            y = next_y,
                        }
                    end
                end
            end
        end

        queue = next_ring
    end

    ctx:emit("spell", "Freezing vapour billows outward!")
end

registry.add(spells.SPELL_FREEZING_CLOUD, freezing_cloud)

return freezing_cloud
