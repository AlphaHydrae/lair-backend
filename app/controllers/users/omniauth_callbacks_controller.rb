class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def google_oauth2

    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user)
    return render text: 'bar'

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.google_data"] = request.env["omniauth.auth"]
      #redirect_to new_user_registration_url
      render text: 'foo'
    end
  end

  def new_session_path *args 
    #new_user_session_path *args
    #'/users/sign_in'
    root_path
  end
end
