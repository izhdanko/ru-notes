class MainController < ApplicationController

  def index
    @search = Post.where(status: :approved).ransack(params[:q])
    @approved_posts = @search.result(distinct: true).order(created_at: :asc)
  end

end
