package monsterweaponimport

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

var declaration = regexp.MustCompile(
	`static\s+const\s+(weapon_list|mon_weapon_spec|vector<pair<brand_type,\s*int>>|` +
		`map<monster_type,\s*mon_weapon_spec>)\s+([A-Za-z0-9_]+)\s*=`,
)

type token struct {
	value string
	line  int
}

type node struct {
	atom     string
	children []node
	line     int
	list     bool
}

type initializerParser struct {
	path   string
	tokens []token
	next   int
}

type namedInitializer struct {
	kind string
	root node
}

func parseSource(path string, data []byte) (
	[]content.MonsterWeaponSpec,
	[]content.MonsterWeaponSpec,
	error,
) {
	lines, err := sourceparse.Tag34NumberedLines(path, data)

	if err != nil {
		return nil, nil, err
	}

	start := -1
	end := -1

	for index, line := range lines {
		if strings.Contains(line.Text, "int make_mons_weapon(") {
			start = index
		}

		if start >= 0 && strings.Contains(line.Text, "bool force_item = false;") {
			end = index
			break
		}
	}

	if start < 0 || end <= start {
		return nil, nil, fmt.Errorf("%s: missing monster weapon tables", path)
	}

	region := lines[start:end]
	text := make([]string, len(region))

	for index, line := range region {
		text[index] = line.Text
	}

	joined := strings.Join(text, "\n")
	named := make(map[string]namedInitializer)
	var primary []content.MonsterWeaponSpec
	var secondary []content.MonsterWeaponSpec

	for _, match := range declaration.FindAllStringSubmatchIndex(joined, -1) {
		kind := joined[match[2]:match[3]]
		name := joined[match[4]:match[5]]
		initial := match[1]
		root, err := readInitializer(path, joined, region[0].Number, initial)

		if err != nil {
			return nil, nil, err
		}

		if kind != "map<monster_type, mon_weapon_spec>" {
			if _, duplicate := named[name]; duplicate {
				return nil, nil, fmt.Errorf("%s: duplicate weapon alias %s", path, name)
			}

			named[name] = namedInitializer{
				kind: kind,
				root: root,
			}

			continue
		}

		specs, err := parseTable(path, root, named)

		if err != nil {
			return nil, nil, err
		}

		switch name {
		case "primary_weapon_specs":
			primary = specs

		case "secondary_weapon_specs":
			secondary = specs

		default:
			return nil, nil, fmt.Errorf("%s: unknown monster weapon table %s", path, name)
		}
	}

	if len(primary) == 0 || len(secondary) == 0 {
		return nil, nil, fmt.Errorf("%s: incomplete monster weapon tables", path)
	}

	return primary, secondary, nil
}

func readInitializer(path, text string, startLine, start int) (node, error) {
	for start < len(text) &&
		(text[start] == ' ' ||
			text[start] == '\n' ||
			text[start] == '\t') {
		start++
	}

	if start >= len(text) {
		return node{}, fmt.Errorf("%s: missing initializer", path)
	}

	depth := 0
	end := start

	if text[start] == '{' {
		for ; end < len(text); end++ {
			if text[end] == '{' {
				depth++
			} else if text[end] == '}' {
				depth--

				if depth == 0 {
					end++
					break
				}
			}
		}
	} else {
		for ; end < len(text) && isAtomByte(text[end]); end++ {
		}
	}

	if depth != 0 || end == start {
		return node{}, fmt.Errorf("%s: unfinished monster weapon initializer", path)
	}

	tail := end

	for tail < len(text) &&
		(text[tail] == ' ' ||
			text[tail] == '\n' ||
			text[tail] == '\t') {
		tail++
	}

	if tail >= len(text) || text[tail] != ';' {
		return node{}, fmt.Errorf("%s: unsupported monster weapon declaration tail", path)
	}

	line := startLine + strings.Count(text[:start], "\n")
	tokens, err := lex(path, text[start:end], line)

	if err != nil {
		return node{}, err
	}

	parser := initializerParser{
		path:   path,
		tokens: tokens,
	}

	root, err := parser.value()

	if err != nil {
		return node{}, err
	}

	if parser.next != len(tokens) {
		return node{}, fmt.Errorf("%s:%d: trailing initializer tokens", path, line)
	}

	return root, nil
}

