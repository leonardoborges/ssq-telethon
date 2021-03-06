class ApplicationController < ActionController::Base
  before_filter :clear_etag
  
  def clear_etag
    response.etag = nil
  end
  
  def force_cache
    response.headers['Cache-Control'] = 'public, max-age=300'
  end
  
  def force_no_cache    
    response.headers["Cache-Control"] = "private, max-age=0"
  end
  
  def redirect_to_ssl
    return unless ENV["USE_SSL"] == "true"
    return if request.ssl? && request.host == ENV["CANONICAL_HOST"]
    redirect_to url_for params.merge({:protocol => 'https://', :host => ENV["CANONICAL_HOST"]})
  end
end
