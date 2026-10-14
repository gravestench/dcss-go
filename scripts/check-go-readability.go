package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type localTypes struct {
	structs       map[string]bool
	structKeyMaps map[string]bool
}

var typesByDir = map[string]localTypes{}

func main() {
	issues := 0

	for _, root := range []string{
		"cmd",
		"internal",
		"scripts",
	} {
		err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
			if walkErr != nil {
				return walkErr
			}

			if entry.IsDir() || !strings.HasSuffix(path, ".go") {
				return nil
			}

			found, err := checkFile(path)
			issues += found

			return err
		})

		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}

	if issues > 0 {
		os.Exit(1)
	}
}

func checkFile(path string) (int, error) {
	source, err := os.ReadFile(path)

	if err != nil {
		return 0, err
	}

	types, err := declaredTypes(filepath.Dir(path))

	if err != nil {
		return 0, err
	}

	lines := strings.Split(string(source), "\n")
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, path, source, parser.ParseComments)

	if err != nil {
		return 0, err
	}

	importedTypes := make(map[string]localTypes)

	for _, imported := range file.Imports {
		importPath, err := strconv.Unquote(imported.Path.Value)

		if err != nil ||
			!strings.HasPrefix(importPath, "dcrawl-go/") {
			continue
		}

		alias := filepath.Base(importPath)

		if imported.Name != nil {
			alias = imported.Name.Name
		}

		root, err := moduleRoot()

		if err != nil {
			return 0, err
		}

		importDir := filepath.Join(root, strings.TrimPrefix(importPath, "dcrawl-go/"))
		importedTypes[alias], err = declaredTypes(importDir)

		if err != nil {
			return 0, err
		}
	}

	issues := 0

	report := func(pos token.Pos, message string) {
		fmt.Printf("%s: %s\n", fset.Position(pos), message)
		issues++
	}

	multilineValueEndsAt := func(statement ast.Stmt, line int) bool {
		found := false

		ast.Inspect(statement, func(node ast.Node) bool {
			switch value := node.(type) {
			case *ast.BasicLit:
				if value.Kind == token.STRING &&
					fset.Position(value.End()-1).Line == line &&
					fset.Position(value.Pos()).Line < line {
					found = true
				}

			case *ast.CompositeLit:
				if fset.Position(value.Rbrace).Line == line &&
					fset.Position(value.Lbrace).Line < line {
					found = true
				}

			case *ast.FuncLit:
				if fset.Position(value.Body.Rbrace).Line == line &&
					fset.Position(value.Body.Lbrace).Line < line {
					found = true
				}
			}

			return true
		})

		return found
	}

	checkStatements := func(statements []ast.Stmt) {
		for index := 1; index < len(statements); index++ {
			previous := statements[index-1]
			next := statements[index]
			previousEndLine := fset.Position(previous.End() - 1).Line
			nextStartLine := fset.Position(next.Pos()).Line

			if previousEndLine == nextStartLine {
				report(next.Pos(), "put each statement on its own line")

				continue
			}

			adjacent := previousEndLine+1 == nextStartLine
			_, returns := next.(*ast.ReturnStmt)

			if isControl(next) &&
				!isControl(previous) &&
				adjacent {
				report(next.Pos(), "leave a blank line before the control block")
			}

			if returns &&
				!isControl(previous) &&
				adjacent {
				report(next.Pos(), "leave a blank line before the return")
			}

			if isControl(previous) && adjacent {
				report(next.Pos(), "leave a blank line after the control block")
			}

			if !isControl(previous) &&
				!isControl(next) &&
				!returns &&
				adjacent &&
				multilineValueEndsAt(previous, previousEndLine) {
				report(next.Pos(), "leave a blank line after the multiline value")
			}
		}
	}

	checkClauses := func(clauses []ast.Stmt) {
		for index := 1; index < len(clauses); index++ {
			previous := clauses[index-1]
			next := clauses[index]

			if fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
				report(next.Pos(), "leave a blank line between switch or select cases")
			}
		}
	}

	blockEndLines := make(map[int]bool)
	booleanOperatorsByLine := make(map[int]map[token.Token]int)
	reportedBooleanLines := make(map[int]bool)
	checkErrorCondition := func(condition ast.Expr) {

		ast.Inspect(condition, func(part ast.Node) bool {
			if _, nestedFunction := part.(*ast.FuncLit); nestedFunction {
				return false
			}

			binary, ok := part.(*ast.BinaryExpr)

			if !ok ||
				(binary.Op != token.LAND && binary.Op != token.LOR) {
				return true
			}

			line := fset.Position(binary.OpPos).Line

			if reportedBooleanLines[line] {
				return true
			}

			left := adjacentLogicalOperand(binary.X, true)
			right := adjacentLogicalOperand(binary.Y, false)
			leftHasError := sameLine(fset, binary.X.End()-1, binary.OpPos) &&
				expressionHasError(left)

			if sameLine(fset, binary.OpPos, binary.Y.Pos()) &&
				(leftHasError || expressionHasError(right)) {
				report(binary.OpPos, "put error checks on their own condition line")
				reportedBooleanLines[line] = true
			}

			return true
		})
	}

	for index := 1; index < len(file.Decls); index++ {
		previous := file.Decls[index-1]
		next := file.Decls[index]

		if fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
			report(next.Pos(), "leave a blank line between top-level declarations")
		}
	}

	ast.Inspect(file, func(node ast.Node) bool {
		switch value := node.(type) {
		case *ast.IfStmt:
			checkErrorCondition(value.Cond)

		case *ast.ForStmt:
			if value.Cond != nil {
				checkErrorCondition(value.Cond)
			}

		case *ast.BinaryExpr:
			if value.Op != token.LAND && value.Op != token.LOR {
				break
			}

			line := fset.Position(value.OpPos).Line

			if booleanOperatorsByLine[line] == nil {
				booleanOperatorsByLine[line] = make(map[token.Token]int)
			}

			booleanOperatorsByLine[line][value.Op]++

			if reportedBooleanLines[line] {
				break
			}

			mixedWithoutGrouping := false

			for _, operand := range []ast.Expr{value.X, value.Y} {
				nested, ok := operand.(*ast.BinaryExpr)

				if ok &&
					(nested.Op == token.LAND || nested.Op == token.LOR) &&
					nested.Op != value.Op &&
					sameLine(fset, nested.OpPos, value.OpPos) {
					mixedWithoutGrouping = true
				}
			}

			if booleanOperatorsByLine[line][value.Op] == 2 ||
				mixedWithoutGrouping {
				report(value.OpPos, "put crowded boolean checks on separate lines")
				reportedBooleanLines[line] = true
			} else if len(lines[line-1]) > 80 {
				report(value.OpPos, "break long boolean expression across lines")
				reportedBooleanLines[line] = true
			}

		case *ast.SwitchStmt:
			checkClauses(value.Body.List)

		case *ast.TypeSwitchStmt:
			checkClauses(value.Body.List)

		case *ast.SelectStmt:
			checkClauses(value.Body.List)

		case *ast.ValueSpec:
			if len(value.Names) > 1 {
				report(value.Pos(), "declare each named value on its own line")
			}

		case *ast.StructType:
			for _, field := range value.Fields.List {
				if len(field.Names) > 1 {
					report(field.Pos(), "declare each struct field on its own line")
				}
			}

		case *ast.AssignStmt:
			if value.Tok == token.DEFINE &&
				len(value.Lhs) >= 4 && len(value.Rhs) >= 4 {
				report(value.Pos(), "declare parser and other local state one variable per line")
			}

			if value.Tok != token.ASSIGN ||
				len(value.Lhs) < 2 || len(value.Rhs) < 2 {
				break
			}

			allFields := true

			for _, target := range value.Lhs {
				_, field := target.(*ast.SelectorExpr)
				allFields = allFields && field
			}

			if allFields || len(value.Lhs) >= 3 {
				report(value.Pos(), "assign mutable fields and unrelated values one per line")
			}

		case *ast.BlockStmt:
			blockEndLines[fset.Position(value.Rbrace).Line] = true

			if len(value.List) > 0 && sameLine(fset, value.Lbrace, value.Rbrace) {
				report(value.Lbrace, "expand this inline block")
			}

			checkStatements(value.List)

		case *ast.CaseClause:
			checkStatements(value.Body)

		case *ast.CommClause:
			checkStatements(value.Body)

		case *ast.CompositeLit:
			// An omitted type usually belongs to a nested struct value. The
			// enclosing collection checks spacing between its entries.
			if value.Type != nil &&
				!isStructLiteralType(value.Type, types, importedTypes) {
				checkMultilineEntrySpacing(fset, value, report)
			}

			checkCollectionStructValues(
				fset,
				value,
				types,
				importedTypes,
				report,
			)

			keyIsStruct := false

			switch literalType := value.Type.(type) {
			case *ast.MapType:
				keyIsStruct = isStructType(literalType.Key, types.structs)

			case *ast.Ident:
				keyIsStruct = types.structKeyMaps[literalType.Name]
			}

			if keyIsStruct {
				checkStructMapKeys(fset, value, report)
			}

			if len(value.Elts) < 2 {
				break
			}

			keyedFields := true

			for _, element := range value.Elts {
				_, keyed := element.(*ast.KeyValueExpr)
				keyedFields = keyedFields && keyed
			}

			_, named := value.Type.(*ast.Ident)
			_, qualified := value.Type.(*ast.SelectorExpr)
			_, anonymous := value.Type.(*ast.StructType)
			_, generic := value.Type.(*ast.IndexExpr)
			_, genericList := value.Type.(*ast.IndexListExpr)
			fixedArray, array := value.Type.(*ast.ArrayType)
			compactFixedArray := array &&
				fixedArray.Len != nil &&
				scalarElements(value.Elts)

			if ((len(value.Elts) >= 3 &&
				!compactFixedArray) ||
				len(value.Elts) >= 4 ||
				keyedFields ||
				named ||
				qualified ||
				anonymous ||
				generic ||
				genericList) &&
				entriesShareLine(fset, value) {
				report(value.Lbrace, "put literal entries on separate lines")
			}

			// Ten or more fields are difficult to scan as one uninterrupted block.
			if len(value.Elts) >= 10 &&
				keyedFields &&
				isStructLiteralType(value.Type, types, importedTypes) &&
				!entriesShareLine(fset, value) &&
				!literalHasGroupBreak(fset, value, lines) {
				report(value.Lbrace, "group long literal fields by concept")
			}
		}

		return true
	})

	for _, group := range file.Comments {
		line := fset.Position(group.Pos()).Line

		if blockEndLines[line-1] && strings.TrimSpace(lines[line-2]) == "}" {
			report(group.Pos(), "leave a blank line after the block before its comment")
		}
	}

	return issues, nil
}

