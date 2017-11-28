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
          if params[:include_page_title_fields]
            [:slug, :title, :breadcrumb].each do |attr|
              to_replace.send("#{attr}=", to_replace.send(attr).gsub(srch, params[:replace]))
            end
          end
          to_replace.parts.each do |page_part|
            if params[:include_page_part_contents]
              page_part.content = page_part.content.gsub(srch, params[:replace])
            end
            if params[:include_page_part_names]
              page_part.name = page_part.name.gsub(srch, params[:replace])
            end
          end
          to_replace.fields.each do |field|
            if params[:include_page_field_contents]
              field.content = field.content.gsub(srch, params[:replace])
            end
            if params[:include_page_field_names]
              field.name = field.name.gsub(srch, params[:replace])
            end
          end
          to_replace.save
        elsif class_name == 'snippet'
          if params[:include_snippet_contents]
            to_replace.content = to_replace.content.gsub(srch, params[:replace])
          end
          if params[:include_snippet_names]
            to_replace.name = to_replace.name.gsub(srch, params[:replace])
          end
          to_replace.save
        else
          if params[:include_layout_contents]
            to_replace.content = to_replace.content.gsub(srch, params[:replace])
          end
          if params[:include_layout_names]
            to_replace.name = to_replace.name.gsub(srch, params[:replace])
          end
          to_replace.save
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
      cols = []
      cols += %w(pages.slug pages.breadcrumb pages.title) if params[:include_page_title_fields]
      cols << "page_parts.content" if params[:include_page_part_contents]
      cols << "page_parts.name" if params[:include_page_part_names]
      cols << "page_fields.content" if params[:include_page_field_contents]
      cols << "page_fields.name" if params[:include_page_field_names]

      # Is not [page, ...] but [[page, boolean], ...] to mark dangerous matches
      conditions = cols.map{|c| "#{c} #{like} ?"}.join(' OR ')
      @page_results = if cols.size > 0
        Page.find(:all, :include => includes, :conditions => [conditions, [match]* cols.size].flatten).map{|page| [page, pages_with_matching_slug.include?(page)]}
      else
        []
      end
      
      snippet_cols = []
      snippet_cols << "content" if params[:include_snippet_contents]
      snippet_cols << "name" if params[:include_snippet_names]
      @snippet_results = if snippet_cols.size > 0
        Snippet.find(:all, :conditions => [snippet_cols.map{|c| "#{c} #{like} ?"}.join(' OR '), [match]*snippet_cols.size])
      else
        []
      end
      
      layout_cols = []
      layout_cols << "content" if params[:include_layout_contents]
      layout_cols << "name" if params[:include_layout_names]
      @layout_results = if layout_cols.size > 0
        Layout.find(:all, :conditions => [layout_cols.map{|c| "#{c} #{like} ?"}.join(' OR '), [match]*layout_cols.size])
      else
        []
      end
    end
    
  end
    
  private
  
  def match
    qry = params[:regex_mode] ? params[:query] : "%#{params[:query]}%"
    params[:case_insensitive] ? qry.downcase : qry
  end
end