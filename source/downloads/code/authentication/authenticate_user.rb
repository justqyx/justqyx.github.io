module AuthenticateUser
  def self.included(base)
    base.helper_method :current_user, :user_signed_in?
  end

  def current_user
    @current_user ||= (session[:user_id] && User.find_by_id(session[:user_id]))
  end

  def user_signed_in?
    !!current_user
  end
end