func lex(path, text string, line int) ([]token, error) {
	var tokens []token

	for index := 0; index < len(text); {
		char := text[index]

		if char == '\n' {
			line++
			index++
			continue
		}

		if char == ' ' ||
			char == '\t' ||
			char == '\r' {
			index++
			continue
		}

		if char == '{' ||
			char == '}' ||
			char == ',' {
			tokens = append(tokens, token{
				value: string(char),
				line:  line,
			})

			index++
			continue
		}

		if !isAtomByte(char) {
			return nil, fmt.Errorf("%s:%d: unsupported weapon initializer byte %q", path, line, char)
		}

		end := index + 1

		for end < len(text) && isAtomByte(text[end]) {
			end++
		}

		tokens = append(tokens, token{
			value: text[index:end],
			line:  line,
		})

		index = end
	}

	return tokens, nil
}

func isAtomByte(char byte) bool {
	return (char >= 'A' && char <= 'Z') ||
		(char >= 'a' && char <= 'z') ||
		(char >= '0' && char <= '9') ||
		char == '_' || char == '-'
}

func (p *initializerParser) value() (node, error) {
	if p.next >= len(p.tokens) {
		return node{}, fmt.Errorf("%s: incomplete initializer", p.path)
	}

	current := p.tokens[p.next]
	p.next++

	if current.value != "{" {
		if current.value == "}" || current.value == "," {
			return node{}, fmt.Errorf("%s:%d: unexpected %s", p.path, current.line, current.value)
		}

		return node{
			atom: current.value,
			line: current.line,
		}, nil
	}

	result := node{
		line: current.line,
		list: true,
	}

	for p.next < len(p.tokens) && p.tokens[p.next].value != "}" {
		if p.tokens[p.next].value == "," {
			return node{}, fmt.Errorf("%s:%d: unexpected comma", p.path, p.tokens[p.next].line)
		}

		child, err := p.value()

		if err != nil {
			return node{}, err
		}

		result.children = append(result.children, child)

		if p.next < len(p.tokens) && p.tokens[p.next].value == "," {
			p.next++
			continue
		}

		if p.next < len(p.tokens) && p.tokens[p.next].value != "}" {
			return node{}, fmt.Errorf("%s:%d: expected comma", p.path, child.line)
		}
	}

	if p.next >= len(p.tokens) {
		return node{}, fmt.Errorf("%s:%d: missing closing brace", p.path, current.line)
	}

	p.next++

	return result, nil
}

func parseTable(
	path string,
	root node,
	named map[string]namedInitializer,
) ([]content.MonsterWeaponSpec, error) {
	if !root.list {
		return nil, fmt.Errorf("%s:%d: weapon table is not a list", path, root.line)
	}

	specs := make([]content.MonsterWeaponSpec, 0, len(root.children))

	for _, entry := range root.children {
		if !entry.list || len(entry.children) != 2 {
			return nil, fmt.Errorf("%s:%d: malformed weapon table entry", path, entry.line)
		}

		monsterID := entry.children[0].atom
		spec, err := parseSpec(path, entry.children[1], named)

		if err != nil {
			return nil, err
		}

		spec.MonsterID = monsterID
		spec.SourceLine = entry.line
		specs = append(specs, spec)
	}

	return specs, nil
}

