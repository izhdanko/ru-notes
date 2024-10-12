class UsersController < ApplicationController
  before_action :authenticate_user!, :set_user, only: [:destroy]

  def index
    if current_user.admin?
      @search = User.ransack(params[:q])
      @users = @search.result(distinct: true).order(:id)
    else
      redirect_to root_path, alert: 'Доступ запрещен. Только администраторы могут просматривать все заметки.'
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
    available_regions
  end

  def update
    @user = User.find(params[:id])

    if current_user.admin? || @user == current_user
      if @user.update(user_params)
        redirect_to @user, notice: 'Пользователь был успешно обновлён.'
      else
        render :edit
      end
    else
      redirect_to root_path, alert: 'У вас нет прав для обновления этого пользователя.'
    end
  end

  def destroy
    if @user
      @user.destroy
      redirect_to users_url, notice: 'Пользователь был успешно удалён.'
    else
      redirect_to users_url, alert: 'Пользователь не найден.'
    end
  end

  def available_regions
    if current_user.admin?
      @regions = nil  # Для администратора возвращается nil.
    else
      @regions = Region.all  # Для обычных пользователей возвращается весь список регионов.
    end
  end

  def new
    @user = User.new
    available_regions
  end

  def promote_to_admin
    user = User.find(params[:id])
    user.update(admin: true)
    redirect_to users_path
  end

  def demote_from_admin
    user = User.find(params[:id])
    user.update(admin: false)
    redirect_to users_path
  end


  private

  # Допустимый список параметров для безопасной массовой загрузки.
  def user_params
    params.require(:user).permit(:email, :full_name, :username, :region_id, :password, :password_confirmation)
  end

  def set_user
    @user = User.find_by(id: params[:id])
  end

end
