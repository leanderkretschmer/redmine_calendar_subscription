class CalendarSubscriptionAdminController < ApplicationController

  layout 'admin'
  prepend_before_action :force_html_format
  before_action :require_admin
  before_action :find_current_user_for_api

  def index
  end

  def users
    term = (params[:name].presence || params[:q].presence || params[:term].presence || '').to_s.strip
    by   = (params[:by].presence || 'name').to_s
    page = params[:page].to_i
    per  = params[:per].to_i
    page = 1 if page <= 0
    per  = 8 if per <= 0 || per > 100

    allowed_fields = %w[name login mail firstname lastname]
    by = 'name' unless allowed_fields.include?(by)

    scope = User.active
    # Join emails when needed (mail mode or full-text name mode to include email in fallback)
    if by == 'mail' || (term.present? && by == 'name')
      scope = scope.left_outer_joins(:email_addresses)
    end
    # Filtering
    if term.present?
      q = "%#{term.downcase}%"
      case by
      when 'login'
        scope = scope.where('LOWER(login) LIKE ?', q)
      when 'mail'
        scope = scope.joins(:email_addresses).where('LOWER(email_addresses.address) LIKE ?', q)
      when 'firstname'
        scope = scope.where('LOWER(firstname) LIKE ?', q)
      when 'lastname'
        scope = scope.where('LOWER(lastname) LIKE ?', q)
      else
        scope = scope.where('LOWER(users.login) LIKE :q OR LOWER(users.firstname) LIKE :q OR LOWER(users.lastname) LIKE :q OR LOWER(email_addresses.address) LIKE :q', q: q)
      end
    end

    # Sorting
    order_sql = case by
                when 'login' then 'users.login ASC'
                when 'mail' then 'email_addresses.address ASC'
                when 'firstname' then 'users.firstname ASC, users.lastname ASC'
                when 'lastname' then 'users.lastname ASC, users.firstname ASC'
                else 'users.login ASC'
                end
    scope = scope.order(order_sql)
    scope = scope.distinct

    total = scope.count
    total_pages = (total.to_f / per).ceil
    users = scope.offset((page - 1) * per).limit(per)

    render json: {
      users: users.map { |u| { id: u.id, login: u.login, name: u.name, mail: u.mail } },
      page: page,
      total_pages: total_pages,
      total: total
    }
  end

  def credentials_index
    user_ids = Array(params[:user_ids]).map(&:to_i)
    records = CalendarSubscriptionCredential.where(user_id: user_ids)
    render json: records.map { |r| { user_id: r.user_id, username: r.username, mode: r.mode, expires_at: r.expires_at, paused: r.paused } }
  end

  def upsert_credential
    user_id = params.require(:user_id).to_i
    attrs = {
      username: params[:username].to_s.strip,
      mode: params[:mode].presence || (ActiveModel::Type::Boolean.new.cast(params[:use_redmine_credentials]) ? 'redmine' : nil),
      expires_at: params[:expires_at].present? ? Time.zone.parse(params[:expires_at]) : nil,
      paused: ActiveModel::Type::Boolean.new.cast(params[:paused])
    }
    cred = CalendarSubscriptionCredential.find_or_initialize_by(user_id: user_id)
    cred.username = attrs[:username] if attrs[:username].present?
    cred.mode = attrs[:mode] if attrs[:mode].present?
    cred.expires_at = attrs[:expires_at]
    cred.paused = attrs[:paused]
    if cred.mode == 'custom' && params[:password].present?
      cred.password = params[:password]
    elsif cred.mode == 'redmine'
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
    
    # Generate a simple token for RSS access (using user's API key or generate one)
    rss_key = user.api_key || SecureRandom.hex(16)
    
    ics_url_rss = url_for(controller: 'calendar_subscription', action: 'show', only_path: false, key: rss_key, format: 'ics')
    ics_url_basic = url_for(controller: 'calendar_subscription', action: 'show', only_path: false, format: 'ics')
    render json: {
      user: { id: user.id, name: user.name, login: user.login, mail: user.mail },
      credential: cred ? { username: cred.username, mode: cred.mode, expires_at: cred.expires_at, paused: cred.paused } : nil,
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


