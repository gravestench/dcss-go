-- Source uncancelled prompts resume from these saved action phases.
-- A phase is separate from the operation so target prompts can be shared.
local phases = {
    NONE = "",
    CHOOSE_DECK = "choose_deck",
    CHOOSE_CARD = "choose_card",
    RESOLVE_CARD = "resolve_card",
    FAILED = "failed",
    READY = "ready",
    REPLACE_STACK = "replace_stack",
    SHORT_STACK = "short_stack",
    SHORT_TRIPLE = "short_triple",
    DRAW_STACK = "draw_stack",
    ORDER_STACK = "order_stack",
    TARGET_CARD = "target_card",
    CONFIRM_FRIENDLY = "confirm_friendly",
    CONFIRM_WASTE = "confirm_waste",
}

return phases