func parseSpec(
	path string,
	root node,
	named map[string]namedInitializer,
) (content.MonsterWeaponSpec, error) {
	resolved, err := resolve(path, root, named, "mon_weapon_spec")

	if err != nil {
		return content.MonsterWeaponSpec{}, err
	}

	if !resolved.list ||
		len(resolved.children) < 1 ||
		len(resolved.children) > 4 {
		return content.MonsterWeaponSpec{}, fmt.Errorf("%s:%d: invalid weapon spec", path, root.line)
	}

	weapons, origin, err := parseChoices(path, resolved.children[0], named, "weapon_list")

	if err != nil {
		return content.MonsterWeaponSpec{}, err
	}

	spec := content.MonsterWeaponSpec{
		SpecLine:       resolved.line,
		WeaponListLine: origin,
		Weapons:        weapons,
	}

	if len(resolved.children) > 1 {
		spec.Plus, err = parsePlus(path, resolved.children[1])

		if err != nil {
			return content.MonsterWeaponSpec{}, err
		}
	}

	if len(resolved.children) > 2 {
		spec.Brands, spec.BrandListLine, err = parseChoices(
			path,
			resolved.children[2],
			named,
			"vector<pair<brand_type, int>>",
		)

		if err != nil {
			return content.MonsterWeaponSpec{}, err
		}
	}

	if len(resolved.children) > 3 {
		spec.GoodChance, err = positiveInteger(path, resolved.children[3], true)

		if err != nil {
			return content.MonsterWeaponSpec{}, err
		}
	}

	return spec, nil
}

func resolve(
	path string,
	value node,
	named map[string]namedInitializer,
	want string,
) (node, error) {
	if value.list {
		return value, nil
	}

	alias, found := named[value.atom]

	if !found || alias.kind != want {
		return node{}, fmt.Errorf("%s:%d: unknown %s alias %s", path, value.line, want, value.atom)
	}

	return alias.root, nil
}

func parseChoices(
	path string,
	value node,
	named map[string]namedInitializer,
	want string,
) ([]content.WeightedWeaponChoice, int, error) {
	resolved, err := resolve(path, value, named, want)

	if err != nil {
		return nil, 0, err
	}

	if !resolved.list {
		return nil, 0, fmt.Errorf("%s:%d: expected weighted list", path, value.line)
	}

	choices := make([]content.WeightedWeaponChoice, 0, len(resolved.children))

	for _, pair := range resolved.children {
		if !pair.list || len(pair.children) != 2 {
			return nil, 0, fmt.Errorf("%s:%d: malformed weighted choice", path, pair.line)
		}

		weight, err := positiveInteger(path, pair.children[1], false)

		if err != nil {
			return nil, 0, err
		}

		choices = append(choices, content.WeightedWeaponChoice{
			ID:     pair.children[0].atom,
			Weight: weight,
		})
	}

	return choices, resolved.line, nil
}

func parsePlus(path string, value node) (content.MonsterWeaponPlus, error) {
	if !value.list || len(value.children) > 4 {
		return content.MonsterWeaponPlus{}, fmt.Errorf("%s:%d: invalid plus range", path, value.line)
	}

	if len(value.children) == 0 {
		return content.MonsterWeaponPlus{}, nil
	}

	if len(value.children) < 3 {
		return content.MonsterWeaponPlus{}, fmt.Errorf("%s:%d: incomplete plus range", path, value.line)
	}

	values := make([]int, len(value.children))

	for index, child := range value.children {
		parsed, err := strconv.Atoi(child.atom)

		if err != nil {
			return content.MonsterWeaponPlus{}, fmt.Errorf("%s:%d: invalid plus value", path, child.line)
		}

		values[index] = parsed
	}

	plus := content.MonsterWeaponPlus{
		Odds: values[0],
		Min:  values[1],
		Max:  values[2],
	}

	if len(values) == 4 {
		plus.Rolls = values[3]
	}

	if plus.Odds <= 0 ||
		plus.Min > plus.Max ||
		plus.Rolls < 0 {
		return content.MonsterWeaponPlus{}, fmt.Errorf("%s:%d: invalid plus range", path, value.line)
	}

	return plus, nil
}

func positiveInteger(path string, value node, allowZero bool) (int, error) {
	result, err := strconv.Atoi(value.atom)

	if err != nil ||
		result < 0 ||
		(!allowZero && result == 0) {
		return 0, fmt.Errorf("%s:%d: invalid integer %q", path, value.line, value.atom)
	}

	return result, nil
}
