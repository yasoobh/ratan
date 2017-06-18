require 'json'

class UserController < ApplicationController
  def signup
    mobileNumber = params[:mobile_number]
    name = params[:name]


    if (!name.nil? && !mobileNumber.nil?)
      response = {'status' => 'HTTP 200 OK'}
    else
      response = {'status' => 'HTTP 400 Bad Request'}
    end
    render :json => response.to_json
  end

  def signin
    mobileNumber = params[:mobile_number]

    if (!mobileNumber.nil?)
      response = {'status' => 'HTTP 200 OK'}
    else
      response = {'status' => 'HTTP 400 Bad Request'}
    end
    render :json => response.to_json
  end

  def otp_verification
    mobileNumber = params[:mobile_number]
    otp = params[:otp]

    if (!mobileNumber.nil? && !otp.nil?)
      response = {'status' => 'HTTP 200 OK'}
    else
      response = {'status' => 'HTTP 400 Bad Request'}
    end
    render :json => response.to_json
  end
end
