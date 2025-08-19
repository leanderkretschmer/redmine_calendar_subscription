require_dependency 'application_controller'

module CalendarSubscription
  module ApplicationControllerPatch
    extend ActiveSupport::Concern

    # enable rss key auth also for ics format
    def find_current_user
      result = super
      return result if result
      if params[:format] == 'ics' && request.get?
        if params[:key]
          return User.find_by_rss_key(params[:key])
        end
        user = nil
        authenticate_with_http_basic do |login, password|
          user = User.try_to_login(login, password)
        end
        return user if user
      end
    end
  end
end

ApplicationController.prepend(CalendarSubscription::ApplicationControllerPatch)
