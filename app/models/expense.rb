class Expense < ApplicationRecord

  @@pspShortMap = {
    'HDFC Bank' => ['vmhdfcbk','vkhdfcbk','bhhdfcbk','amhdfcbk','adhdfcbk','vmhdfcmp','imhdfcbk','dmhdfcbk','mdhdfcbk','bwhdfcbk','mmhdfcbk','vkhdfcmp','idhdfcbk','rmhdfcbk','dzhdfcbk'],
    'Kotak Mahindra Bank' => ['vm-kotakb','vk-kotakb','dm-kotakb','im-kotakb','id-kotakb','im-kotaks','vm-kotakm','vm-kotaks','vmkotakb','amkotakb','vkkotakb','imkotakb','vkkotaks','vmkotaks','dmkotakb','bhkotaks','bzkotaks','adkotaks','imkotaks','dmkotaks','hpkotaks','rmkotaks','amkotaks','idkotakb'],
    'State Bank of India' => ['bz-sbiinb','bx-sbiinb','bz-atmsbi','vk-sbiinb','vmsbiacs','vk-cbssbi','vm-cbssbi','bzatmsbi','bx-atmsbi','vm-sbiinb','dm-sbiinb','bz-sbiacs','bpatmsbi','bp-sbiinb','bxatmsbi','vk-sbipsg','vmcbssbi','vk-atmsbi','tm-sbiacs','amsbiacs','vmsbibdp','bp-atmsbi','vksbiupi','vm-atmsbi','vkcbssbi','vm-sbiacs','amcbssbi','bx-sbiacs','amsbibnk','dm-sbibnk','vksbiotp','imcbssbi','vmsbibnk','vk-sbiotp','vk-sbiacs','vm-sbibnk','im-sbipsg','bxsbiacs','adsbibnk','amatmsbi','bpsbiacs','vkatmsbi','vm-sbipsg','vk-sbibnk','bz-sbibnk','bpsbiinb','dzsbibnk','vksbiacs','vksbibnk']
  }

  # def process_raw_expenses
  #   probableRawTransactions = Hash.new
  #   @@pspShortMap.each { |psp, pspShorts|
  #     pspShorts.each { |short|
  #       Erd.where("sender_address = '" + short + "'").select("message_content").each { |row|
  #         (probableRawTransactions[psp] ||= Array.new) << row["message_content"]
  #       }
  #     }
  #   }
  #   # these will also need to be extracted from the content of the messages.
  #   # merchantNames = ['VFCARE', 'DOMINO', 'GROFRS', 'FAASOS', 'RIVIGO', 'FPANDA', 'BIRBLU','ZOMATO','Amazon','PTRENG','UBERIN','MYSHPO','INMOJO','MYAMEX','VDFONE','Quikrr','GoIBIB','PLFSHN','CHAYOS','FCTZEN','BUENOK','BRSNGH','OLACAB','MYNTRA','SWIGGY','BENTTN','CANTBL','IMYPAT','AIROAM','SIMPLX','IRCTCi','CBSSBI','mShopo','SBRWDZ','PANTLS','SPARHM','OYORMS','ZOPPER','ARWINF','DUNKND','PRACTO','INDANE','Paytm']

  #   begin
  #     file = File.open("probable_raw_transactions.csv", 'w')
  #     file_2 = File.open("probable_raw_transactions_discarded.csv", 'w')
  #     probableRawTransactions.each { |psp, messageContents|
  #       messageContents.each { |messageContent|
  #         # file.write("\"" + psp + "\",\"" + messageContent+"\"\n")
  #         messageContentDc = messageContent.downcase
  #         if filter_message_content(messageContentDc)
  #           moneySpent = get_money_from_raw_expense(messageContentDc)
  #           if not moneySpent.nil?
  #             merchantName = get_merchant_name_from_raw_expense(messageContent)
  #             file.write("\"" + psp + "\",\"" + messageContent + "\"," + moneySpent.to_s + ",\"" + merchantName + "\"\n")
  #           else
  #             file_2.write("\"" + psp + "\",\"" + messageContent + "\"," + moneySpent.to_s + "\n")
  #           end
  #         end
  #       }
  #     }
  #   rescue Exception => e
  #     puts e
  #   ensure
  #     file.close unless file.nil?
  #     file_2.close unless file_2.nil?
  #   end
  # end

  def self.process_all_expenses_for_device(deviceId)
    rawExpenses = Erd.where(device_id: deviceId)
    processed = 0
    total = 0
    rawExpenses.each {|rawExpense|
      total += 1
      messageContent = rawExpense['message_content']
      messageTime = rawExpense['message_time']
      messageSender = rawExpense['message_sender']
      messageId = rawExpense['message_id']
      if self.process_raw_expense(messageSender, messageContent, messageTime)
        processed += 1
      end
    }
    p (processed.to_f/total*100).round(2).to_s
  end

  def self.process_raw_expense(messageSender, messageContent, messageTime)
    if filter_message_content(messageContent.downcase)
      psp = get_payment_service_provider_from_raw_expense(messageSender.downcase)
      moneySpent = get_money_from_raw_expense(messageContent.downcase)
      if moneySpent.nil?
        return false
      end
      merchantName = get_merchant_name_from_raw_expense(messageContent)
      if merchantName.nil?
        return false
      end
      p psp.to_s + "," + moneySpent.to_s + "," + merchantName.to_s + "," + messageContent
      return true
    end
  end

  def self.get_payment_service_provider_from_raw_expense(messageSenderDc)
    @@pspShortMap.each {|psp, pspShorts|
      pspShorts.each{|short|
        if (short == messageSenderDc)
          return psp
        end
      }
    }
    return 'Others'
  end

  # /via (.*?) on/
  # /at [\+A-Z*?] on/ (with case match)
  # /at (a-z*?) on/ (without case match)
  # /netbanking/
  def self.get_merchant_name_from_raw_expense(messageContent)
    merchant_1 = /via (.*?) on/
    merchant_2 = / at ([A-Za-z\+ ]*?) [(on)|(txn)|\.]/
    merchant_3 = / at ([a-z ]*?) on/
    merchant_4 = /(netbanking)/
    merchant_5 = / at ([A-Za-z\+ ]*?)/

    (1..4).each { |i|
      merchant_num = eval('merchant_'+i.to_s)
      regexMatch = merchant_num.match(messageContent)
      if not regexMatch.nil?
        return regexMatch[1]
      end
    }
    return nil
  end

  # for Rs.99.00 + debit
  # INR 99 + debit
  # Rs.3000.00 was withdrawn
  # Rs.290.00 was spent
  # 3000.00 is debited
  # Transaction of Rs 239 has been made
  # Rs 2500 withdrawn
  def self.get_money_from_raw_expense(messageContentDc)
    money_0 = /(inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+)/
    money_1 = /for (inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+).*debit/
    money_2 = /debit.*for (inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+)/
    money_3 = /(inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+) was withdrawn/
    money_4 = /(inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+) was spent/
    money_5 = /(inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+) is debited/
    money_6 = /transaction of (inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+) has been made/
    money_7 = /(inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+) withdrawn/
    money_8 = /(inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+) has been debited/
    money_9 = /for a purchase worth (inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+)/
    money_10 = /for (inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+)/
    money_11 = /(inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+) .*cash withdrawal/
    money_12 = /cash withdrawal of (inr)|(r(upee)?s)[\. ]? ?([0-9\.,]+)/

    (1..12).each { |i|
      money_num = eval('money_'+i.to_s)
      regexMatch = money_num.match(messageContentDc)
      if not regexMatch.nil?
        return regexMatch[4]
      end
    }
    return nil
  end

  # Remove OTP messages
  # Remove One Time Password messages
  # Remove declined
  # Remove transfer
  # Remove salary
  # Remove deposited to a/c
  # Remove credited
  # Remove UPI
  # Keep Rs[0-9\. ]
  # Keep Rupees[0-9\. ]
  # Keep INR
  # Keep debited
  def self.filter_message_content(messageContentDc)
    discardedKeywords = [/otp/, /one time password/, /declined/, /transfer/, /salary/, /deposited to a\/c/, /credited/, /upi/, /imps/, /statement/, /stmt/]
    includedKeywords = [/inr/, /debited/, /r(upee)?s[\. ]? ?([0-9\.,]+)/]

    discardedKeywords.each { |discardedKeyword|
      regexMatch = discardedKeyword.match(messageContentDc)
      if not regexMatch.nil?
        return false
      end
    }

    includedKeywords.each { |includedKeyword|
      regexMatch = includedKeyword.match(messageContentDc)
      if not regexMatch.nil?
        return true
      end
    }
    return false
  end
end