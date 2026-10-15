package game

import (
	"strings"
	"testing"
)

func TestShieldedGoblinBlocksPlayerMelee(t *testing.T) {
	for seed := uint64(1); seed <= 20; seed++ {
		g := shieldedGoblinScenario(t, seed)
		result, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})

		g.Close()

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "blocks your") {
				return
			}
		}
	}

	t.Fatal("shielded goblin never blocked the player's melee attacks")
}
