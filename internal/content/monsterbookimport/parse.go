package monsterbookimport

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

var bookEnumLine = regexp.MustCompile(`^\s*(MST_[A-Z0-9_]+)\s*,?\s*$`)

var spellFlagLine = regexp.MustCompile(`^\s*(MON_SPELL_[A-Z0-9_]+)\s*=`)

type token struct {
	value string
	line  int
}

type bookParser struct {
	path   string
	tokens []token
	next   int
}

func parseBooks(path string, body []byte) ([]content.MonsterSpellbook, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, body)

	if err != nil {
		return nil, err
	}

	start := -1

	for index, line := range lines {
		if strings.Contains(line.Text, "mspell_list[] =") {
			start = index + 1
			break
		}
	}

	if start < 0 {
		return nil, fmt.Errorf("%s: missing monster spellbook table", path)
	}

	tokens, err := tokenize(path, lines[start:])

	if err != nil {
		return nil, err
	}

	parser := bookParser{
		path:   path,
		tokens: tokens,
	}

	if _, err := parser.take("{"); err != nil {
		return nil, err
	}

	var books []content.MonsterSpellbook

	for parser.peek() == "{" {
		book, err := parser.book()

		if err != nil {
			return nil, err
		}

		books = append(books, book)
	}

	if _, err := parser.take("}"); err != nil {
		return nil, err
	}

	if parser.next != len(parser.tokens) || len(books) == 0 {
		return nil, fmt.Errorf("%s: trailing or empty monster spellbook table", path)
	}

	return books, nil
}

func tokenize(path string, lines []sourceparse.Line) ([]token, error) {
	var tokens []token

	for _, line := range lines {
		for index := 0; index < len(line.Text); {
			char := line.Text[index]

			if char == ' ' ||
				char == '\t' ||
				char == '\r' ||
				char == '\n' ||
				char == ';' {
				index++
				continue
			}

			if strings.ContainsRune("{},|", rune(char)) {
				tokens = append(tokens, token{
					value: string(char),
					line:  line.Number,
				})

				index++
				continue
			}

			if !isWordChar(char) {
				return nil, fmt.Errorf("%s:%d: invalid spellbook character %q", path, line.Number, char)
			}

			end := index + 1

			for end < len(line.Text) && isWordChar(line.Text[end]) {
				end++
			}

			tokens = append(tokens, token{
				value: line.Text[index:end],
				line:  line.Number,
			})

			index = end
		}
	}

	return tokens, nil
}

func isWordChar(char byte) bool {
	return (char >= 'A' && char <= 'Z') ||
		(char >= 'a' && char <= 'z') ||
		(char >= '0' && char <= '9') ||
		char == '_'
}

func (p *bookParser) peek() string {
	if p.next >= len(p.tokens) {
		return ""
	}

	return p.tokens[p.next].value
}

func (p *bookParser) take(want string) (token, error) {
	if p.next >= len(p.tokens) {
		return token{}, fmt.Errorf("%s: expected %s at end of table", p.path, want)
	}

	current := p.tokens[p.next]

	if want != "" && current.value != want {
		return token{}, fmt.Errorf("%s:%d: expected %s, got %s",
			p.path, current.line, want, current.value)
	}

	p.next++

	return current, nil
}

func (p *bookParser) optionalComma() {
	if p.peek() == "," {
		p.next++
	}
}

func (p *bookParser) book() (content.MonsterSpellbook, error) {
	start, err := p.take("{")

	if err != nil {
		return content.MonsterSpellbook{}, err
	}

	id, err := p.take("")

	if err != nil {
		return content.MonsterSpellbook{}, err
	}

	if !strings.HasPrefix(id.value, "MST_") {
		return content.MonsterSpellbook{}, fmt.Errorf("%s:%d: invalid book ID %q", p.path, start.line, id.value)
	}

	if _, err := p.take(","); err != nil {
		return content.MonsterSpellbook{}, err
	}

	if _, err := p.take("{"); err != nil {
		return content.MonsterSpellbook{}, err
	}

	book := content.MonsterSpellbook{
		ID:         id.value,
		SourceLine: start.line,
	}

	grouped := p.peek() == "{" &&
		p.next+1 < len(p.tokens) &&
		p.tokens[p.next+1].value == "{"

	if grouped {
		p.next++
	}

	for p.peek() == "{" {
		slot, err := p.slot()

		if err != nil {
			return content.MonsterSpellbook{}, err
		}

		book.Slots = append(book.Slots, slot)
	}

	if grouped {
		if _, err := p.take("}"); err != nil {
			return content.MonsterSpellbook{}, err
		}
	}

	if _, err := p.take("}"); err != nil {
		return content.MonsterSpellbook{}, err
	}

	if _, err := p.take("}"); err != nil {
		return content.MonsterSpellbook{}, err
	}

	p.optionalComma()

	return book, nil
}

