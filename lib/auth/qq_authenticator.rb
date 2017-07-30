class QQAuthenticator < ::Auth::Authenticator
  AUTHENTICATOR_NAME = 'qq'.freeze

  def name
    AUTHENTICATOR_NAME
  end

  def after_authenticate(auth_token)
    Rails.logger.info auth_token
    result = Auth::Result.new

    data = auth_token[:info]
    raw_info = auth_token[:extra][:raw_info]
    name = data['nickname']
    username = data['name']
    qq_uid = auth_token[:uid]

    current_info = ::PluginStore.get(AUTHENTICATOR_NAME, "qq_uid_#{qq_uid}")

    if current_info
      result.user = User.where(id: current_info[:user_id]).first
    else
      current_info = Hash.new
    end
    current_info.store(:raw_info, raw_info)
    ::PluginStore.set(AUTHENTICATOR_NAME, "qq_uid_#{qq_uid}", current_info)

    result.name = name
    result.username = username
    result.extra_data = { qq_uid: qq_uid }

    result
  end

  def after_create_account(user, auth)
    qq_uid = auth[:extra_data][:qq_uid]
    current_info = ::PluginStore.get(AUTHENTICATOR_NAME, "qq_uid_#{qq_uid}") || {}
    ::PluginStore.set(AUTHENTICATOR_NAME, "qq_uid_#{qq_uid}", current_info.merge({user_id: user.id}))
  end

  def register_middleware(omniauth)
    omniauth.provider :qq, :setup => lambda { |env|
      strategy = env['omniauth.strategy']
      strategy.options[:client_id] = SiteSetting.zh_l10n_qq_client_id
      strategy.options[:client_secret] = SiteSetting.zh_l10n_qq_client_secret
    }
  end
end

