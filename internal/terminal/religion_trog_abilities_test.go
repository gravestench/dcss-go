package terminal

import (
	"strings"
	"testing"

	"crawl/internal/game"
)

// The ordinary ability screen discovers Trog's Lua registrations from
// the starting Berserker's saved piety, with no terminal god keymap.
func TestTrogAbilityMenuUsesLivePiety(t *testing.T) {
	m := pregameModel(t)
	g, err := game.NewDungeonGame(1, "SP_HUMAN", "JOB_BERSERKER",
		"WPN_HAND_AXE", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	m.game = g
	m.screen = ScreenPlay
	m.handleKey("a")

	first := plainApp(m)

	if m.screen != ScreenAbilities ||
		!strings.Contains(first, "Berserk") ||
		strings.Contains(first, "Brothers in Arms") {
		t.Fatalf("one-star Trog menu is wrong:\n%s", first)
	}

}
