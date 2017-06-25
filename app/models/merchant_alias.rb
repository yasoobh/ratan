class MerchantAlias < ApplicationRecord

  def self.get_merchant_aliases
    merchantAliasRows = self.all.select(:merchant_id, :alias)
    merchantAliases = Hash.new
    merchantAliasRows.each {|merchantAliasRow|
      merchantId = merchantAliasRow[:merchant_id]
      merchantAlias = merchantAliasRow[:alias]
      merchantAliases[merchantId] ||= Array.new
      merchantAliases[merchantId] << merchantAlias
    }
    return merchantAliases
  end
end