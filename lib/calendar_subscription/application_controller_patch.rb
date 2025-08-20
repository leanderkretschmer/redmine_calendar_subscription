require_dependency 'application_controller'

module CalendarSubscription
  module ApplicationControllerPatch
    extend ActiveSupport::Concern

    # enable rss key or HTTP Basic auth also for ics format
    def find_current_user
      result = super
      return result if result
      if params[:format] == 'ics' && request.get?
        if params[:key]
          token = Token.find_by(value: params[:key], action: 'feeds')
          return token&.user
        end
        authenticated_user = nil
        authenticate_with_http_basic do |login, password|
          # 1) Try plugin-specific credentials
          cred = CalendarSubscriptionCredential.find_by(username: login, use_redmine_credentials: false)
          if cred && cred.authenticate(password)
            authenticated_user = User.find_by_id(cred.user_id)
          end
          # 2) Fallback to Redmine login/password
          authenticated_user ||= User.try_to_login(login, password)
        end
        return authenticated_user if authenticated_user
      end
    end
  end
end

ApplicationController.prepend(CalendarSubscription::ApplicationControllerPatch)
