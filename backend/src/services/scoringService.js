// ─────────────────────────────────────────────────────
// scoringService.js
// Rule-based lead risk scoring engine
// Can be upgraded to OpenAI later
// ─────────────────────────────────────────────────────

/**
 * Score a lead based on financial profile
 * Returns score 0-100 (higher = less risk = better lead)
 */
function scoreLead({ income, debt, creditScore, loanAmount, employmentStatus }) {

  let score = 0;
  const breakdown = [];
  const flags = [];

  // ── 1. CREDIT SCORE (max 35 points) ─────────────────
  if (creditScore >= 800) {
    score += 35;
    breakdown.push({ factor: 'Credit Score', points: 35, note: 'Exceptional credit' });
  } else if (creditScore >= 740) {
    score += 30;
    breakdown.push({ factor: 'Credit Score', points: 30, note: 'Very good credit' });
  } else if (creditScore >= 670) {
    score += 22;
    breakdown.push({ factor: 'Credit Score', points: 22, note: 'Good credit' });
  } else if (creditScore >= 580) {
    score += 12;
    breakdown.push({ factor: 'Credit Score', points: 12, note: 'Fair credit' });
    flags.push('Credit score below recommended threshold');
  } else {
    score += 0;
    breakdown.push({ factor: 'Credit Score', points: 0, note: 'Poor credit' });
    flags.push('Credit score is too low — high risk');
  }

  // ── 2. DEBT-TO-INCOME RATIO (max 30 points) ─────────
  const monthlyIncome = income / 12;
  const monthlyDebt = debt / 12;
  const dti = monthlyIncome > 0 ? (monthlyDebt / monthlyIncome) * 100 : 100;

  if (dti <= 20) {
    score += 30;
    breakdown.push({ factor: 'Debt-to-Income', points: 30, note: `DTI ${dti.toFixed(1)}% — Excellent` });
  } else if (dti <= 28) {
    score += 24;
    breakdown.push({ factor: 'Debt-to-Income', points: 24, note: `DTI ${dti.toFixed(1)}% — Good` });
  } else if (dti <= 36) {
    score += 16;
    breakdown.push({ factor: 'Debt-to-Income', points: 16, note: `DTI ${dti.toFixed(1)}% — Acceptable` });
  } else if (dti <= 43) {
    score += 8;
    breakdown.push({ factor: 'Debt-to-Income', points: 8, note: `DTI ${dti.toFixed(1)}% — High` });
    flags.push('DTI ratio above 36% — lenders may require review');
  } else {
    score += 0;
    breakdown.push({ factor: 'Debt-to-Income', points: 0, note: `DTI ${dti.toFixed(1)}% — Too high` });
    flags.push('DTI ratio exceeds 43% — most lenders will reject');
  }

  // ── 3. LOAN-TO-INCOME RATIO (max 20 points) ─────────
  const lti = income > 0 ? loanAmount / income : 99;

  if (lti <= 3) {
    score += 20;
    breakdown.push({ factor: 'Loan-to-Income', points: 20, note: `LTI ${lti.toFixed(1)}x — Excellent` });
  } else if (lti <= 4) {
    score += 15;
    breakdown.push({ factor: 'Loan-to-Income', points: 15, note: `LTI ${lti.toFixed(1)}x — Good` });
  } else if (lti <= 5) {
    score += 8;
    breakdown.push({ factor: 'Loan-to-Income', points: 8, note: `LTI ${lti.toFixed(1)}x — Borderline` });
    flags.push('Loan amount is high relative to income');
  } else {
    score += 0;
    breakdown.push({ factor: 'Loan-to-Income', points: 0, note: `LTI ${lti.toFixed(1)}x — Too high` });
    flags.push('Loan amount significantly exceeds income capacity');
  }

  // ── 4. EMPLOYMENT STATUS (max 15 points) ────────────
  const employment = (employmentStatus || 'unknown').toLowerCase();

  if (employment === 'employed') {
    score += 15;
    breakdown.push({ factor: 'Employment', points: 15, note: 'Fully employed' });
  } else if (employment === 'self-employed') {
    score += 10;
    breakdown.push({ factor: 'Employment', points: 10, note: 'Self-employed — verify income documentation' });
    flags.push('Self-employed borrowers require additional income verification');
  } else if (employment === 'part-time') {
    score += 6;
    breakdown.push({ factor: 'Employment', points: 6, note: 'Part-time employment' });
    flags.push('Part-time income may not meet lender requirements');
  } else {
    score += 0;
    breakdown.push({ factor: 'Employment', points: 0, note: 'Unemployed or unknown' });
    flags.push('Employment status unclear — high risk');
  }

  // ── RISK LABEL ───────────────────────────────────────
  let riskLabel, riskColor, recommendation;

  if (score >= 80) {
    riskLabel = 'Low Risk';
    riskColor = 'green';
    recommendation = 'Excellent candidate. Prioritize and fast-track this lead. High probability of approval.';
  } else if (score >= 60) {
    riskLabel = 'Moderate Risk';
    riskColor = 'orange';
    recommendation = 'Good candidate with some areas to address. Review flagged items before submission.';
  } else if (score >= 40) {
    riskLabel = 'High Risk';
    riskColor = 'red';
    recommendation = 'Proceed with caution. Significant risk factors present. Consider alternative loan products.';
  } else {
    riskLabel = 'Very High Risk';
    riskColor = 'darkred';
    recommendation = 'Not recommended for standard mortgage products. Explore credit improvement options first.';
  }

  // ── LOAN RECOMMENDATION ──────────────────────────────
  let loanRecommendation;

  if (creditScore >= 740 && dti <= 36) {
    loanRecommendation = {
      type: 'Conventional Loan',
      reason: 'Strong credit and healthy DTI qualify for conventional financing',
      suggestedRate: '6.25% - 6.75%',
    };
  } else if (creditScore >= 580 && dti <= 43) {
    loanRecommendation = {
      type: 'FHA Loan',
      reason: 'FHA loans are suitable for borrowers with moderate credit scores',
      suggestedRate: '6.75% - 7.25%',
    };
  } else if (employmentStatus === 'self-employed') {
    loanRecommendation = {
      type: 'Bank Statement Loan',
      reason: 'Self-employed borrowers benefit from bank statement loan programs',
      suggestedRate: '7.00% - 7.75%',
    };
  } else {
    loanRecommendation = {
      type: 'Credit Improvement Required',
      reason: 'Current profile does not qualify for standard products',
      suggestedRate: 'N/A',
    };
  }

  return {
    score,
    riskLabel,
    riskColor,
    recommendation,
    loanRecommendation,
    breakdown,
    flags,
    metrics: {
      dti: parseFloat(dti.toFixed(2)),
      lti: parseFloat(lti.toFixed(2)),
      creditScore,
      monthlyIncome: parseFloat(monthlyIncome.toFixed(2)),
    },
  };
}

module.exports = { scoreLead };