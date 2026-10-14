local catalog = require("policy.catalog")
local brands = require("policy.combat.brands")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local practice = require("policy.combat.practice")
local ranged = require("policy.combat.ranged")

local actions = {}

local function adjacent(a, b)
    return a.level_id == b.level_id and
        math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1
end

local function target(ctx, attacker, kind_id)
    local player = ctx:player()
    local actor = ctx:get(attacker, "core.actor")
    local attack_pos = ctx:get(attacker, "core.position")
    local player_pos = ctx:get(player, "core.position")
    local attack_health = ctx:get(attacker, "core.health")
    local health = ctx:get(player, "core.health")

    if not actor or actor.kind_id ~= kind_id or not attack_pos or not player_pos or
        not attack_health or not health or attack_health.current <= 0 or
        health.current <= 0 or attack_pos.level_id ~= player_pos.level_id or
        adjacent(attack_pos, player_pos) then
        error("monster cannot shoot distant or dead player")
    end

    if not ctx:projectile_clear(attack_pos.level_id, attack_pos.x, attack_pos.y,
        player_pos.x, player_pos.y) then
        error("monster has no clear shot")
    end

    return catalog.get("monsters", kind_id), fighter.defense(ctx), health
end

local function apply(ctx, outcome, health, defense)
    local player = ctx:player()
    local state = ctx:get(player, "core.combat")

    if not state then
        error("player has no combat state")
    end

    state.shield_blocks = outcome.shield_blocks
    health.current = math.max(0, health.current - outcome.damage)
    ctx:set(player, "core.combat", state)
    ctx:set(player, "core.health", health)

    if outcome.kind == "block" then
        practice.incoming_shield(ctx, outcome, defense)
    end
end

function actions.goblin(ctx, attacker, intent)
    local definition, defense, health = target(ctx, attacker, "MONS_GOBLIN")
    local worn = equipment.worn(ctx, attacker, { weapon = true })
    local launcher = worn.weapon

    if not launcher or launcher.entity ~= intent.item_id or
        launcher.definition.id ~= "WPN_SLING" then
        error("goblin has no matching sling")
    end

    local brand = launcher.item.ego or ""

    if brand ~= "" and brand ~= "SPWPN_NORMAL" and brand ~= "SPWPN_FLAMING" and
        brand ~= "SPWPN_FREEZING" and brand ~= "SPWPN_VORPAL" then
        error("unsupported goblin sling brand " .. brand)
    end

    local weapon = launcher.definition.weapon
    local projectile = catalog.get("items", weapon.ammo_id)

    if projectile.class ~= "OBJ_MISSILES" or not projectile.missile then
        error("sling has invalid projectile")
    end

    local outcome = ranged.shot(ctx, {
        hd = definition.hd,
        weapon_damage = weapon.damage,
        weapon_hit = weapon.hit,
        weapon_plus = launcher.item.plus,
        projectile_damage = projectile.missile.damage,
        natural_damage = definition.attacks[1].damage,
    }, defense)

    apply(ctx, outcome, health, defense)
    ctx:emit("combat", "The goblin shoots a sling bullet.")

    local message = "The sling bullet misses you."

    if outcome.kind == "block" then
        message = "You block the sling bullet."
    elseif outcome.kind == "hit" then
        if outcome.damage == 0 then
            message = "The sling bullet hits you but does no damage."
        else
            message = "The sling bullet hits you for " .. outcome.damage .. " damage."
        end
    end

    ctx:emit("combat", message)

    if outcome.kind == "hit" and
        (health.current > 0 or brands.after_death(brand)) then
        brands.apply(ctx, brand, outcome.damage, "MONS_GOBLIN", "sling bullet", health)
        ctx:set(ctx:player(), "core.health", health)
    end
end

function actions.kobold(ctx, attacker, intent)
    local definition, defense, health = target(ctx, attacker, "MONS_KOBOLD")
    local worn = equipment.worn(ctx, attacker, { missile = true })
    local missile = worn.missile

    if not missile or missile.entity ~= intent.item_id or missile.item.quantity <= 0 then
        error("kobold has no matching missile stack")
    end

    local kind = missile.definition
    local valid_stone = kind.id == "MI_STONE" and missile.item.ego == ""
    local valid_dart = kind.id == "MI_DART" and missile.item.ego == "poisoned"

    if not valid_stone and not valid_dart then
        error("unsupported kobold missile " .. kind.id)
    end

    local outcome
    local poison = 0

    if valid_dart then
        outcome, poison = ranged.poison_dart(ctx, definition.hd, defense)
    else
        outcome = ranged.shot(ctx, {
            hd = definition.hd,
            weapon_damage = 0,
            projectile_damage = kind.missile.damage,
            natural_damage = definition.attacks[1].damage,
        }, defense)
    end

    apply(ctx, outcome, health, defense)

    local name = valid_dart and "poisoned dart" or "stone"
    ctx:emit("combat", "The kobold throws a " .. name .. ".")

    local message = "The " .. name .. " misses you."

    if outcome.kind == "block" then
        message = "You block the " .. name .. "."
    elseif outcome.kind == "hit" then
        message = "The " .. name .. " hits you."

        if valid_stone then
            if outcome.damage == 0 then
                message = "The stone hits you but does no damage."
            else
                message = "The stone hits you for " .. outcome.damage .. " damage."
            end
        end
    end

    ctx:emit("combat", message)

    if poison > 0 then
        brands.poison(ctx, poison, "MONS_KOBOLD")
    end
end

return actions
