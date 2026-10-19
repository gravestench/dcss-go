-- An entity target tracks a live actor; a cell target remains valid even when empty.

-- A spell plan targets a live entity or a cell that may be empty.
local kind = {
    ENTITY = "entity",
    CELL = "cell",
}

return kind
