package terminal

import "crawl/internal/game"

func writeClipped(canvas *Canvas, x, y, width int, value string, fg Color) {
	clippedWrite(canvas, x, y, width, value, fg, Black)
}

// DrawPlay paints the read-only view through the active screen rules.
func DrawPlay(
	canvas *Canvas,
	layout Layout,
	view game.View,
	notice string,
	policy presentationPolicy,
) {
	drawDungeon(canvas, layout.Dungeon, view, policy)
	drawPresentation(canvas, layout.HUD, runPresentation(policy,
		"presentation.hud", map[string]any{"view": hudInput(view)}))
	drawPresentation(canvas, layout.Monsters, runPresentation(policy,
		"presentation.nearby", map[string]any{"entities": entityInput(view.Entities)}))
	drawPresentation(canvas, layout.Messages, runPresentation(policy,
		"presentation.messages", map[string]any{
			"history": view.Messages,
			"notice":  notice,
			"height":  layout.Messages.H,
		}))
}
