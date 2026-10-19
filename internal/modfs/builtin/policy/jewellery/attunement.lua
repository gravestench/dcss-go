local capabilities = require("constants.jewellery_capabilities")
local component = require("constants.component")
local jewellery = require("policy.inventory.jewellery")
local items = require("policy.inventory.items")
local mutation_capabilities = require("constants.mutation_capabilities")
local mutation_effects = require("policy.mutations.effects.registry")

local attunement = {}

-- Regeneration jewellery attunes to the resource its effect restores.
local function resource_id(definition)
    local effects = definition.jewellery and
        definition.jewellery.effects or {}

    if effects[capabilities.HP_REGEN] then
        return component.HEALTH
    end

    if effects[capabilities.MP_REGEN] then
        return component.MAGIC
    end

    return nil
end

-- Mutation restrictions can block regeneration even when the resource exists.
local function resource_available(ctx, player, id, resource)
    if id == component.HEALTH then
        return mutation_effects.sum(ctx, player,
            mutation_capabilities.HP_REGEN_FORBIDDEN) == 0
    end

    return resource.max > 0 and mutation_effects.sum(ctx, player,
        mutation_capabilities.HP_CASTING) == 0
end

-- Attunement starts active only if its resource is both usable and full.
local function resource_full(ctx, player, id)
    local resource = ctx:get(player, id)

    if not resource then
        error("jewellery attunement requires player " .. id)
    end

    return resource_available(ctx, player, id, resource) and
        resource.current >= resource.max
end

-- Equipping and removing jewellery refreshes attunement against the current resource capacity.
-- Example: attunement.on_equip(ctx, player, ring) initializes the ring's attunement resource.
function attunement.on_equip(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)
    local definition = items.kind(item)
    local id = resource_id(definition)

    if not id then
        return
    end

    ctx:add(entity, component.JEWELLERY_ATTUNEMENT, {
        active = resource_full(ctx, player, id),
    })
end

-- Remove the item's attunement marker so re-equipping starts from current resources.
function attunement.on_remove(ctx, entity)
    if ctx:has(entity, component.JEWELLERY_ATTUNEMENT) then
        ctx:remove(entity, component.JEWELLERY_ATTUNEMENT)
    end
end

-- A worn item activates at full resource and deactivates if regeneration becomes forbidden.
function attunement.refresh(ctx, player)
    for _, entry in pairs(jewellery.worn(ctx, player)) do
        local id = resource_id(entry.definition)
        local state = id and ctx:get(entry.entity,
            component.JEWELLERY_ATTUNEMENT)

        if id and not state then
            error("worn regeneration jewellery lacks attunement")
        end

        if state then
            local resource = ctx:get(player, id)
            local available = resource_available(ctx, player, id, resource)
            local ready = available and resource.current >= resource.max

            if state.active and not available then
                state.active = false
                ctx:set(entry.entity, component.JEWELLERY_ATTUNEMENT, state)
            elseif not state.active and ready then
                state.active = true
                ctx:set(entry.entity,
                    component.JEWELLERY_ATTUNEMENT, state)
                ctx:emit("jewellery", "Your jewellery attunes to you.")
            end
        end
    end
end

return attunement
