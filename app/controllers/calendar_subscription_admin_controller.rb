class CalendarSubscriptionAdminController < ApplicationController

  layout 'admin'
  before_action :require_admin

  def users
    term = params[:name].to_s.strip
    scope = User.active.order(:login)
    scope = scope.where("LOWER(login) LIKE :q OR LOWER(firstname) LIKE :q OR LOWER(lastname) LIKE :q OR LOWER(mail) LIKE :q", q: "%#{term.downcase}%") if term.present?
    render json: scope.limit(50).select(:id, :login, :firstname, :lastname).map { |u| { id: u.id, login: u.login, name: u.name } }
  end

  def credentials_index
    user_ids = Array(params[:user_ids]).map(&:to_i)
    records = CalendarSubscriptionCredential.where(user_id: user_ids)
    render json: records.map { |r| { user_id: r.user_id, username: r.username, use_redmine_credentials: r.use_redmine_credentials } }
  end

  def upsert_credential
    user_id = params.require(:user_id).to_i
    attrs = {
      username: params[:username].to_s.strip,
      use_redmine_credentials: ActiveModel::Type::Boolean.new.cast(params[:use_redmine_credentials])
    }
    cred = CalendarSubscriptionCredential.find_or_initialize_by(user_id: user_id)
    cred.username = attrs[:username] if attrs[:username].present?
    cred.use_redmine_credentials = attrs[:use_redmine_credentials]
    if !cred.use_redmine_credentials && params[:password].present?
      cred.password = params[:password]
    elsif cred.use_redmine_credentials
      cred.password_digest = nil
    end
    if cred.save
      render json: { ok: true }
    else
      render json: { ok: false, errors: cred.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy_credential
    cred = CalendarSubscriptionCredential.find_by(user_id: params[:user_id].to_i)
    cred&.destroy
    render json: { ok: true }
  end
end


