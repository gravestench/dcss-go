local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local monsters = require("ids.monsters")
local terrain = require("constants.terrain")
local cloud = require("policy.magic.effects.zaps.cloud")
local explosion = require("policy.combat.explosion")
local explosive = require("policy.magic.effects.zaps.explosive")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local fire_storm = {}

-- zap-data.h:ZAP_FIRE_STORM and spl-damage.cc:setup_fire_storm.
local spec = {
    name = "great blast of fire",
    cap = 200,
    element = "MR_RES_FIRE",
    resistible_fraction = 55,
    damage = {
        count = 8,
        base = 5,
        numerator = 1,
        denominator = 1,
    },
}

function fire_storm.prepare(ctx, player, spell, dx, dy)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + dx
    local y = origin.y + dy
    local reach = range.for_spell(ctx, player, spell)

    if math.max(math.abs(dx), math.abs(dy)) > reach or
        not ctx:visible(origin.level_id, origin.x, origin.y, reach, x, y) or
        not ctx:walkable(origin.level_id, x, y) then
        return "You can't place the storm there."
    end
end

function fire_storm.resolve(ctx, player, intent, _, power)
    local origin = ctx:get(player, component.POSITION)
    local center_x = origin.x + intent.dx
    local center_y = origin.y + intent.dy
    local capped = math.min(power, 200)
    local radius = 2 + (ctx:random("spell", 1000) < capped and 1 or 0)

    ctx:emit("spell", "A great blast of fire erupts!")

    for _, cell in ipairs(explosion.cells(ctx, origin.level_id,
        center_x, center_y, radius)) do
        local target = ctx:actor_at(origin.level_id, cell.x, cell.y)

        if target then
            explosive.hurt(ctx, player, target, spec, capped)
        end

        -- beam.cc:affect_place_explosion_clouds. Clouds occupy every blast
        -- cell. Empty floor cells have a one-in-four vortex spawn chance.
        local duration = 2 + math.floor((ctx:random("spell", 5) +
            ctx:random("spell", 5)) / 2)

        cloud.place(ctx, zap_ids.cloud.FIRE, player,
            origin.level_id, cell.x, cell.y, duration * 10)

        if ctx:cell(origin.level_id, cell.x, cell.y) == terrain.DNGN_FLOOR and
            not ctx:actor_at(origin.level_id, cell.x, cell.y) and
            ctx:random("spell", 4) == 0 then
            summons.spawn(ctx, player, spells.SPELL_FIRE_STORM,
                monsters.MONS_FIRE_VORTEX, 1, 999, {
                    anchor = {
                        level_id = origin.level_id,
                        x = cell.x,
                        y = cell.y,
                    },
                    exact = { x = cell.x, y = cell.y },
                })
        end
    end
end

registry.add(spells.SPELL_FIRE_STORM, fire_storm)

return fire_storm
