class Expense < ApplicationRecord

  @@pspShortMap = PspShort.get_psp_shorts
  @@merchantList = MerchantAlias.get_merchant_aliases
  @@paymentMethodAliases = PaymentMethodAlias.get_payment_method_aliases

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

  def self.process_all_expenses_for_users
    userIds = [6, 7, 8]
    userIds.each {|userId|
      self.process_all_expenses_for_user(userId)
    }
  end

  def self.process_all_expenses_for_devices
    deviceIds = ['yasoobs_device_1', 'rhythms_device_1', 'sagars_device_1']
    deviceIds.each {|deviceId|
      self.process_all_expenses_for_device(deviceId)
    }
  end

  def self.process_all_expenses_for_user(userId)
    devices = Device.where(user_id: userId)
    devices.each { |device|
      deviceId = device.device_id
      process_all_expenses_for_device(deviceId)
    }
  end

  def self.process_all_expenses_for_device(deviceId)
    rawExpenses = Erd.where(device_id: deviceId)
    deviceUser = Device.where(device_id: deviceId).select(:user_id).take
    if !deviceUser.nil?
      userId = deviceUser[:user_id]
    else
      return false
    end
    processed = 0
    total = 0
    rawExpenses.each {|rawExpense|
      total += 1
      messageContent = rawExpense['message_content']
      messageTime = rawExpense['message_time']
      messageSender = rawExpense['message_sender']
      messageId = rawExpense['message_id']
      if process_raw_expense(messageId, messageSender, messageContent, messageTime, userId)
        processed += 1
      end
    }
    return true
  end

  def self.process_raw_expense(messageId, messageSender, messageContent, messageTime, userId)
    if filter_message_content(messageContent.downcase)
      pspId = get_payment_service_provider_from_raw_expense(messageSender.downcase)
      moneySpent = get_money_from_raw_expense(messageContent.downcase)
      if moneySpent.nil?
        return false
      end
      merchantId = get_merchant_id_from_raw_expense(messageContent)
      cardNumberEnding = get_card_info_from_raw_expense(messageContent.downcase)
      paymentMethodId = get_payment_method_from_raw_expense(messageContent.downcase)
      begin
        exp = Expense.new
        exp.user_id = userId
        exp.merchant_id = merchantId
        exp.amount = moneySpent
        exp.payment_method_id = paymentMethodId
        exp.card_number_ending = cardNumberEnding
        exp.payment_service_provider_id = pspId
        exp.transaction_time = messageTime
        exp.raw_message_id = messageId
        exp.save
      rescue Exception => e
        p e
        return false
      end
      # p psp.to_s + " $ " + moneySpent.to_s + " $ " + merchantId.to_s + " $ " + cardInfo.to_s + " $ " + paymentMethodId.to_s + " $ " + messageContent
      return true
    end
  end

  def self.get_card_info_from_raw_expense(messageContentDc)
    card_info_1 = /x([0-9]{4,4})/
    card_info_2 = /ending ([0-9]{4,4})/

    (1..2).each { |i|
      card_info_num = eval('card_info_'+i.to_s)
      regexMatch = card_info_num.match(messageContentDc)
      if not regexMatch.nil?
        return regexMatch[1]
      end
    }
    return nil
  end

  def self.get_payment_method_from_raw_expense(messageContentDc)
    @@paymentMethodAliases.each { |paymentMethodId, paymentMethodAliases|
      paymentMethodAliases.each { |paymentMethodAlias|
        regexp = Regexp.new paymentMethodAlias
        if regexp.match(messageContentDc)
          return paymentMethodId
        end
      }
    }
    return nil
  end

  def self.get_payment_service_provider_from_raw_expense(messageSenderDc)
    @@pspShortMap.each {|psp, pspShorts|
      pspShorts.each{|short|
        if (short == messageSenderDc)
          return psp
        end
      }
    }
    return nil
  end

  # /via (.*?) on/
  # /at [\+A-Z*?] on/ (with case match)
  # /at (a-z*?) on/ (without case match)
  # /netbanking/
  def self.get_merchant_id_from_raw_expense(messageContent)
    merchant_1 = /via (.*?) on/
    merchant_2 = / at ([A-Za-z0-9\+&\(\)\-,*_ ]*?)(( on)|( txn)|\.)/
    merchant_3 = / at ([a-z ]*?) on/

    (1..3).each { |i|
      merchant_num = eval('merchant_'+i.to_s)
      regexMatch = merchant_num.match(messageContent)
      if not regexMatch.nil?
        return regexMatch[1]
      end
    }
    return nil
  end

  def self.get_merchant_id(merchantRegexMatch)
    @@merchantList.each { |merchantId, merchantAliases|
      merchantAliases.each { |merchantAlias|
        if (merchantRegexMatch.downcase.include?(merchantAlias))
          return merchantId
        end
      }
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
    money_0 = /((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+)/
    money_1 = /for ((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+).*debit/
    money_2 = /debit.*for ((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+)/
    money_3 = /((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+) was withdrawn/
    money_4 = /((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+) was spent/
    money_5 = /((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+) is debited/
    money_6 = /transaction of ((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+) has been made/
    money_7 = /((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+) withdrawn/
    money_8 = /((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+) has been debited/
    money_9 = /for a purchase worth ((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+)/
    money_10 = /for ((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+)/
    money_11 = /((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+) .*cash withdrawal/
    money_12 = /cash withdrawal of ((inr)|(r(upee)?s))[\. ]? ?([0-9\.,]+)/

    (1..12).each { |i|
      money_num = eval('money_'+i.to_s)
      regexMatch = money_num.match(messageContentDc)
      if not regexMatch.nil?
        return regexMatch[5]
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