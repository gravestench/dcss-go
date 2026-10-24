-- Example: Mana Link can redirect recovery when MP is empty and HP is below maximum.
local capabilities = require("constants.mutation_capabilities")
local mutation_effects = require("policy.mutations.effects.registry")
local component = require("constants.component")
local vision = require("policy.character.vision")
local targets = require("policy.ai.targets")
local powered = require("policy.character.powered_by_death")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local jiyva_defenses = require("policy.religion.jiyva.defenses")
local trog_hand = require("policy.religion.trog.hand")

local regeneration = {}

-- Source: player.cc:player_regen and player_mp_regen. The status system
-- applies healing gates after these base and mutation rates are computed.
function regeneration.rates(ctx, player, maximum_hp, maximum_mp)
    local hp = math.floor(maximum_hp / 3)

    if hp > 20 then
        hp = 20 + math.floor((hp - 20) / 2)
    end

    hp = hp + mutation_effects.sum(ctx, player,
        capabilities.HP_REGEN_BONUS)
    hp = hp + jewellery_effects.sum(ctx, player,
        jewellery_capabilities.HP_REGEN)
    hp = hp + powered.strength(ctx, player) * 100
    hp = math.max(1, hp)
    hp = hp + jiyva_defenses.hp_bonus(ctx, player)
    hp = hp + (trog_hand.active(ctx, player) and 100 or 0)

    local mp = 7 + math.floor(maximum_mp / 2)

    if mutation_effects.sum(ctx, player,
        capabilities.MP_REGEN_DOUBLE) > 0 then
        mp = mp * 2
    end

    mp = mp + jewellery_effects.sum(ctx, player,
        jewellery_capabilities.MP_REGEN)
    mp = mp + jiyva_defenses.mp_bonus(ctx, player)

    if mutation_effects.sum(ctx, player,
        capabilities.HP_CASTING) > 0 then
        mp = 0
    end

    return hp, mp
end

-- Source: player.cc:regeneration_is_inhibited. A nearby, visible, hostile
-- monster stops the first level of inhibited regeneration.
-- Nearby hostile visibility suppresses recovery where the source rule requires safety.
local function threatening_monster_visible(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        error("inhibited regeneration requires player position")
    end

    local sight = vision.radius(ctx, player)

    for _, entity in ipairs(ctx:query({
        component.AI,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)
        local range = math.max(math.abs(position.x - origin.x),
            math.abs(position.y - origin.y))

        if targets.enemy(ctx, player, entity) and health.current > 0 and
            position.level_id == origin.level_id and range <= sight and
            ctx:visible(origin.level_id, origin.x, origin.y,
                sight, position.x, position.y) then
            return true
        end
    end

    return false
end

-- Visible threats gate natural HP recovery here after the base regeneration rate is calculated.
function regeneration.hp_allowed(ctx, player)
    if mutation_effects.sum(ctx, player,
        capabilities.HP_REGEN_FORBIDDEN) > 0 then
        return false
    end

    if mutation_effects.sum(ctx, player,
        capabilities.HP_REGEN_INHIBITED) > 0 then
        return not threatening_monster_visible(ctx, player)
    end

    return true
end

-- A natural-regeneration blocker must not grant the ordinary HP rate.
-- Jiyva's separate pip and Trog's Hand survive it, as in player.cc.
function regeneration.effective_hp_rate(ctx, player, total_rate)
    if regeneration.hp_allowed(ctx, player) then
        return total_rate
    end

    return jiyva_defenses.hp_bonus(ctx, player) +
        (trog_hand.active(ctx, player) and 100 or 0)
end

-- Source: player-reacts.cc:regen_hp diverts each HP pip to MP when Mana
-- Link is active and a current-MP-in-max-MP chance does not succeed.
-- Some effects redirect an HP regeneration point into MP while the magic pool is deficient.
function regeneration.hp_restores_magic(ctx, player, magic)
    if mutation_effects.sum(ctx, player,
        capabilities.MANA_LINK) == 0 or
        magic.current >= magic.max then
        return false
    end

    if magic.current == 0 then
        return true
    end

    return ctx:random("regeneration", magic.max) >= magic.current
end

return regeneration
