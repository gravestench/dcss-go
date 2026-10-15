local mutation_effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local catalog = require("policy.catalog")
local object_classes = require("ids.object_classes")
local effects = require("policy.magic.effects.registry")
local intent = require("constants.intent")
local power = require("policy.magic.power")
local range = require("policy.magic.range")
local resources = require("policy.magic.resources")
local skill_ids = require("ids.skills")
local identification = require("policy.items.identification")

local wands = {}

-- Source: spl-book.cc:spell_in_wand. Each wand definition owns its spell
-- link; a mod can add a new wand without editing this resolver.
function wands.spell(wand_id)
    local definition = catalog.get("items", wand_id)

    if definition.class ~= object_classes.OBJ_WANDS then
        return nil
    end

    return definition.wand_spell_id
end

-- Source: evoke.cc:wand_mp_cost. Djinn spend HP, but the last HP is safe.
function wands.mp_cost(ctx, player)
    local maximum = mutation_effects.sum(ctx, player,
        capabilities.WAND_MP_COST)

    if maximum == 0 then
        return 0
    end

    if mutation_effects.sum(ctx, player, capabilities.HP_CASTING) > 0 then
        local health = ctx:get(player, "core.health")

        return math.min(math.max(0, health.current - 1), maximum)
    end

    local magic = ctx:get(player, "core.magic")

    return math.min(magic.current, maximum)
end

-- Source: evoke.cc:wand_power. The sevenfold skill scale is part of the
-- source integer formula, before MP Wands multiplies the result.
function wands.power(ctx, player, cost)
    local skill = power.training(ctx, player, skill_ids.SK_EVOCATIONS, 7)

    return math.floor((15 + math.floor(skill / 2)) * (cost + 9) / 9)
end

function wands.prepare(ctx, player, item_id, dx, dy)
    local entity = item_id ~= 0 and ctx:entity(item_id) or nil
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= player then
        return { message = "You are not carrying that wand." }
    end

    local spell_id = wands.spell(item.kind_id)

    if not spell_id then
        return { message = "You can't zap that!" }
    end

    if item.charges <= 0 then
        return { message = "That wand has no charges." }
    end

    if dx == 0 and dy == 0 then
        return { message = "Okay, then." }
    end

    local spell = catalog.get("spells", spell_id)
    local reach = range.for_spell(ctx, player, spell)

    if math.max(math.abs(dx), math.abs(dy)) > reach then
        return { message = "That is beyond your range." }
    end

    local effect = effects.get(spell_id)

    if not effect then
        error("wand " .. item.kind_id .. " lacks its spell effect")
    end

    if effect.prepare then
        local rejection = effect.prepare(ctx, player, spell, dx, dy)

        if rejection then
            return { message = rejection }
        end
    end

    return {
        intent = {
            kind = intent.EVOKE_WAND,
            item_id = entity,
            spell_id = spell_id,
            dx = dx,
            dy = dy,
        },
        cost = 10,
    }
end

-- Source: evoke.cc:zap_wand. Charge loss and Evocations practice occur only
-- after a successful effect. The item disappears when its last charge fires.
function wands.resolve(ctx, player, chosen, aut)
    local entity = chosen.item_id
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= player or
        item.charges <= 0 then
        error("prepared wand is no longer carried or charged")
    end

    local spell_id = wands.spell(item.kind_id)

    if spell_id ~= chosen.spell_id then
        error("prepared wand spell changed")
    end

    local spell = catalog.get("spells", spell_id)
    local effect = effects.get(spell_id)
    local cost = wands.mp_cost(ctx, player)
    local strength = wands.power(ctx, player, cost)

    resources.pay(ctx, player, cost)

    local outcome = effect.resolve(ctx, player, chosen, spell, strength, aut)

    if outcome == "abort" or outcome == "fail" then
        resources.refund(ctx, player, cost)

        if outcome == "fail" then
            ctx:emit("evoke", "Nothing happens.")
        end

        return outcome
    end

    identification.reveal_type(ctx, player, entity)

    item.charges = item.charges - 1

    if item.charges == 0 then
        ctx:destroy(entity)
        ctx:emit("evoke", "The now-empty wand crumbles to dust.")
    else
        ctx:set(entity, "core.item", item)
    end

    ctx:signal("practice", skill_ids.SK_EVOCATIONS)

    return "success"
end

return wands
