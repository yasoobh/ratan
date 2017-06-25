require 'json'
require 'nokogiri'
require 'date'

class ExpenseController < ApplicationController
  def get_expenses_by_month
    allMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec']
    userId = params[:user_id]

    if (userId.nil?)
      response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Malformed Request Parameters!'}
      render :json => response.to_json and return
    end

    userExpenses = Expense.where("user_id = ? AND transaction_time > subdate(curdate(),180) AND year(transaction_time) = 2017", userId).select("month(transaction_time)").group("month(transaction_time)").sum(:amount)
    expensesByMonth = Array.new
    userExpenses.each { |userExpense|
      month = userExpense[0]
      amount = userExpense[1].round
      expensesByMonth << {'month' => allMonths[month-1] + " '17", 'expense' => amount}
    }
    render :json => expensesByMonth.to_json
  end

  def get_expenses_for_services
    userId = params[:user_id]

    if (userId.nil?)
      response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Malformed Request Parameters!'}
      render :json => response.to_json and return
    end

    selectQuery = 'SELECT merchants.category_id, sum(expenses.amount) 
      FROM `expenses`
      LEFT JOIN merchants
        ON merchants.id = expenses.merchant_id
      WHERE (user_id = ' + userId.to_s + ' AND transaction_time > subdate(curdate(),180) AND year(transaction_time) = 2017) 
      GROUP BY merchants.category_id;'

    queryResult = ActiveRecord::Base.connection.execute(selectQuery)
 
    expensesForServices = Array.new
    queryResult.each {|row|
      categoryId = row[0]
      if not categoryId.nil?
        categoryName = Category.where(id: categoryId).take[:name]
      end
      amount = row[1].round
      expensesForServices << {'category' => categoryName, 'expense' => amount}
    }

    render :json => expensesForServices.to_json
  end

  def get_days_expenses
    userId = params[:user_id]
    date = params[:date]
    page = params[:page]
    pageSize = params[:page_size]

    if (userId.nil?)
      response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Malformed Request Parameters!'}
      render :json => response.to_json and return
    end

    dailyExpenses = Array.new
    userExpenses = Expense.where("user_id = ?", userId).order(:transaction_time).reverse_order.limit(100)
    userExpenses.each { |userExpense|
      merchantId = userExpense[:merchant_id]
      amount = userExpense[:amount]
      paymentMethodId = userExpense[:payment_method_id]
      pspId = userExpense[:payment_service_provider_id]
      transactionTime = userExpense[:transaction_time]
      cardNumberEnding = userExpense[:card_number_ending]

      if not merchantId.nil?
        merchantInfo = Merchant.where(id: merchantId).take
        merchantName = merchantInfo[:name]
        categoryId = merchantInfo[:category_id]
        categoryInfo = Category.where(id: categoryId).take
        if not categoryInfo.nil?
          categoryName = categoryInfo[:name]
        else
          categoryName = 'Others'
        end
      else
        merchantName = 'Others'
        categoryName = 'Others'
      end

      if not paymentMethodId.nil?
        paymentMethodInfo = PaymentMethod.where(id: paymentMethodId).take
        if not paymentMethodInfo.nil?
          paymentMethod = paymentMethodInfo[:name]
        end
      end

      if not pspId.nil?
        pspInfo = PaymentServiceProvider.where(id: pspId).take
        if not pspInfo.nil?
          pspName = pspInfo[:name]
        end
      end

      subtext = ""
      if not pspName.nil?
        subtext = pspName
        if not paymentMethod.nil?
          subtext += " " + paymentMethod
          if not cardNumberEnding.nil?
            subtext += " ending " + cardNumberEnding.to_s
          end
        end
      end

      dailyExpenses << {
        'merchant' => merchantName,
        'category' => categoryName,
        'expense' => amount,
        'subtext' => subtext
      }
    }
    render :json => dailyExpenses.to_json
  end

  def upload_expenses_raw
    deviceId = params[:device_id]
    expensesData = params[:expenses_data]

    if (deviceId.nil? || expensesData.nil?)
      response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Malformed request. Some parameters are missing!'}
      render :json => response.to_json and return
    end

    # deviceId = "rhythms_device_1"
    @doc = Nokogiri::XML(File.open("sagar_sms_data.xml"))
    errors = Array.new
    iter = 0
    saved = 0
    @doc.xpath('//sms').each { |sms|
      begin
        iter += 1
        messageSender = sms["address"].encode("ISO-8859-1")
        messageContent = sms["body"].encode("ISO-8859-1")
        messageTime = Date.parse(sms["readable_date"])
        messageId = sms["date"]

        erd = Erd.new
        erd.message_sender = messageSender
        erd.message_content = messageContent
        erd.message_time = messageTime
        erd.message_id = messageId
        erd.device_id = deviceId
        erd.save
        saved += 1
      rescue Exception => e
        errors << e
        errors << sms["body"]
      end
    }
    p errors

    # errors = Array.new
    # iter = 0
    # saved = 0
    # expensesData.each { |ed|
    #   iter += 1
    #   begin
    #     messageSender = ed[:message_sender]
    #     messageId = ed[:message_id]
    #     messageContent = ed[:message_content]
    #     messageTime = ed[:message_time]

    #     @erd = Erd.new
    #     @erd.device_id = deviceId
    #     @erd.message_id = messageId
    #     @erd.message_sender = messageSender
    #     @erd.message_content = messageContent
    #     @erd.message_time = messageTime
    #     @erd.save
    #     saved += 1
    #   rescue Exception => e
    #     errors << e
    #     errors << sms["body"]
    #   end
    # }
    # p errors

    percentageSaved = (saved.to_f/iter*100).round(2)
    response = {'status' => 'success', 'responseCode' => 200, 'message' => percentageSaved.to_s + '% SMSs inserted successfully!'}
    render :json => response.to_json
  end
end
