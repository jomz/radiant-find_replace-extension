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
            to_replace.send("#{attr}=", to_replace.send(attr).gsub(srch, params[:replace]))
          end
          to_replace.parts.each do |page_part|
            page_part.content = page_part.content.gsub(srch, params[:replace])
            page_part.name = page_part.name.gsub(srch, params[:replace]) if params[:include_field_and_part_names]
          end
          to_replace.fields.each do |field|
            field.content = field.content.gsub(srch, params[:replace])
            field.name = field.name.gsub(srch, params[:replace]) if params[:include_field_and_part_names]
          end
          page.save
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
      
      includes = [ :parts, :fields ]
      cols = %w(page_parts.content pages.slug pages.breadcrumb pages.title page_fields.content)
      cols+= %w(page_fields.name page_parts.name) if params[:include_field_and_part_names]
      # Is not [page, ...] but [[page, boolean], ...] to mark dangerous matches
      conditions = cols.map{|c| "#{c} #{like} ?"}.join(' OR ')
      @page_results = Page.find(:all, :include => includes, :conditions => [conditions, [match]* cols.size].flatten).map{|page| [page, pages_with_matching_slug.include?(page)]}
      
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