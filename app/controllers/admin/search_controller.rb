class Admin::SearchController < ApplicationController
  only_allow_access_to :results,
    :when => [:designer, :admin],
    :denied_url => { :controller => 'admin/pages', :action => 'index' },
    :denied_message => 'You must have designer privileges to perform this action.'
  
  def results
    if params[:doReplace]
      params.select{|k, v| k =~ /(page|snippet|layout)_(\d)/ }.map do |k,v| 
        class_name, id = k.to_s.split('_')
        to_replace = class_name.titlecase.constantize.find(id)
        qry = params[:regex_mode] ? params[:query] : Regexp.quote(params[:query])
        srch = Regexp.new(qry, params[:case_insensitive])
        
        if class_name == 'page'
          [:slug, :title, :breadcrumb].each do |attr|
            to_replace.update_attribute(attr, to_replace.send(attr).gsub(srch, params[:replace]))
          end
          to_replace.parts.each do |page_part|
            page_part.update_attribute :content, page_part.content.gsub(srch, params[:replace])
          end
        else
          to_replace.update_attribute :content, to_replace.content.gsub(srch, params[:replace])
        end
      end
    end
    
    if query = params[:query]
      like = case Page.connection.adapter_name.downcase
        when 'postgresql'
          if params[:regex_mode]
            sqlike = params[:case_insensitive] ? '~*' : '~'
          else
            sqlike = params[:case_insensitive] ? "ILIKE" : "LIKE"
          end
        else
          if params[:regex_mode]
            sqlike = params[:case_insensitive] ? "REGEXP" : "REGEXP BINARY"
          else
            sqlike = params[:case_insensitive] ? "LIKE" : "LIKE BINARY"
          end
        end
      
      pages_with_matching_slug = Page.find(:all, :conditions => ["slug #{like} ?", match])
      # Is not [page, ...] but [[page, boolean], ...] to mark dangerous matches
      @page_results = Page.find(:all, :include => [ :parts ], :conditions => ["page_parts.content #{like} ? OR pages.slug #{like} ? OR pages.breadcrumb #{like} ?  OR pages.title #{like} ? ", [match]* 4].flatten).map{|page| [page, pages_with_matching_slug.include?(page)]}
      @snippet_results = Snippet.find(:all, :conditions => ["content #{like} ?", match])
      @layout_results = Layout.find(:all, :conditions => ["content #{like} ?", match])
    end
    
  end
    
  private
  
  def match
    qry = params[:regex_mode] ? params[:query] : "%#{params[:query]}%"
    params[:case_insensitive] ? qry.downcase : qry
  end
end