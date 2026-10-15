package game

import (
	"strings"
	"testing"
)

func TestPlayerConfusionBlocksCastingAndExpiresAfterWait(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_MAGIC_DART")

	_, err := g.scripts.Components()["zap.player_confusion"].Set(
		g.player,
		map[string]any{
			"remaining_aut": int64(20),
		},
	)
	if err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_MAGIC_DART",
		DX:      1,
	})
	if err != nil {
		t.Fatal(err)
	}
	confusedMessage := false
	for _, event := range result.Events {
		confusedMessage = confusedMessage ||
			strings.Contains(event.Text, "confused")
	}
	if result.Spent != 0 || !confusedMessage {
		t.Fatalf("confused cast = %+v, want no-time rejection", result)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
	state, ok := g.scripts.Components()["zap.player_confusion"].Get(g.player)
	if !ok {
		t.Fatal("confusion expired too early")
	}
	remaining, err := state.Get("remaining_aut")
	if err != nil {
		t.Fatal(err)
	}
	if remaining != int64(10) {
		t.Fatalf("confusion after one wait = %v, %v", state, ok)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
	if g.scripts.Components()["zap.player_confusion"].Has(g.player) {
		t.Fatal("confusion remained after its duration")
	}
}
