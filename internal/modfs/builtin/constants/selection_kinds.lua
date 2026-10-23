-- Selection kinds are the Lua-to-terminal protocol for free input prompts.
-- Content labels may change, while these stable kinds keep routing intact.
local kinds = {
    ITEM = "item",
    SPELL = "spell",
    CELL = "cell",
    OFFER = "offer",
    CARD = "card",
}

return kinds
