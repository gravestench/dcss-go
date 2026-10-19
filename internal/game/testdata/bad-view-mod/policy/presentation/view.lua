-- An empty presentation.player result probes validation of required view fields.

register.policy({
    id = "presentation.player",
    -- Return an empty view on purpose: the Go presentation boundary should
    -- reject missing required fields instead of rendering a partial screen.
    -- Example: runtime.Policy("presentation.player", nil) returns {} here.
    run = function()
        return {}
    end,
})
