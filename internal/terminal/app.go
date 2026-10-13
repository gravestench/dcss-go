package terminal

import (
	"fmt"
	"os"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
)

type ScreenID uint8

const (
	ScreenStartup ScreenID = iota
	ScreenSpecies
	ScreenBackground
	ScreenWeapon
	ScreenName
	ScreenPlay
	ScreenInventory
	ScreenSkills
	ScreenHelp
	ScreenConfirm
	ScreenDeath
)

// AppModel owns terminal navigation; the Game owns every turn-changing state.
type AppModel struct {
	catalog                    content.Catalog
	presentation               content.PresentationArtifact
	seed                       uint64
	savePath                   string
	game                       *game.Game
	screen                     ScreenID
	previous                   ScreenID
	weaponReturn               ScreenID
	width, height              int
	name                       string
	speciesID, jobID, weaponID string
	options                    []character.WeaponOption
	focus                      int
	notice                     string
}

func NewAppModel(catalog content.Catalog, seed uint64, savePath string) (*AppModel, error) {
	if err := catalog.Validate(); err != nil {
		return nil, err
	}
	if len(catalog.Presentation().SpeciesGroups) != 3 {
		return nil, fmt.Errorf("catalog lacks console presentation")
	}
	return &AppModel{catalog: catalog, presentation: catalog.Presentation(), seed: seed, savePath: savePath, screen: ScreenStartup, width: 79, height: 24}, nil
}

func (m *AppModel) Init() tea.Cmd { return nil }

func (m *AppModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
	case tea.KeyPressMsg:
		return m, m.handleKey(msg.String())
	}
	return m, nil
}

func (m *AppModel) handleKey(key string) tea.Cmd {
	switch m.screen {
	case ScreenStartup:
		return m.handleStartupKey(key)
	case ScreenSpecies, ScreenBackground:
		m.handleCharacterChoiceKey(key)
	case ScreenWeapon:
		m.handleWeaponKey(key)
	case ScreenName:
		m.handleNameKey(key)
	case ScreenPlay:
		// Task 6 installs source play-command routing here.
	case ScreenHelp:
		if key == "esc" {
			m.screen = m.previous
		}
	}
	return nil
}

func (m *AppModel) renderCanvas() *Canvas {
	canvas := NewCanvas(m.width, m.height)
	if _, ok := ComputeLayout(m.width, m.height); !ok {
		canvas.Write(0, 0, "Your terminal window is too small; please resize to at least 79,24", LightGrey, Black)
		return canvas
	}
	switch m.screen {
	case ScreenStartup:
		m.drawStartup(canvas)
	case ScreenSpecies, ScreenBackground:
		m.drawCharacterChoice(canvas)
	case ScreenWeapon:
		m.drawWeapon(canvas)
	case ScreenName:
		m.drawName(canvas)
	case ScreenPlay:
		layout, _ := ComputeLayout(m.width, m.height)
		if m.game != nil {
			DrawPlay(canvas, layout, m.game.View(), m.notice)
		}
	case ScreenHelp:
		canvas.Write(0, 0, "Dungeon Crawl Stone Soup - Help", Yellow, Black)
		canvas.Write(0, 2, "Esc - Return", LightGrey, Black)
	}
	return canvas
}

func (m *AppModel) View() tea.View {
	view := tea.NewView(m.renderCanvas().Styled())
	view.AltScreen = true
	return view
}

func (m *AppModel) Close() error {
	if m.game != nil {
		return m.game.Close()
	}
	return nil
}

func (m *AppModel) savedRunExists() bool {
	_, err := os.Stat(m.savePath)
	return err == nil
}

func (m *AppModel) loadSavedRun() {
	snapshot, err := save.Read(m.savePath)
	if err != nil {
		m.notice = fmt.Sprintf("Load failed: %v", err)
		return
	}
	restored, err := game.Restore(snapshot, m.catalog)
	if err != nil {
		m.notice = fmt.Sprintf("Load failed: %v", err)
		return
	}
	if m.game != nil {
		_ = m.game.Close()
	}
	m.game = restored
	m.screen = ScreenPlay
	m.notice = ""
}
