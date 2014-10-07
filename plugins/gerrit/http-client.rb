module HTTPCLIENT

  def self.get_proxy
    (ENV['HTTP_PROXY'] == nil)? ENV['http_proxy'] : ENV['HTTP_PROXY']
  end

  def self.get_proxy_uri
    proxy = self.get_proxy
    (proxy != nil)? URI.parse(proxy) : nil
  end

  def self.rest_do_get(url, raw_params, timeout, token, accept)
    data = nil
    url_srt = url
    if raw_params
      url_srt = URI.encode(url+raw_params)
    end
    uri = URI.parse(url_srt)

    if !url.include? 'localhost'
      proxy_uri = self.get_proxy_uri
    end

    req = Net::HTTP::Get.new(url_srt)
    req['accept'] = accept
    req['X-Auth-Token'] = token

    http = (proxy_uri != nil) ? Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port) : Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    http.open_timeout = timeout
    http.read_timeout = timeout
    begin
      http.start {
        http.request(req) {|res| data = res }
      }
    rescue Timeout::Error
      data = nil;
    end
    case data
      when Net::HTTPSuccess
        return data.body, data.code
      else
        data.error!
    end
  end

end
