module NavigationHelpers
  
  # Extend the standard PathMatchers with your own paths
  # to be used in your features.
  # 
  # The keys and values here may be used in your standard web steps
  # Using:
  #
  #   When I go to the "find_replace" admin page
  # 
  # would direct the request to the path you provide in the value:
  # 
  #   admin_find_replace_path
  # 
  PathMatchers = {} unless defined?(PathMatchers)
  PathMatchers.merge!({
    # /find_replace/i => 'admin_find_replace_path'
  })
  
end

World(NavigationHelpers)