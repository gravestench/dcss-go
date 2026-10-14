package terminal

import "dcrawl-go/internal/game"

func CommandForKey(key string) (game.Command, bool) {
	switch key {
	case "h", "left":
		return game.Command{
			Kind: game.CommandMove,
			DX:   -1,
		}, true

	case "j", "down":
		return game.Command{
			Kind: game.CommandMove,
			DY:   1,
		}, true

	case "k", "up":
		return game.Command{
			Kind: game.CommandMove,
			DY:   -1,
		}, true

	case "l", "right":
		return game.Command{
			Kind: game.CommandMove,
			DX:   1,
		}, true

	case "y", "home":
		return game.Command{
			Kind: game.CommandMove,
			DX:   -1,
			DY:   -1,
		}, true

	case "u", "pgup":
		return game.Command{
			Kind: game.CommandMove,
			DX:   1,
			DY:   -1,
		}, true

	case "b", "end":
		return game.Command{
			Kind: game.CommandMove,
			DX:   -1,
			DY:   1,
		}, true

	case "n", "pgdown":
		return game.Command{
			Kind: game.CommandMove,
			DX:   1,
			DY:   1,
		}, true

	case ".", "s":
		return game.Command{Kind: game.CommandWait}, true

	case "g", ",":
		return game.Command{Kind: game.CommandPickup}, true

	case "<":
		return game.Command{Kind: game.CommandUpstairs}, true

	case ">":
		return game.Command{Kind: game.CommandDownstairs}, true
	}

	return game.Command{}, false
}