func adjacentLogicalOperand(expression ast.Expr, rightmost bool) ast.Expr {
	for {
		switch value := expression.(type) {
		case *ast.ParenExpr:
			expression = value.X

		case *ast.BinaryExpr:
			if value.Op != token.LAND && value.Op != token.LOR {
				return expression
			}

			if rightmost {
				expression = value.Y
			} else {
				expression = value.X
			}

		default:
			return expression
		}
	}
}

func expressionHasError(expression ast.Expr) bool {
	found := false

	ast.Inspect(expression, func(node ast.Node) bool {
		identifier, ok := node.(*ast.Ident)

		if ok &&
			(identifier.Name == "err" ||
				strings.HasSuffix(identifier.Name, "Err")) {
			found = true
		}

		return true
	})

	return found
}

func checkMultilineEntrySpacing(
	fset *token.FileSet,
	collection *ast.CompositeLit,
	report func(token.Pos, string),
) {
	for index := 1; index < len(collection.Elts); index++ {
		previous := collection.Elts[index-1]
		next := collection.Elts[index]

		previousStart := fset.Position(previous.Pos()).Line
		previousEnd := fset.Position(previous.End() - 1).Line
		nextStart := fset.Position(next.Pos()).Line
		nextEnd := fset.Position(next.End() - 1).Line

		if previousEnd > previousStart &&
			nextEnd > nextStart &&
			previousEnd+1 == nextStart {
			report(next.Pos(), "leave a blank line between multiline literal entries")
		}
	}
}

