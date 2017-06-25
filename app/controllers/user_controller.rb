require 'json'

class UserController < ApplicationController

  def signup
    mobileNumber = params[:mobile_number]

    if (!mobileNumber.nil?)
      if User.user_already_present?(mobileNumber)
        response = {'status' => 'error', 'responseCode' => 401, 'message' => 'User already present!'}
        render :json => response.to_json and return
      end

      begin
        Otp.create_otp(mobileNumber)
        response = {'status' => 'success', 'responseCode' => 200, 'message' => 'Otp sent successfully!'}
        render :json => response.to_json and return
      rescue Exception => e
        p e
      end
    end

    response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Received empty mobile number!'}
    render :json => response.to_json and return
  end

  def signin
    mobileNumber = params[:mobile_number]

    if (!mobileNumber.nil?)
      begin
        Otp.create_otp(mobileNumber)
        response = {'status' => 'success', 'responseCode' => 200, 'message' => 'Otp sent successfully!'}
        render :json => response.to_json and return
      rescue Exception => e
        p e
      end
    end

    response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Received empty mobile number!'}
    render :json => response.to_json and return
  end

  def otp_verification
    mobileNumber = params[:mobile_number]
    otp = params[:otp]
    name = params[:name]
    deviceId = params[:device_id]

    if (!otp.nil? && !mobileNumber.nil?)
      if Otp.verify_otp(mobileNumber, otp)
        if (!name.nil? && !deviceId.nil?)
          begin
            u = User.new
            u.name = name
            u.mobile_number = mobileNumber
            u.device_id = deviceId
            u.save
            response = {'status' => 'success', 'message' => 'User verified successfully!', 'responseCode' => 200, 'data' => {'user_id' => u.id}}
            render :json => response.to_json and return
          rescue Exception => e
            p e
          end
        else
          u = User.where("mobile_number = ?", mobileNumber).take
          if not u.nil?
            response = {'status' => 'success', 'message' => 'User verified successfully!', 'responseCode' => 200, 'data' => {'user_id' => u.id}}
            render :json => response.to_json and return
          end
        end
      end
    end

    response = {'status' => 'error', 'responseCode' => 400, 'message' => 'Otp verification failed. Please try again!'}
    render :json => response.to_json and return
  end
end
