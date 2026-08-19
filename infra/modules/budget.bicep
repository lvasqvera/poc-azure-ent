@description('Prefijo usado para nombrar los recursos')
param namePrefix string

@description('Monto mensual del budget en USD')
param budgetAmount int

@description('Umbral de alerta como porcentaje del budget')
param budgetThresholdPercentage int

@description('Correos a notificar cuando se cruza el umbral')
param contactEmails array

// Fecha de inicio: primer día del mes actual. endDate: 10 años después
// (máximo soportado por Microsoft.Consumption/budgets para budgets mensuales).
param startDate string = utcNow('yyyy-MM-01')
param endDate string = dateTimeAdd(startDate, 'P10Y', 'yyyy-MM-dd')

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: '${namePrefix}-monthly-budget'
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    notifications: {
      actualCostAlert80pct: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: budgetThresholdPercentage
        thresholdType: 'Actual'
        contactEmails: contactEmails
      }
    }
  }
}

output budgetName string = budget.name