func checkCollectionStructValues(
	fset *token.FileSet,
	literal *ast.CompositeLit,
	local localTypes,
	imports map[string]localTypes,
	report func(token.Pos, string),
) {
	var elementType ast.Expr

	switch collection := literal.Type.(type) {
	case *ast.ArrayType:
		elementType = collection.Elt

	case *ast.MapType:
		elementType = collection.Value
	}

	if !isStructLiteralType(elementType, local, imports) {
		return
	}

	for _, element := range literal.Elts {
		if entry, keyed := element.(*ast.KeyValueExpr); keyed {
			element = entry.Value
		}

		value, composite := element.(*ast.CompositeLit)

		if !composite ||
			value.Type != nil || len(value.Elts) < 2 {
			continue
		}

		if entriesShareLine(fset, value) {
			report(value.Lbrace, "put positional struct fields on separate lines")
		}
	}
}

func sameLine(fset *token.FileSet, left, right token.Pos) bool {
	return fset.Position(left).Line == fset.Position(right).Line
}

func checkStructMapKeys(
	fset *token.FileSet,
	literal *ast.CompositeLit,
	report func(token.Pos, string),
) {
	for _, element := range literal.Elts {
		entry, ok := element.(*ast.KeyValueExpr)

		if !ok {
			continue
		}

		key, ok := entry.Key.(*ast.CompositeLit)

		if !ok ||
			key.Type != nil || len(key.Elts) < 2 {
			continue
		}

		if entriesShareLine(fset, key) {
			report(key.Lbrace, "put multi-field struct keys on separate lines")
		}
	}
}

