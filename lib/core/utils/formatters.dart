String getCategoryLabel(String value) {
  return switch (value) {
    "GENERAL_MERCHANDISE" => "Shopping",
    "FOOD_AND_DRINK" => "Food & Drink",
    "ENTERTAINMENT" => "Leisure",
    "PERSONAL_CARE" => "Personal Care",
    "LOAN_PAYMENTS" => "Loans",
    "TRANSPORTATION" => "Transit",
    "TRAVEL" => "Travel",
    "BANK_FEES" => "Bank Fees",
    "HOME_IMPROVEMENT" => "Home Improvement",
    "MEDICAL" => "Medical",
    "GENERAL_SERVICES" => "Services",
    "GOVERNMENT_AND_NON_PROFIT" => "Govt & Non-Profit",
    "RENT_AND_UTILITIES" => "Bills & Utilities",
    "INCOME" => "Income",
    "TRANSFER_IN" => "Transfer In",
    "TRANSFER_OUT" => "Transfer Out",
    _ => formatSnakeCaseToTitle(value),
  };
}

String formatSnakeCaseToTitle(String input) {
  if (input.isEmpty) return "";

  return input
      .split('_')
      .map((word) {
        if (word.isEmpty) return "";
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}
