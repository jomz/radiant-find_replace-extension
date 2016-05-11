# Uncomment this if you reference any of your controllers in activate
# require_dependency "application_controller"
require "radiant-find_replace-extension"

class FindReplaceExtension < Radiant::Extension
  version     RadiantFindReplaceExtension::VERSION
  description RadiantFindReplaceExtension::DESCRIPTION
  url         RadiantFindReplaceExtension::URL

  # See your config/routes.rb file in this extension to define custom routes

  extension_config do |config|
    # config is the Radiant.configuration object
  end

  def activate
    # tab 'Content' do
    #   add_item "Find Replace", "/admin/find_replace", :after => "Pages"
    # end
  end
end
