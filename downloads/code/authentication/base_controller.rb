# encoding: utf-8
class Admin::BaseController < ActionController::Base
  include AuthenticateUser
  protect_from_forgery with: :exception
  before_filter :require_login

  protected
  def require_login
    return true if user_signed_in?
    redirect_to root_path
  end
end
