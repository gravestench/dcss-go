-- Theory of operation: Lugonu's six-star gift selects a carried,
-- non-artefact melee weapon, confirms its permanent distortion brand,
-- then enchants that same item twice. A saved choice stores its entity ID;
-- both preparation and resolution recheck ownership and eligibility.
local abilities = require("ids.abilities")
local brands = require("constants.weapon_brands")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local identification = require("policy.items.identification")
local object_classes = require("ids.object_classes")
local registry = require("policy.abilities.registry")
local selection_kinds = require("constants.selection_kinds")
local skills = require("ids.skills")

local blessing = {}

-- This permanent gift remains spent after apostasy and later rejoining.
function blessing.available(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local spent = worship and worship.one_time_abilities or {}

    return costs.available(ctx, player, gods.LUGONU, 6) and
        not spent[gods.LUGONU]
end

-- A displayed name cannot establish ownership or distinguish artefacts.
-- Read the actual carried item and immutable weapon catalog instead.
function blessing.eligible(ctx, player, entity)
    local item = entity and ctx:get(entity, component.ITEM)
    local carrier = entity and ctx:get(entity, component.CARRIED_BY)

    if not item or not carrier or carrier.holder ~= player or
        ctx:has(entity, component.ITEM_ARTEFACT) then
        return false
    end

    local kind = catalog.get(categories.ITEMS, item.kind_id)

    return kind.class == object_classes.OBJ_WEAPONS and
        kind.weapon ~= nil and
        kind.weapon.skill_id ~= skills.SK_RANGED_WEAPONS
end

-- Only legal weapons enter the free item menu. Option IDs are stable ECS
-- entity IDs; labels may be changed by a mod without changing the choice.
local function item_prompt(ctx, player)
    local options = {}

    for _, entity in ipairs(ctx:query({ component.ITEM })) do
        if blessing.eligible(ctx, player, entity) then
            options[#options + 1] = {
                id = tostring(ctx:id(entity)),
                label = identification.name(ctx, player, entity),
            }
        end
    end

    if #options == 0 then
        return { message = "You have no weapon Lugonu can corrupt." }
    end

    return {
        selection = {
            kind = selection_kinds.ITEM,
            title = "Brand which weapon?",
            options = options,
        },
    }
end

-- Both Esc and a refused confirmation erase the saved free choice.
-- A stale item or change of worship never commits a timed intent.
function blessing.prepare(ctx, player, input)
    local pending = ctx:get(player, component.LUGONU_BLESS_CHOICE)

    if input.cancelled then
        if pending then
            ctx:remove(player, component.LUGONU_BLESS_CHOICE)
        end

        return "Okay."
    end

    if pending then
        if not blessing.available(ctx, player) or
            not blessing.eligible(ctx, player, pending.item) then
            ctx:remove(player, component.LUGONU_BLESS_CHOICE)

            return "That weapon is no longer available."
        end

        if not input.forced then
            return {
                confirmation = "Do you wish to have " ..
                    identification.name(ctx, player, pending.item) ..
                    " corrupted with distortion?",
            }
        end

        input.item_id = ctx:id(pending.item)

        return nil
    end

    local selected_id = tonumber(input.target_id)
    local selected = selected_id and ctx:entity(selected_id)

    if not selected then
        return item_prompt(ctx, player)
    end

    if not blessing.eligible(ctx, player, selected) then
        return "Lugonu cannot corrupt that weapon."
    end

    ctx:add(player, component.LUGONU_BLESS_CHOICE, {
        item = selected,
    })

    return {
        confirmation = "Do you wish to have " ..
            identification.name(ctx, player, selected) ..
            " corrupted with distortion?",
    }
end

-- The source's two enchant calls each stop at +9. The capstone itself
-- spends no MP or piety and records a permanent per-god use flag.
function blessing.resolve(ctx, player, intent)
    local pending = ctx:get(player, component.LUGONU_BLESS_CHOICE)

    if not pending or ctx:id(pending.item) ~= ctx:id(intent.item_id) or
        not blessing.available(ctx, player) or
        not blessing.eligible(ctx, player, pending.item) then
        error("invalid Lugonu blessing intent")
    end

    local item = ctx:get(pending.item, component.ITEM)

    item.ego = brands.DISTORTION
    item.plus = math.min(9, item.plus + 2)
    ctx:set(pending.item, component.ITEM, item)
    ctx:remove(player, component.LUGONU_BLESS_CHOICE)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.one_time_abilities[gods.LUGONU] = true
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    ctx:emit("religion", "Your weapon shines brightly! Lugonu booms: Use this gift wisely!")
end

-- Reject forged or stale saved choices before the player can resume them.
function blessing.validate(ctx, player)
    local pending = ctx:get(player, component.LUGONU_BLESS_CHOICE)

    if pending and (not blessing.available(ctx, player) or
        not blessing.eligible(ctx, player, pending.item)) then
        error("invalid saved Lugonu blessing choice")
    end
end

registry.add(abilities.LUGONU_BLESS_WEAPON, {
    name = "Bless Weapon",
    available = blessing.available,
    owns_cancellation = true,
    prepare = blessing.prepare,
    resolve = blessing.resolve,
})

return blessing
