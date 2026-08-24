ALTER TABLE source_documents
  ADD COLUMN IF NOT EXISTS proposes_rule boolean NOT NULL DEFAULT true;

-- statement-breakpoint

UPDATE source_documents
   SET proposes_rule = false
 WHERE is_index = true;
