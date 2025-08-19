class CalendarSubscriptionAdminController < ApplicationController

  layout 'admin'
  before_action :require_admin

  def users
    term = params[:name].to_s.strip
    scope = User.active.order(:login)
    scope = scope.where("LOWER(login) LIKE :q OR LOWER(firstname) LIKE :q OR LOWER(lastname) LIKE :q OR LOWER(mail) LIKE :q", q: "%#{term.downcase}%") if term.present?
    render json: scope.limit(50).select(:id, :login, :firstname, :lastname).map { |u| { id: u.id, login: u.login, name: u.name } }
  end
end


