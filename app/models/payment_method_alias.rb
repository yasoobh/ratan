class PaymentMethodAlias < ApplicationRecord

  def self.get_payment_method_aliases
    paymentMethodAliasRows = self.all.select(:payment_method_id, :alias)
    paymentMethodAliases = Hash.new
    paymentMethodAliasRows.each { |paymentMethodAliasRow|
      paymentMethodId = paymentMethodAliasRow[:payment_method_id]
      paymentMethodAlias = paymentMethodAliasRow[:alias]
      paymentMethodAliases[paymentMethodId] ||= Array.new
      paymentMethodAliases[paymentMethodId] << paymentMethodAlias
    }
    return paymentMethodAliases
  end
end