require 'json'
require 'nokogiri'
require 'date'

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
