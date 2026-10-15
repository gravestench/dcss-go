package terminal

import (
	"strings"
	"testing"

	"dcrawl-go/internal/game"
)

func conjurerModel(t *testing.T) *AppModel {
	t.Helper()

	m := pregameModel(t)
	g, err := game.NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_CONJURER",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	m.game = g
	m.screen = ScreenPlay
	t.Cleanup(func() {
		g.Close()
	})

	return m
}

func TestSpellMenusOpenFromSourceKeys(t *testing.T) {
	m := conjurerModel(t)

	cases := []struct {
		key  string
		mode string
	}{
		{
			key:  "z",
			mode: "spell_cast",
		},

		{
			key:  "Z",
			mode: "spell_force",
		},

		{
			key:  "M",
			mode: "spell_memorise",
		},
	}

	for _, tc := range cases {
		m.handleKey(tc.key)

		if m.screen != ScreenSpells || m.spellMode != tc.mode {
			t.Fatalf("%q opened screen %v mode %q", tc.key, m.screen, m.spellMode)
		}

		m.handleKey("esc")

		if m.screen != ScreenPlay {
			t.Fatalf("Esc did not close %q menu", tc.key)
		}
	}
}

func TestKnownSpellLetterStartsSpellAim(t *testing.T) {
	m := conjurerModel(t)
	m.handleKey("z")
	m.handleKey("a")

	if m.screen != ScreenAim ||
		m.aimKind != game.CommandCast ||
		m.aimSpellID != "SPELL_MAGIC_DART" {
		t.Fatalf("spell selection did not start Magic Dart aim: %+v", m)
	}
}

func TestSpellMenuRendersLuaCatalogAtMinimumSize(t *testing.T) {
	m := conjurerModel(t)
	m.handleKey("z")

	rows := strings.Join(m.renderCanvas().PlainRows(), "\n")

	if !strings.Contains(rows, "Magic Dart") ||
		!strings.Contains(rows, "Failure") {
		t.Fatalf("spell menu omitted source fields:\n%s", rows)
	}
}

func TestForceCastFromMenuSpendsTime(t *testing.T) {
	m := conjurerModel(t)
	before := m.game.View().CurrentAut

	m.handleKey("Z")
	m.handleKey("a")
	m.handleKey("enter")

	if m.screen != ScreenPlay ||
		m.game.View().CurrentAut <= before {
		t.Fatalf("force cast did not finish: screen=%v, notice=%q",
			m.screen, m.notice)
	}
}

func TestMemorisationMenuSchedulesRemainingTurns(t *testing.T) {
	m := pregameModel(t)
	g, err := game.NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_HEDGE_WIZARD",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	m.game = g
	m.screen = ScreenPlay
	m.handleKey("M")
	m.handleKey("a")

	if m.screen != ScreenPlay || m.game.View().LearningRemaining == 0 {
		t.Fatalf("memorisation was not scheduled: %v, %q", m.screen, m.notice)
	}

	m.Update(spellTick{id: m.spellTickID})

	if m.game.View().LearningRemaining != 0 {
		t.Fatal("memorisation did not complete on its scheduled tick")
	}

	for _, spell := range m.game.View().Spells {
		if spell.ID == "SPELL_SLOW" && spell.KnownSlot > 0 {
			return
		}
	}

	t.Fatal("the scheduled spell did not become known")
}
