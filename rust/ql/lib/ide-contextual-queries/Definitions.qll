/**
 * Provides classes and predicates related to jump-to-definition links
 * in the code viewer.
 */

private import codeql.rust.elements.Variable
private import codeql.rust.elements.Locatable
private import codeql.rust.elements.FormatArgsExpr
private import codeql.rust.elements.FormatArgsArg
private import codeql.rust.elements.NamedFormatArgument
private import codeql.rust.elements.PositionalFormatArgument

/** An element with an associated definition. */
abstract class Use extends Locatable {
  /** Gets the definition associated with this element. */
  abstract Definition getDefinition();

  /**
   * Gets the type of use.
   */
  abstract string getUseType();
}

private newtype TDef =
  TVariable(Variable v) or
  TFormatArgsArgName(Name name) { name = any(FormatArgsArg a).getName() } or
  TFormatArgsArgIndex(Expr e) { e = any(FormatArgsArg a).getExpr() }

/** A definition */
class Definition extends TDef {
  /**
   * Holds if this element is at the specified location.
   * The location spans column `startcolumn` of line `startline` to
   * column `endcolumn` of line `endline` in file `filepath`.
   * For more information, see
   * [Providing locations in CodeQL queries](https://codeql.github.com/docs/writing-codeql-queries/providing-locations-in-codeql-queries/).
   */
  predicate hasLocationInfo(string file, int startLine, int startColumn, int endLine, int endColumn) {
    this.asVariable()
        .getLocation()
        .hasLocationInfo(file, startLine, startColumn, endLine, endColumn) or
    this.asName().hasLocationInfo(file, startLine, startColumn, endLine, endColumn) or
    this.asExpr().hasLocationInfo(file, startLine, startColumn, endLine, endColumn)
  }

  /** Gets this definition as a `Variable` */
  Variable asVariable() { this = TVariable(result) }

  /** Gets this definition as a `Name` */
  Name asName() { this = TFormatArgsArgName(result) }

  /** Gets this definition as an `Expr` */
  Expr asExpr() { this = TFormatArgsArgIndex(result) }

  /** Gets the string representation of this element. */
  string toString() {
    result = this.asExpr().toString() or
    result = this.asVariable().toString() or
    result = this.asName().getText()
  }
}

private class LocalVariableUse extends Use instanceof VariableAccess {
  private Variable def;

  LocalVariableUse() { this = def.getAnAccess() }

  override Definition getDefinition() { result.asVariable() = def }

  override string getUseType() { result = "local variable" }
}

private class NamedFormatArgumentUse extends Use instanceof NamedFormatArgument {
  private Name def;

  NamedFormatArgumentUse() {
    exists(FormatArgsExpr parent |
      parent = this.getParent().getParent() and
      parent.getAnArg().getName() = def and
      this.getName() = def.getText()
    )
  }

  override Definition getDefinition() { result.asName() = def }

  override string getUseType() { result = "format argument" }
}

private class PositionalFormatArgumentUse extends Use instanceof PositionalFormatArgument {
  private Expr def;

  PositionalFormatArgumentUse() {
    exists(FormatArgsExpr parent |
      parent = this.getParent().getParent() and
      def = parent.getArg(this.getIndex()).getExpr()
    )
  }

  override Definition getDefinition() { result.asExpr() = def }

  override string getUseType() { result = "format argument" }
}

/**
 * Gets an element, of kind `kind`, that element `use` uses, if any.
 */
cached
Definition definitionOf(Use use, string kind) {
  result = use.getDefinition() and kind = use.getUseType()
}
