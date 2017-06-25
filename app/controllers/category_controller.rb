class CategoryController < ApplicationController

  def get_all_categories
    allCategories = Category.all.select(:id, :name, :icon_url)
    response = {'status' => 'success', 'responseCode' => 200, 'data' => allCategories, 'message' => 'All categories sent successfully!'}
    render :json => response.to_json
  end
end