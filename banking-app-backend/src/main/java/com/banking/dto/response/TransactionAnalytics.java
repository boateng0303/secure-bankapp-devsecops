package com.banking.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionAnalytics {
    private MonthlyData monthlyData;
    private TypeDistribution typeDistribution;
    private DailyCashFlow dailyCashFlow;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MonthlyData {
        private List<String> labels; // ["Jan", "Feb", "Mar", ...]
        private List<BigDecimal> deposits;
        private List<BigDecimal> withdrawals;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TypeDistribution {
        private Integer deposits;
        private Integer withdrawals;
        private Integer transfersOut;
        private Integer transfersIn;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyCashFlow {
        private List<String> labels; // ["Dec 1", "Dec 2", ...]
        private List<BigDecimal> netFlow; // positive = income, negative = expense
    }
}

