class User < ApplicationRecord

  def self.user_already_present?(mobileNumber)
    u = User.find_by(mobile_number: mobileNumber)
    (not u.nil?)
  end
end