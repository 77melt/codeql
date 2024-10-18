/**
 * @name Find-references links
 * @description Generates use-definition pairs that provide the data
 *              for find-references in the code viewer.
 * @kind definitions
 * @id rust/ide-find-references
 * @tags ide-contextual-queries/local-references
 */

import codeql.IDEContextual
import Definitions

external string selectedSourceFile();

from Use use, Definition def, string kind
where
  def = definitionOf(use, kind) and
  def.hasLocationInfo(getFileBySourceArchiveName(selectedSourceFile()).getAbsolutePath(), _, _, _, _)
select use, def, kind
