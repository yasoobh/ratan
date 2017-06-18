require 'json'

class ExpenseController < ApplicationController
  def get_expenses_by_month
    userId = params[:user_id]

    if (userId.nil?)
      response = {'status' => 'HTTP 400 Bad Request'}
      render :json => response.to_json and return
    end

    expensesByMonth = [
      {"month" => "Jun '17", "expense" => "22.5K"},
      {"month" => "May '17", "expense" => "38.2K"},
      {"month" => "Apr '17", "expense" => "37.9K"},
      {"month" => "Mar '17", "expense" => "42.1K"},
      {"month" => "Feb '17", "expense" => "21.6K"},
      {"month" => "Jan '17", "expense" => "38.2K"}
    ]

    render :json => expensesByMonth.to_json
  end

  def get_expenses_for_services
    userId = params[:user_id]

    if (userId.nil?)
      response = {'status' => 'HTTP 400 Bad Request'}
      render :json => response.to_json and return
    end

    expensesForServices = [
      {"service" => "Food & Drinks", "expense" => "8K"},
      {"service" => "Travel", "expense" => "12.2K"}
    ]

    render :json => expensesForServices.to_json
  end

  def get_days_expenses
    userId = params[:user_id]
    date = params[:date]
    page = params[:page]
    pageSize = params[:page_size]

    if (userId.nil? || date.nil?)
      response = {'status' => 'HTTP 400 Bad Request'}
      render :json => response.to_json and return
    end

    daysExpenses = [
      {
        "service_name" => "Uber",
        "service_type" => "Travel",
        "payment_method" => "HDFC Bank Credit Card xxxx9594",
        "expense" => "1.1K",
        "service_type_icon" => "http:\\www.url.com\travel-url"
      },
      {
        "service_name" => "Zomato",
        "service_type" => "Food",
        "payment_method" => "Kotak Bank Debit Card xxxx7449",
        "expense" => "378",
        "service_type_icon" => "http:\\www.url.com\food-url"
      }
    ]

    render :json => daysExpenses.to_json
  end

  def upload_expenses_raw
    deviceId = params[:device_id]
    expensesData = params[:expenses_data]

    if (deviceId.nil? || expensesData.nil?)
      response = {'status' => 'HTTP 400 Bad Request'}
      render :json => response.to_json and return
    end

    # expensesData = [
    #   {
    #     "sender_address" => "VKHDFC",
    #     "message_content" => "You just spent Rs. 120 at Zomato!",
    #     "message_time" => "2017-06-19 00:35:23"
    #   },
    #   {
    #     "sender_address" => "VM-PAYTM",
    #     "message_content" => "You spent Rs. 230 on Uber!",
    #     "message_time" => "2017-06-16 13:03:12"
    #   }
    # ]

    begin
      expensesData.each { |ed|
        senderAddress = ed["sender_address"]
        messageContent = ed["message_content"]
        messageTime = ed["message_time"]

        @erd = Erd.new
        @erd.sender_address = senderAddress
        @erd.message_content = messageContent
        @erd.message_time = messageTime
        @erd.device_id = deviceId
        @erd.save
      }
    rescue
      response = {'status' => 'HTTP 400 Bad Request'}
      render :json => response.to_json and return
    end

    response = {'status' => 'HTTP 200 OK'}
    render :json => response.to_json
  end
end
