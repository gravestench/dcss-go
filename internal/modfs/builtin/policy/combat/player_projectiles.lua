local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local items = require("policy.inventory.items")
local net = require("policy.combat.net")
local player_attack = require("policy.combat.player_attack")
local effects = require("policy.combat.projectile_effects")
local practice = require("policy.combat.practice")
local roll = require("policy.combat.roll")
local trajectory = require("policy.combat.trajectory")
local statuses = require("policy.magic.effects.statuses.player")
local monster_defense = require("policy.combat.monster_defense")

local projectiles = {}

local function missile_for(ctx, entity)
    local item = ctx:get(entity, "core.item")
    local kind = items.kind(item)

    if kind.class == "OBJ_WEAPONS" and kind.weapon then
        return catalog.get("items", kind.weapon.ammo_id), true, kind, item
    end

    return kind, false, nil, item
end

local function destroyed(ctx, item, kind)
    if kind.id == "MI_THROWING_NET" then
        return false
    end

    if kind.id == "MI_STONE" or item.ego == "dispersal" or
        item.ego == "chaos" or item.ego == "exploding" then
        return true
    end

    local rate = kind.missile.mulch_rate

    if item.ego == "curare" then
        rate = rate * 2
    end

    return rate > 0 and ctx:random("melee", rate) == 0
end

local function land(ctx, item, kind, entity, position, separate)
    local mulched = destroyed(ctx, item, kind)

    -- A surviving boomerang retraces to the thrower in throw.cc:857-866.
    if kind.id == "MI_BOOMERANG" and not mulched then
        return
    end

    local floor_item

    if not mulched then
        local floor = not separate and items.floor_stack(ctx, position, item, entity)

        if floor then
            local stack = ctx:get(floor, "core.item")
            stack.quantity = stack.quantity + 1
            ctx:set(floor, "core.item", stack)
            floor_item = floor
        else
            local dropped = ctx:create()

            ctx:add(dropped, "core.item", {
                kind_id = item.kind_id,
                quantity = 1,
                plus = item.plus,
                charges = item.charges,
                ego = item.ego,
            })
            ctx:add(dropped, "core.position", position)
            floor_item = dropped
        end
    end

    item.quantity = item.quantity - 1

    if item.quantity == 0 then
        ctx:destroy(entity)
    else
        ctx:set(entity, "core.item", item)
    end

    return floor_item
end

local function attack_input(ctx, player, missile, launcher, item, target, defender)
    local attributes = ctx:get(player, "core.attributes")
    local weapon = launcher and launcher.weapon or nil
    local skill_id = weapon and weapon.skill_id or "SK_THROWING"
    local throwing_bonus = 0
    local shield = equipment.monster_shield(ctx, target)
    local combat = ctx:get(target, "core.combat")

    if not launcher then
        local throwing100 = fighter.skill(ctx, "SK_THROWING", 100)
        throwing_bonus = roll.random_divide(ctx,
            throwing100 * math.min(4, missile.missile.damage), 400)
    end

    local input = {
        strength = attributes.strength,
        dexterity = attributes.dexterity,
        damage_attribute = weapon and attributes.dexterity or attributes.strength,
        fighting100 = fighter.skill(ctx, "SK_FIGHTING", 100),
        weapon100 = fighter.skill(ctx, skill_id, 100),
        weapon_skill = skill_id,
        using_weapon = launcher ~= nil,
        weapon_damage = missile.missile.damage + (weapon and weapon.damage or throwing_bonus),
        weapon_hit = weapon and weapon.hit or 0,
        hit_bonus = statuses.portal_projectile_hit_bonus(ctx, player),
        weapon_plus = weapon and item.plus or 0,
        defender_ev = monster_defense.evasion(ctx, target, defender),
        defender_ac = monster_defense.armour(ctx, target, defender),
        penetrating = missile.id == "MI_JAVELIN",
        mighty = false,
    }

    if shield then
        input.defender_shield = {
            ac = shield.definition.armour.ac,
            plus = shield.item.plus,
            subtype = shield.definition.subtype_value,
            size = defender.size_id,
            hit_dice = defender.hd,
            blocks = combat.shield_blocks,
            name = shield.definition.name,
        }
    end

    return input
end

