class PspShort < ApplicationRecord

  def self.get_psp_shorts
    pspShortRows = self.all.select(:short, :psp_id)
    pspShorts = Hash.new
    pspShortRows.each {|pspShortRow|
      pspId = pspShortRow[:psp_id]
      short = pspShortRow[:short]
      pspShorts[pspId] ||= Array.new
      pspShorts[pspId] << short
    }
    return pspShorts
  end
end