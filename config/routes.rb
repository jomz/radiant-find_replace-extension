ActionController::Routing::Routes.draw do |map|
  map.namespace :admin do |admin|
    admin.search 'search', :controller => :search, :action => :results
  end
  # map.namespace :admin, :member => { :remove => :get } do |admin|
  #   admin.resources :find_replace
  # end
end