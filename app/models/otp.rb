class Otp < ApplicationRecord
  self.table_name = 'otp'

  def self.create_otp(mobileNumber)
    otp = Otp.new
    otp.mobile_number = mobileNumber
    # otp.otp = generate_otp()
    otp.otp = '7254'
    otp.used = 0
    otp.timeout = Time.now.to_i + 600
    otp.save
  end

  def generate_otp
    r = Random.new
    r.rand(1000..9999)
  end

  def self.verify_otp(mobileNumber, otp)
    otpData = Otp.where("mobile_number = ? AND otp = ? AND used = ? AND timeout > ?", mobileNumber, otp, 0, Time.now.to_i).take
    p otpData
    (not otpData.nil?)
  end
end