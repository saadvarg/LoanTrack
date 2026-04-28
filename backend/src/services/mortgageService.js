function calculateMonthlyPayment(principal, annualRate, termYears) {
  const monthlyRate = annualRate / 100 / 12;
  const numberOfPayments = termYears * 12;
  if (monthlyRate === 0) return principal / numberOfPayments;
  const payment = (principal * (monthlyRate * Math.pow(1 + monthlyRate, numberOfPayments))) /
    (Math.pow(1 + monthlyRate, numberOfPayments) - 1);
  return Math.round(payment * 100) / 100;
}

function calculateMortgage({ loanAmount, downPayment = 0, interestRate, termYears }) {
  const principal = loanAmount - downPayment;
  const monthlyPayment = calculateMonthlyPayment(principal, interestRate, termYears);
  const totalPayment = Math.round(monthlyPayment * termYears * 12 * 100) / 100;
  const totalInterest = Math.round((totalPayment - principal) * 100) / 100;
  return {
    principal,
    monthlyPayment,
    totalPayment,
    totalInterest,
    loanToValue: Math.round((principal / loanAmount) * 100 * 100) / 100,
  };
}

function generateAmortizationSchedule({ loanAmount, downPayment = 0, interestRate, termYears }) {
  const principal = loanAmount - downPayment;
  const monthlyRate = interestRate / 100 / 12;
  const numberOfPayments = termYears * 12;
  const monthlyPayment = calculateMonthlyPayment(principal, interestRate, termYears);
  let balance = principal;
  const schedule = [];
  for (let month = 1; month <= numberOfPayments; month++) {
    const interestPayment = Math.round(balance * monthlyRate * 100) / 100;
    const principalPayment = Math.round((monthlyPayment - interestPayment) * 100) / 100;
    balance = Math.round((balance - principalPayment) * 100) / 100;
    schedule.push({
      month,
      payment: monthlyPayment,
      principal: principalPayment,
      interest: interestPayment,
      balance: Math.max(0, balance),
    });
  }
  return schedule;
}

function compareLoans(scenarios) {
  return scenarios.map((scenario, index) => {
    const result = calculateMortgage(scenario);
    return {
      scenario: index + 1,
      label: scenario.label || `Option ${index + 1}`,
      ...scenario,
      ...result,
    };
  });
}

module.exports = { calculateMortgage, generateAmortizationSchedule, compareLoans };
