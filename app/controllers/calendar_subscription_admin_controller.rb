class CalendarSubscriptionAdminController < ApplicationController

  layout 'admin'
  prepend_before_action :force_html_format
  before_action :require_admin
  before_action :find_current_user_for_api

  def index
  end

  def users
    term = (params[:name].presence || params[:q].presence || params[:term].presence || '').to_s.strip
    scope = User.active.order(:login)
    scope = scope.where("LOWER(login) LIKE :q OR LOWER(firstname) LIKE :q OR LOWER(lastname) LIKE :q OR LOWER(mail) LIKE :q", q: "%#{term.downcase}%") if term.present?
    render json: scope.limit(50).select(:id, :login, :firstname, :lastname, :mail).map { |u| { id: u.id, login: u.login, name: u.name, mail: u.mail } }
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

  def allowed_index
    settings = Setting.plugin_redmine_calendar_subscription || {}
    allowed_ids = Array(settings[:allowed_user_ids]).map(&:to_i)
    users = User.where(id: allowed_ids).map { |u| { id: u.id, name: u.name, login: u.login, mail: u.mail } }
    render json: users
  end

  def allowed_add
    user_id = params.require(:user_id).to_i
    settings = Setting.plugin_redmine_calendar_subscription || {}
    allowed = Array(settings[:allowed_user_ids]).map(&:to_i)
    unless allowed.include?(user_id)
      allowed << user_id
      settings[:allowed_user_ids] = allowed
      Setting.plugin_redmine_calendar_subscription = settings
    end
    render json: { ok: true }
  end

  def allowed_remove
    user_id = params.require(:user_id).to_i
    settings = Setting.plugin_redmine_calendar_subscription || {}
    allowed = Array(settings[:allowed_user_ids]).map(&:to_i)
    allowed.delete(user_id)
    settings[:allowed_user_ids] = allowed
    Setting.plugin_redmine_calendar_subscription = settings
    render json: { ok: true }
  end

  def user_details
    user = User.find(params[:user_id])
    cred = CalendarSubscriptionCredential.find_by(user_id: user.id)
    ics_url_rss = url_for(controller: 'calendar_subscription', action: 'show', only_path: false, key: user.rss_key, format: 'ics')
    ics_url_basic = url_for(controller: 'calendar_subscription', action: 'show', only_path: false, format: 'ics')
    render json: {
      user: { id: user.id, name: user.name, login: user.login, mail: user.mail },
      credential: cred ? { username: cred.username, use_redmine_credentials: cred.use_redmine_credentials } : nil,
      links: { ics_rss: ics_url_rss, ics_basic: ics_url_basic }
    }
  end

  private
  # Allow JSON API calls from admin UI via session or authenticity token
  def find_current_user_for_api
    return if User.current&.admin?
    # Try regular session
    return if User.current.logged?
    # Try API key in header (not required, but keep compatible)
    if request.format.json? && (token = request.headers['X-Redmine-API-Key']).present?
      user = User.find_by_api_key(token)
      User.current = user if user
    end
  end

  def force_html_format
    # Force HTML format for XHR so Redmine does not treat it as API (which would require API key)
    if request.xhr? && (request.format.json? || request.format.js?)
      request.format = :html
    end
  end
end


