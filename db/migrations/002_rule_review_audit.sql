ALTER TABLE renewal_rule_versions
  ADD COLUMN IF NOT EXISTS review_note text;

-- statement-breakpoint

ALTER TABLE renewal_rule_versions
  ADD COLUMN IF NOT EXISTS reviewed_by text;