local function resolve_target(ctx, player, missile, launcher, item, target)
    local defender_actor = ctx:get(target, "core.actor")
    local defender = catalog.get("monsters", defender_actor.kind_id)
    local input = attack_input(ctx, player, missile, launcher, item, target, defender)
    local outcome

    if missile.id == "MI_THROWING_NET" or missile.id == "MI_DART" then
        outcome = player_attack.contact(ctx, input)
    else
        outcome = player_attack.resolve(ctx, input)
    end

    local message = "The " .. missile.name .. " misses the " .. defender.name .. "."
    local effect_message
    local caught = false

    if outcome.pierced_shield then
        ctx:emit("combat", "The " .. missile.name .. " pierces through the " ..
            defender.name .. "'s " .. input.defender_shield.name .. "!")
    end

    if outcome.kind == "block" then
        local combat = ctx:get(target, "core.combat")
        combat.shield_blocks = combat.shield_blocks + 1
        ctx:set(target, "core.combat", combat)
        message = "The " .. defender.name .. " blocks the " .. missile.name .. "."
    elseif outcome.kind == "hit" then
        message = "The " .. missile.name .. " hits the " .. defender.name .. "."

        if missile.id == "MI_THROWING_NET" then
            caught = net.can_hold(defender) and
                not ctx:has(target, "projectile.held")
        else
            local health = ctx:get(target, "core.health")
            local brand_damage = 0

            if launcher then
                brand_damage, effect_message = effects.launcher(ctx,
                    item.ego, missile, defender, outcome.damage)
            end

            statuses.wake_hibernating(ctx, target)
            outcome.damage = statuses.petrified_damage(ctx, target,
                outcome.damage)
            health.current = math.max(0, health.current - outcome.damage)

            if health.current > 0 and not launcher then
                brand_damage = brand_damage + effects.missile(ctx,
                    item.ego, missile, target, defender, outcome.damage,
                    health.current)
            end

            brand_damage = statuses.petrified_damage(ctx, target,
                brand_damage)
            health.current = math.max(0, health.current - brand_damage)
            ctx:set(target, "core.health", health)

            if health.current == 0 then
                ctx:signal("player_kill", target)
            end
        end
    end

    ctx:emit("combat", message)

    if effect_message then
        ctx:emit("combat", effect_message)
    end

    return defender, caught, outcome.kind
end

function projectiles.practice(ctx, item_id)
    local entity = ctx:entity(item_id)
    local missile, _, launcher = missile_for(ctx, entity)
    practice.player_projectile(ctx, missile, launcher)
end

function projectiles.resolve(ctx, player, intent)
    local position = ctx:get(player, "core.position")
    local entity = intent.item_id
    local missile, launched, launcher, item = missile_for(ctx, entity)
    local penetrating = not launched and missile.id == "MI_JAVELIN"
    local portal = statuses.portal_projectile_active(ctx, player)
    local impact

    if portal then
        local x = position.x + intent.dx
        local y = position.y + intent.dy
        local target = ctx:actor_at(position.level_id, x, y)
        local contacts = {}

        if target then
            contacts[1] = { actor = target, x = x, y = y }
        end

        impact = { x = x, y = y, contacts = contacts }
    else
        impact = trajectory.trace(ctx, position.level_id, position.x, position.y,
            position.x + intent.dx, position.y + intent.dy, 7)
    end
    local verb = launched and "shoot" or "throw"

    ctx:emit("combat", "You " .. verb .. " " .. items.phrase(missile.name, 1) .. ".")

    local defender
    local caught = false
    local caught_target

    for _, contact in ipairs(impact.contacts) do
        local outcome
        defender, caught, outcome = resolve_target(ctx, player, missile,
            launcher, item, contact.actor)

        if caught then
            caught_target = contact.actor
        end

        if not penetrating and outcome ~= "miss" then
            impact.x = contact.x
            impact.y = contact.y

            break
        end
    end

    if not launched then
        local separate_net = missile.id == "MI_THROWING_NET" and caught
        local floor_item = land(ctx, item, missile, entity, {
            level_id = position.level_id,
            x = impact.x,
            y = impact.y,
        }, separate_net)

        if caught then
            net.catch(ctx, caught_target, floor_item, defender)
        end
    end

    if portal then
        statuses.portal_projectile_pay(ctx, player)
    end
end

return projectiles