func isStructType(expression ast.Expr, structs map[string]bool) bool {
	switch keyType := expression.(type) {
	case *ast.StructType:
		return true

	case *ast.Ident:
		return structs[keyType.Name]
	}

	return false
}

func declaredTypes(dir string) (localTypes, error) {
	if known, found := typesByDir[dir]; found {
		return known, nil
	}

	entries, err := os.ReadDir(dir)

	if err != nil {
		return localTypes{}, err
	}

	types := localTypes{
		structs:       map[string]bool{},
		structKeyMaps: map[string]bool{},
	}

	var declarations []*ast.TypeSpec

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".go") {
			continue
		}

		path := filepath.Join(dir, entry.Name())
		file, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)

		if err != nil {
			return localTypes{}, err
		}

		for _, declaration := range file.Decls {
			group, ok := declaration.(*ast.GenDecl)

			if !ok {
				continue
			}

			for _, spec := range group.Specs {
				typeSpec, ok := spec.(*ast.TypeSpec)

				if !ok {
					continue
				}

				declarations = append(declarations, typeSpec)

				if _, isStruct := typeSpec.Type.(*ast.StructType); isStruct {
					types.structs[typeSpec.Name.Name] = true
				}
			}
		}
	}

	for _, typeSpec := range declarations {
		mapType, ok := typeSpec.Type.(*ast.MapType)

		if !ok {
			continue
		}

		types.structKeyMaps[typeSpec.Name.Name] = isStructType(mapType.Key, types.structs)
	}

	typesByDir[dir] = types

	return types, nil
}

func scalarElements(elements []ast.Expr) bool {
	for _, element := range elements {
		switch value := element.(type) {
		case *ast.BasicLit, *ast.Ident:
			continue

		case *ast.UnaryExpr:
			if _, literal := value.X.(*ast.BasicLit); literal {
				continue
			}
		}

		return false
	}

	return true
}

func entriesShareLine(fset *token.FileSet, literal *ast.CompositeLit) bool {
	if sameLine(fset, literal.Lbrace, literal.Elts[0].Pos()) ||
		sameLine(fset, literal.Elts[len(literal.Elts)-1].End()-1, literal.Rbrace) {
		return true
	}

	for index := 1; index < len(literal.Elts); index++ {
		if sameLine(fset, literal.Elts[index-1].End()-1, literal.Elts[index].Pos()) {
			return true
		}
	}

	return false
}

func literalHasGroupBreak(
	fset *token.FileSet,
	literal *ast.CompositeLit,
	lines []string,
) bool {
	for index := 1; index < len(literal.Elts); index++ {
		previousEnd := fset.Position(literal.Elts[index-1].End() - 1).Line
		nextStart := fset.Position(literal.Elts[index].Pos()).Line

		for line := previousEnd + 1; line < nextStart; line++ {
			if strings.TrimSpace(lines[line-1]) == "" {
				return true
			}
		}
	}

	return false
}

func isStructLiteralType(
	expression ast.Expr,
	local localTypes,
	imports map[string]localTypes,
) bool {
	switch value := expression.(type) {
	case *ast.Ident, *ast.StructType:
		return isStructType(expression, local.structs)

	case *ast.SelectorExpr:
		owner, ok := value.X.(*ast.Ident)

		return ok && imports[owner.Name].structs[value.Sel.Name]

	case *ast.IndexExpr:
		return isStructLiteralType(value.X, local, imports)

	case *ast.IndexListExpr:
		return isStructLiteralType(value.X, local, imports)
	}

	return false
}

func moduleRoot() (string, error) {
	dir, err := os.Getwd()

	if err != nil {
		return "", err
	}

	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir, nil
		}

		parent := filepath.Dir(dir)

		if parent == dir {
			return "", fmt.Errorf("cannot locate project go.mod")
		}

		dir = parent
	}
}

func isControl(statement ast.Stmt) bool {
	switch statement.(type) {
	case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt,
		*ast.SwitchStmt, *ast.TypeSwitchStmt, *ast.SelectStmt:
		return true
	}

	return false
}
