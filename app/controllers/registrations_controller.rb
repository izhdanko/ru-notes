class RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  def edit
    @regions = Region.all
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:full_name, :username, :region_id, :email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:full_name, :username, :region_id, :email])
  end

end
