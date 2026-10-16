-- Source: item-use.cc:SCR_ACQUIREMENT and acquire.cc:acquirement_menu.
local component = require("constants.component")
local identification = require("policy.items.identification")
local item_ids = require("ids.items")
local offers = require("policy.scrolls.acquirement_offers")
local scrolls = require("policy.scrolls")

local effect = {}

local function saved_offers(ctx, player, scroll)
    local state = ctx:get(scroll, component.SCROLL_ACQUIREMENT)

    if state then
        return state
    end

    state = offers.generate(ctx, player, scroll)
    ctx:add(scroll, component.SCROLL_ACQUIREMENT, state)

    return state
end

function effect.prepare(ctx, player, request)
    -- DCSS identifies acquirement before opening its cancellable menu.
    identification.reveal_type(ctx, player, request.scroll)

    if request.cancelled then
        return {
            message = "Okay.",
        }
    end

    local state = saved_offers(ctx, player, request.scroll)
    local options = offers.options(ctx, player, state)

    if request.target_id == "" then
        return {
            selection = {
                kind = "offer",
                title = "Choose an item to acquire.",
                options = options,
            },
        }
    end

    for _, option in ipairs(options) do
        if option.id == request.target_id then
            return nil
        end
    end

    return {
        message = "That choice is no longer available.",
    }
end

function effect.apply(ctx, player, request)
    local state = ctx:get(request.scroll, component.SCROLL_ACQUIREMENT)
    local index = tonumber(request.target_id)

    if not state or not index or index < 1 or
        index > #state.offer_ids then
        error("acquirement has no selected offer")
    end

    offers.grant(ctx, player, state, index)
    ctx:remove(request.scroll, component.SCROLL_ACQUIREMENT)
    ctx:emit("read", "Something appears at your feet!")
end

scrolls.register(item_ids.SCR_ACQUIREMENT, effect)

return effect
