ALTER TABLE source_documents
  ADD COLUMN IF NOT EXISTS renewal_year_from integer;

-- statement-breakpoint

ALTER TABLE source_documents
  ADD COLUMN IF NOT EXISTS renewal_year_to integer;

-- statement-breakpoint

ALTER TABLE renewal_rule_versions
  ADD COLUMN IF NOT EXISTS renewal_year_from integer;

-- statement-breakpoint

ALTER TABLE renewal_rule_versions
  ADD COLUMN IF NOT EXISTS renewal_year_to integer;

-- statement-breakpoint

CREATE INDEX IF NOT EXISTS renewal_rule_year_lookup_idx
  ON renewal_rule_versions (
    qualification_id, status, system_type,
    renewal_year_from, renewal_year_to
  );
