Rails.application.routes.draw do
  get 'expense/get_expenses_by_month'

  get 'expense/get_expenses_for_services'

  get 'expense/get_days_expenses'

  post 'expense/upload_expenses_raw'

  get 'user/signup'

  get 'user/signin'

  get 'user/otp_verification'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
