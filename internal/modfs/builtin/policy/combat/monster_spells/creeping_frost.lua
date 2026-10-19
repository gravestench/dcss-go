-- Creeping Frost checks the caster's entire visible area. Every unaligned
-- actor beside a visible solid wall gets its own ice contact; allies are
-- spared, while an incidental neutral bystander is not.
-- Source: mon-cast.cc:_near_visible_wall and _cast_creeping_frost.
local actors = require("policy.combat.monster_area.actors")
local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local flash_freeze = require("policy.combat.monster_beams.flash_freeze")
local power = require("policy.combat.monster_beams.power")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CREEPING_FROST)
local SIGHT_RADIUS = 7

-- A transparent or unseen wall does not count. Recheck live terrain at
-- resolution so terrain changes do not preserve a stale area hit list.
local function near_visible_wall(ctx, source, destination)
    if not ctx:visible_no_trans(source.level_id,
        source.x, source.y, SIGHT_RADIUS,
        destination.x, destination.y) then
        return false
    end

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = destination.x + dx
                local y = destination.y + dy
                local feature = ctx:cell(source.level_id, x, y)

                if feature and feature ~= terrain.DNGN_MALIGN_GATEWAY and
                    not ctx:walkable(source.level_id, x, y) and
                    ctx:visible_no_trans(source.level_id,
                        source.x, source.y, SIGHT_RADIUS, x, y) then
                    return true
                end
            end
        end
    end

    return false
end

-- The selected foe must be eligible before the monster chooses this cast;
-- another foe may also be caught when resolution scans the visible area.
function effect.plan(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id or
        not targets.enemy(ctx, caster, foe) or
        not near_visible_wall(ctx, source, destination) then
        return nil
    end

    return self_target.plan(caster)
end

-- Unlike Flash Freeze, Creeping Frost damages an already frozen player.
-- The source only adds frozen status for player contact; monsters still
-- take ice damage but do not receive this spell's frozen condition.
function effect.after_hit(ctx, _, victim)
    if ctx:has(victim, component.PLAYER) then
        flash_freeze.after_hit(ctx, nil, victim)
    end
end

-- Resolve each eligible body independently through the ordinary beam
-- contact owner, with source automatic-hit accuracy.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local source = ctx:get(caster, component.POSITION)
    local spell_power = power.caster_power(ctx, caster, profile)
    local to_hit = calculators.to_hit(profile, spell_power)

    for _, victim in ipairs(actors.los(ctx, caster, SIGHT_RADIUS)) do
        local destination = ctx:get(victim, component.POSITION)

        if not targets.aligned(ctx, caster, victim) and
            near_visible_wall(ctx, source, destination) then
            contact.resolve(ctx, caster, victim,
                profile, spell_power, to_hit, effect)
        end
    end
end

return effect