func (p *bookParser) slot() (content.MonsterSpellSlot, error) {
	start, err := p.take("{")

	if err != nil {
		return content.MonsterSpellSlot{}, err
	}

	id, err := p.take("")

	if err != nil {
		return content.MonsterSpellSlot{}, err
	}

	if !strings.HasPrefix(id.value, "SPELL_") {
		return content.MonsterSpellSlot{}, fmt.Errorf("%s:%d: invalid spell ID %q", p.path, start.line, id.value)
	}

	if _, err := p.take(","); err != nil {
		return content.MonsterSpellSlot{}, err
	}

	frequency, err := p.take("")

	if err != nil {
		return content.MonsterSpellSlot{}, err
	}

	count, err := strconv.Atoi(frequency.value)

	if err != nil {
		return content.MonsterSpellSlot{}, fmt.Errorf("%s:%d: invalid frequency %q",
			p.path, frequency.line, frequency.value)
	}

	if count < 1 || count > 200 {
		return content.MonsterSpellSlot{}, fmt.Errorf("%s:%d: invalid frequency %q",
			p.path, frequency.line, frequency.value)
	}

	if _, err := p.take(","); err != nil {
		return content.MonsterSpellSlot{}, err
	}

	slot := content.MonsterSpellSlot{
		SpellID:    id.value,
		SourceLine: start.line,
		Frequency:  count,
	}

	for {
		flag, err := p.take("")

		if err != nil {
			return content.MonsterSpellSlot{}, err
		}

		if !strings.HasPrefix(flag.value, "MON_SPELL_") {
			return content.MonsterSpellSlot{}, fmt.Errorf("%s:%d: invalid spell flag %q",
				p.path, start.line, flag.value)
		}

		slot.Flags = append(slot.Flags, flag.value)

		if p.peek() != "|" {
			break
		}

		p.next++
	}

	if _, err := p.take("}"); err != nil {
		return content.MonsterSpellSlot{}, err
	}

	p.optionalComma()

	return slot, nil
}

func parseBookEnum(path string, body []byte) ([]string, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, body)

	if err != nil {
		return nil, err
	}

	inside := false
	closed := false
	sawCount := false
	var ids []string

	for _, line := range lines {
		value := strings.TrimSpace(line.Text)

		if !inside {
			inside = value == "enum mon_spellbook_type"
			continue
		}

		if value == "{" {
			continue
		}

		if value == "};" {
			closed = true
			break
		}

		if value == "NUM_MSTYPES," {
			sawCount = true
			continue
		}

		match := bookEnumLine.FindStringSubmatch(value)

		if match != nil {
			ids = append(ids, match[1])
		} else if value != "" {
			return nil, fmt.Errorf("%s:%d: malformed monster book enum %q", path, line.Number, value)
		}
	}

	if !closed ||
		!sawCount ||
		len(ids) < 3 ||
		ids[len(ids)-2] != "MST_GHOST" ||
		ids[len(ids)-1] != "MST_NO_SPELLS" {
		return nil, fmt.Errorf("%s: incomplete monster spellbook enum", path)
	}

	return ids[:len(ids)-2], nil
}

func parseFlagVocabulary(path string, body []byte) (map[string]bool, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, body)

	if err != nil {
		return nil, err
	}

	inside := false
	closed := false
	flags := map[string]bool{}

	for _, line := range lines {
		value := strings.TrimSpace(line.Text)

		if !inside {
			inside = value == "enum mon_spell_slot_flag"
			continue
		}

		if value == "};" {
			closed = true
			break
		}

		if match := spellFlagLine.FindStringSubmatch(value); match != nil {
			flags[match[1]] = true
		}
	}

	if !closed ||
		!flags["MON_SPELL_NATURAL"] ||
		!flags["MON_SPELL_WIZARD"] {
		return nil, fmt.Errorf("%s: incomplete monster spell flag vocabulary", path)
	}

	return flags, nil
}

func reconcile(books []content.MonsterSpellbook, ids []string, flags map[string]bool) error {
	if len(books) != len(ids) {
		return fmt.Errorf("monster spellbooks: %d rows for %d enum IDs", len(books), len(ids))
	}

	seen := map[string]bool{}

	for index, book := range books {
		if book.ID != ids[index] || seen[book.ID] {
			return fmt.Errorf("monster spellbook %d mismatches enum: %s", index, book.ID)
		}

		seen[book.ID] = true

		for _, slot := range book.Slots {
			for _, flag := range slot.Flags {
				if !flags[flag] {
					return fmt.Errorf("monster spellbook %s has unknown flag %s", book.ID, flag)
				}
			}
		}
	}

	return nil
}
