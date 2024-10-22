/**
 * @name Jump-to-definition links
 * @description Generates use-definition pairs that provide the data
 *              for jump-to-definition in the code viewer.
 * @kind definitions
 * @id rust/ide-jump-to-definition
 * @tags ide-contextual-queries/local-definitions
 */

import codeql.IDEContextual
import Definitions

external string selectedSourceFile();

from Use use, Definition def, string kind
where
  def = definitionOf(use, kind) and
  use.hasLocationInfo(getFileBySourceArchiveName(selectedSourceFile()).getAbsolutePath(), _, _, _, _)
select use, def, kind
