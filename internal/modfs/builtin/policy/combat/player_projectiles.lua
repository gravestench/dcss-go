local catalog = require("policy.catalog")
local fighter = require("policy.combat.fighter")
local items = require("policy.inventory.items")
local net = require("policy.combat.net")
local player_attack = require("policy.combat.player_attack")
local effects = require("policy.combat.projectile_effects")
local launcher_brands = require("policy.combat.launcher_brands")
local practice = require("policy.combat.practice")
local roll = require("policy.combat.roll")
local trajectory = require("policy.combat.trajectory")
local statuses = require("policy.magic.effects.statuses.player")
local monster_defense = require("policy.combat.monster_defense")
local repulsion = require("policy.combat.monster_support.repulsion")
local player_attributes = require("policy.character.attributes")
local vision = require("policy.character.vision")
local player_slay = require("policy.combat.player_slay")
local monster_health = require("policy.combat.monster_health")
local attack_conduct = require("policy.religion.conduct.attack")
local projectile_conduct = require("policy.religion.conduct.projectiles")
local missile_egos = require("constants.missile_egos")
local item_ids = require("ids.items")
local skills = require("ids.skills")

local projectiles = {}

-- An equipped launcher supplies its own ammo kind; a thrown item is already the missile.
local function missile_for(ctx, entity)
    local item = ctx:get(entity, "core.item")
    local kind = items.kind(item)

    if kind.class == "OBJ_WEAPONS" and kind.weapon then
        return catalog.get("items", kind.weapon.ammo_id), true, kind, item
    end

    return kind, false, nil, item
end

-- Nets persist for holds, while stones and selected egos always mulch before stack handling.
local function destroyed(ctx, item, kind)
    if kind.id == item_ids.MI_THROWING_NET then
        return false
    end

    if kind.id == item_ids.MI_STONE or
        item.ego == missile_egos.DISPERSAL or
        item.ego == missile_egos.CHAOS or
        item.ego == missile_egos.EXPLODING then
        return true
    end

    local rate = kind.missile.mulch_rate

    if item.ego == missile_egos.CURARE then
        rate = rate * 2
    end

    return rate > 0 and ctx:random("melee", rate) == 0
end

-- Merge a surviving missile with floor stock unless a caught net needs its own entity.
local function land(ctx, item, kind, entity, position, separate)
    -- Resolve mulch before changing stack quantities; a caught net needs a
    -- separate floor entity so its held status can refer to that item.
    local mulched = destroyed(ctx, item, kind)

    -- A surviving boomerang retraces to the thrower in throw.cc.
    if kind.id == item_ids.MI_BOOMERANG and not mulched then
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

-- Build one accuracy and damage snapshot from launcher or throwing skill before contact.
local function attack_input(ctx, player, missile, launcher, item, target, defender)
    local attributes = player_attributes.current(ctx, player)
    local weapon = launcher and launcher.weapon or nil
    local skill_id = weapon and weapon.skill_id or skills.SK_THROWING
    local throwing_bonus = 0

    if not launcher then
        local throwing100 = fighter.skill(ctx, skills.SK_THROWING, 100)
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
        slay = player_slay.total(ctx, player),
        weapon_plus = weapon and item.plus or 0,
        defender_ev = monster_defense.evasion(ctx, target, defender),
        missile_repulsion = repulsion.active(ctx, target),
        defender_ac = monster_defense.armour(ctx, target, defender),
        defender_shield = monster_defense.shield(ctx, target, defender),
        penetrating = missile.id == item_ids.MI_JAVELIN,
        mighty = false,
    }

    return input
end

-- Nets and darts use contact only; damaging missiles apply brands after base HP loss.
local function resolve_target(ctx, player, missile, launcher, item, target)
    local defender_actor = ctx:get(target, "core.actor")
    local defender = catalog.get("monsters", defender_actor.kind_id)

    attack_conduct.report(ctx, target, defender)

    local input = attack_input(ctx, player, missile, launcher, item, target, defender)
    local outcome

    if missile.id == item_ids.MI_THROWING_NET or
        missile.id == item_ids.MI_DART then
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
        monster_defense.register_block(ctx, target)
        message = "The " .. defender.name .. " blocks the " .. missile.name .. "."
    elseif outcome.kind == "hit" then
        message = "The " .. missile.name .. " hits the " .. defender.name .. "."

        if missile.id == item_ids.MI_THROWING_NET then
            caught = net.can_hold(defender) and
                not ctx:has(target, "projectile.held")
        else
            local health = ctx:get(target, "core.health")
            local brand_damage = 0

            if launcher then
                brand_damage, effect_message = launcher_brands.apply(ctx,
                    item.ego, missile, defender, outcome.damage)
            end

            health, outcome.damage = monster_health.damage(ctx, target,
                outcome.damage, player)

            if health.current > 0 and not launcher then
                brand_damage = brand_damage + effects.missile(ctx,
                    item.ego, missile, target, defender, outcome.damage,
                    health.current)
            end

            health = monster_health.damage(ctx, target, brand_damage, player)

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

-- Example: projectiles.practice(ctx, item_id) with committed launcher shot -> practice event even on a miss
-- Train the committed shot using resolved ammo and launcher, even when the attack misses.
function projectiles.practice(ctx, item_id)
    local entity = ctx:entity(item_id)
    local missile, _, launcher = missile_for(ctx, entity)
    practice.player_projectile(ctx, missile, launcher)
end

-- Trace normal flight or portal aim, then stop nonpenetrating missiles on hit or block.
function projectiles.resolve(ctx, player, intent)
    local position = ctx:get(player, "core.position")
    local entity = intent.item_id
    local missile, launched, launcher, item = missile_for(ctx, entity)
    local penetrating = not launched and missile.id == item_ids.MI_JAVELIN
    local portal = statuses.portal_projectile_active(ctx, player)
    local impact

    -- Portal Projectile skips trajectory tracing and attacks the aimed cell
    -- directly, then pays its extra cost after the shot resolves.
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
            position.x + intent.dx, position.y + intent.dy,
            vision.radius(ctx, player))
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

        -- Javelins continue through contacts; other missiles stop on a hit
        -- or block, but a miss lets the flight continue.
        if not penetrating and outcome ~= "miss" then
            impact.x = contact.x
            impact.y = contact.y

            break
        end
    end

    if not launched then
        local separate_net = missile.id == item_ids.MI_THROWING_NET and caught
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

    projectile_conduct.on_shot(ctx, player, entity, launched, item)
end

return projectiles
