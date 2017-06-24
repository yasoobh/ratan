require 'json'

class UserController < ApplicationController
  def signup
    mobileNumber = params[:mobile_number]

    if (!mobileNumber.nil?)
      response = {'status' => 'success', 'responseCode' => 200, 'message' => 'Otp sent successfully!'}
      begin

      rescue Exception => e
      end
    else
      response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Received empty mobile number!'}
    end
    render :json => response.to_json
  end

  def signin
    mobileNumber = params[:mobile_number]

    if (!mobileNumber.nil?)
      response = {'status' => 'success', 'responseCode' => 200, 'message' => 'Otp sent successfully!'}
    else
      response = {'status' => 'HTTP 400 Bad Request'}
    end
    render :json => response.to_json
  end

  def otp_verification
    name = params[:name]
    mobileNumber = params[:mobile_number]
    otp = params[:otp]

    if (!mobileNumber.nil? && !otp.nil?)
      if Otp.verify_otp(mobileNumber, otp)
        begin
          u = User.new
          if (!name.nil?)
            u.name = name
          end
          u.mobile_number = mobileNumber
          u.save
          response = {'status' => 'success', 'message' => 'User verified successfully!', 'responseCode' => 200, 'data' => {'user_id' => u.id}}
        rescue Exception => e
          p e
          response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Otp verification failed. Please try again!'}
        end
      else
        response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Otp verification failed. Please try again!'}
      end
    else
      response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Otp verification failed. Please try again!'}
    end
    render :json => response.to_json
  end
end
