local spells = require("ids.spells")
local component = require("constants.component")
local blink = require("policy.combat.dispersal")
local confusion = require("policy.magic.effects.statuses.confusing_touch")
local common = require("policy.magic.effects.translocation.common")
local net = require("policy.combat.net")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local teleport = require("policy.magic.effects.zaps.teleport_other")
local will = require("policy.magic.effects.zaps.will")

-- Source: spl-transloc.cc:cast_dispersal and _disperse_monster.
local spell_effects = {}

function spell_effects.resolve(ctx, player, _, spell, power)
    local center = ctx:get(player, component.POSITION)
    local radius = range.for_spell(ctx, player, spell)
    local moved = false

    for _, monster in ipairs(common.monsters(ctx, center.level_id)) do
        if common.distance(center, monster.position) <= radius and
            not teleport.no_tele(monster.actor, monster.definition) then
            if will.resists(ctx, monster.definition, power) then
                moved = blink.blink(ctx, player, monster.entity,
                    monster.definition) or moved
            else
                local x, y = teleport.random_destination(ctx,
                    monster.entity, monster.position)

                if x then
                    net.release(ctx, monster.entity)
                    ctx:move_actor(monster.entity, center.level_id, x, y)
                    moved = true
                    if not will.resists(ctx, monster.definition, power) then
                        confusion.apply_innate(ctx, monster.entity,
                            monster.definition)
                    end
                    ctx:emit("spell", "The " .. monster.definition.name ..
                        " disappears!")
                end
            end
        end
    end

    if not moved then
        ctx:emit("spell", "The air shimmers briefly around you.")
    end
end

registry.add(spells.SPELL_DISPERSAL, {
    resolve = spell_effects.resolve,
})

return spell_effects
