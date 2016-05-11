class Admin::SearchController < ApplicationController
  
  def results
    if params[:doReplace]
      params.select{|k, v| k =~ /(page|snippet|layout)_(\d)/ }.map do |k,v| 
        class_name, id = k.to_s.split('_')
        to_replace = class_name.titlecase.constantize.find(id)
        srch = Regexp.new(params[:query], params[:case_insensitive])
        
        if class_name == 'page'
          Page.find(id).parts.each do |page_part|
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

      @page_results = Page.find(:all, :include => [ :parts ], :conditions => ["page_parts.content #{like} ? ", match])
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