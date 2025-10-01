class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # Pour l'inscription
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    # Pour la mise à jour du compte
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end
end
