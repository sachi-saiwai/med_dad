export interface RequirementInput {
  label: string;
  minimum?: number;
  maximum?: number;
  requiredValue?: number;
  unit: '単位' | '症例' | '回' | '件';
  mandatory: boolean;
  evidence?: string;
}

export interface RuleCorrections {
  systemType: string;
  acquiredYearFrom?: number;
  acquiredYearTo?: number;
  renewalYearFrom?: number;
  renewalYearTo?: number;
  renewalCycleYears?: number;
  requiredTotalCredits?: number;
  requirements: RequirementInput[];
  mandatoryNotes: string[];
  otherConditions: string[];
}

const optionalNumber = (
  value: unknown,
  label: string,
  minimum: number,
  maximum: number,
): number | undefined => {
  if (value === undefined || value === null || value === '') return undefined;
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new Error(`${label} must be a number`);
  }
  if (value < minimum || value > maximum) {
    throw new Error(`${label} is out of range`);
  }
  return value;
};

const shortText = (value: unknown, label: string, maximum: number): string => {
  if (typeof value !== 'string' || !value.trim()) throw new Error(`${label} is required`);
  if (value.trim().length > maximum) throw new Error(`${label} is too long`);
  return value.trim();
};

const textLines = (value: unknown, label: string): string[] => {
  if (!Array.isArray(value) || value.length > 50) throw new Error(`${label} is invalid`);
  return value.map((item) => shortText(item, label, 1000));
};

export const validateRuleCorrections = (value: unknown): RuleCorrections => {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('rule is required');
  }
  const input = value as Record<string, unknown>;
  const acquiredYearFrom = optionalNumber(input.acquiredYearFrom, 'acquiredYearFrom', 1900, 2200);
  const acquiredYearTo = optionalNumber(input.acquiredYearTo, 'acquiredYearTo', 1900, 2200);
  if (
    acquiredYearFrom !== undefined &&
    acquiredYearTo !== undefined &&
    acquiredYearFrom > acquiredYearTo
  ) {
    throw new Error('acquiredYearFrom must not be after acquiredYearTo');
  }
  const renewalYearFrom = optionalNumber(input.renewalYearFrom, 'renewalYearFrom', 1900, 2200);
  const renewalYearTo = optionalNumber(input.renewalYearTo, 'renewalYearTo', 1900, 2200);
  if (
    renewalYearFrom !== undefined &&
    renewalYearTo !== undefined &&
    renewalYearFrom > renewalYearTo
  ) {
    throw new Error('renewalYearFrom must not be after renewalYearTo');
  }

  if (!Array.isArray(input.requirements) || input.requirements.length > 40) {
    throw new Error('requirements is invalid');
  }
  const requirements = input.requirements.map((raw, index): RequirementInput => {
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
      throw new Error(`requirements[${index}] is invalid`);
    }
    const item = raw as Record<string, unknown>;
    const unit = item.unit;
    if (!['単位', '症例', '回', '件'].includes(String(unit))) {
      throw new Error(`requirements[${index}].unit is invalid`);
    }
    const minimum = optionalNumber(item.minimum, `requirements[${index}].minimum`, 0, 100000);
    const maximum = optionalNumber(item.maximum, `requirements[${index}].maximum`, 0, 100000);
    const requiredValue = optionalNumber(
      item.requiredValue,
      `requirements[${index}].requiredValue`,
      0,
      100000,
    );
    if (minimum !== undefined && maximum !== undefined && minimum > maximum) {
      throw new Error(`requirements[${index}] minimum exceeds maximum`);
    }
    if (minimum === undefined && maximum === undefined && requiredValue === undefined) {
      throw new Error(`requirements[${index}] needs a value`);
    }
    return {
      label: shortText(item.label, `requirements[${index}].label`, 200),
      minimum,
      maximum,
      requiredValue,
      unit: unit as RequirementInput['unit'],
      mandatory: item.mandatory === true,
      evidence:
        typeof item.evidence === 'string' && item.evidence.trim()
          ? item.evidence.trim().slice(0, 2000)
          : undefined,
    };
  });

  return {
    systemType: shortText(input.systemType, 'systemType', 100),
    acquiredYearFrom,
    acquiredYearTo,
    renewalYearFrom,
    renewalYearTo,
    renewalCycleYears: optionalNumber(input.renewalCycleYears, 'renewalCycleYears', 1, 20),
    requiredTotalCredits: optionalNumber(
      input.requiredTotalCredits,
      'requiredTotalCredits',
      0,
      100000,
    ),
    requirements,
    mandatoryNotes: textLines(input.mandatoryNotes ?? [], 'mandatoryNotes'),
    otherConditions: textLines(input.otherConditions ?? [], 'otherConditions'),
  };
};
