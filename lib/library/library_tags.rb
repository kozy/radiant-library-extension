module Library
  module LibraryTags
    include Radiant::Taggable
  
    class TagError < StandardError; end

    ############### tags for use on library pages
                  # usually to build a faceted browser

    tag "library" do |tag|
      raise TagError, "library:* tags can only be used on a LibraryPage" unless tag.locals.page && tag.locals.page.is_a?(LibraryPage)
      tag.expand
    end

    desc %{
      Displays a list of the tags that can be used to narrow the set of results displayed. This begins as a list of 
      all available tags, and as they are chosen it shrinks to show only the coincident tags that will further reduce the set.
      
      This is normally used to display a list or cloud of facets that can be added to a search. The default is to show a cloud.
      
      <pre><code>
        <r:library:tags:each><li><r:tag:link /></li></r:library:tags:each>
        <r:library:tags:list />
        <r:library:tags:cloud />
        <r:library:tags />
      </code></pre>

      To show only those tags attached to a particular kind of object, supply a 'for' parameter. 
      The parameter can be 'pages', 'assets' or the plural of any asset type. If you're displaying an image gallery,
      you may want to start with a cloud of all the tags that have been applied to images:
      
      <pre><code>
        <r:library:tags for="images" />
      </code></pre>
      
      You can still display pages associated with those tags, but the list will not include tags that only have pages.
    }
    tag "library:tags" do |tag|
      tag.locals.tags = _get_coincident_tags(tag)
      if tag.double?
        tag.expand
      else
        tag.render('tags:cloud', tag.attr.dup)
      end
    end
    tag "library:tags:each" do |tag|
      tag.render('tags:each', tag.attr.dup, &tag.block)
    end
    tag "library:tags:list" do |tag|
      tag.render('tags:list', tag.attr.dup)
    end
    tag "library:tags:cloud" do |tag|
      tag.render('tags:cloud', tag.attr.dup)
    end
    
    desc %{
      Expands if there are is more than one tag to show. 
      
      *Usage:* 
      <pre><code>
        <r:library:if_tags>
          Displaying items tagged with all of <r:requested_tags />
        <r:library:if_tags>
      </code></pre>
    }
    tag "library:if_tags" do |tag|
      tag.locals.tags = _get_coincident_tags(tag)
      tag.expand if tag.locals.tags.length > 1
    end
    desc %{
      Expands if are is one or no tag to show. 
      
      *Usage:* 
      <pre><code>
        <r:library:unless_tags>That's your lot.</r:library:unless_tags>
      </code></pre>
    }
    tag "library:unless_tags" do |tag|
      tag.locals.tags = _get_coincident_tags(tag)
      tag.expand if tag.locals.tags.length > 1
    end
        
    desc %{
      Displays a list of the tags requested by the user.
      To offer links that remove the tag from the current set, these will both work:
      
      *Usage:* 
      <pre><code>
        <r:library:requested_tags:each><li><r:tag:unlink /></li></r:library:requested_tags:each>
        <r:library:requested_tags />
      </code></pre>
    }
    tag "library:requested_tags" do |tag|
      tag.locals.tags = _get_requested_tags(tag)
      if tag.double?
        tag.expand
      else
        tag.render('tags:unlink_list', tag.attr.dup)
      end
    end
    tag "library:requested_tags:each" do |tag|
      tag.render('tags:each', tag.attr.dup, &tag.block)
    end

    desc %{
      Expands if any tags have been specified:
      
      *Usage:* 
      <pre><code>
        <r:library:if_requested_tags>
          Displaying items tagged with all of <r:requested_tags />
        <r:library:if_requested_tags>
      </code></pre>
    }
    tag "library:if_requested_tags" do |tag|
      tag.locals.tags = _get_requested_tags(tag)
      tag.expand if tag.locals.tags.any?
    end
    
    desc %{
      Expands if no tags have been specified:
      
      *Usage:* 
      <pre><code>
        <r:library:unless_requested_tags>
          Showing everything. Choose a tag to start narrowing down the list.
        <r:library:unless_requested_tags>
      </code></pre>
    }
    tag "library:unless_requested_tags" do |tag|
      tag.expand unless _get_requested_tags(tag).any?
    end

    desc %{
      Displays a list of the pages associated with the current tag set. If no tags are specified, this will show all pages.
      You can use all the usual r:page tags within the list.
      
      :by, :order, :limit, :offset, :status and all the usual list-control attributes are obeyed.
      
      To paginate the list, set paginated="true" and, optionally, per_page="xx".
      
      *Usage:* 
      <pre><code>
        <r:library:pages:each><li><r:link /><br /><r:content part="description" /></li></r:library:pages:each>
      </code></pre>
    }
    tag "library:pages" do |tag|
      # tag.locals.pages = _get_pages(tag)
      tag.expand
    end
    tag "library:pages:each" do |tag|
      displayed_children = tag.locals.pages = _get_pages(tag)
      result = tag.render('page_list', tag.attr.dup, &tag.block)       # r:page_list is defined in taggable
      
      if tag.attr.symbolize_keys[:paginated] == 'true' && displayed_children.total_pages > 1
        tag.locals.paginated_list = displayed_children
        result << tag.render('pagination_with_tags', tag.attr.dup)
      end
      result
      
    end

    desc %{
      Expands if there are any pages associated with all of the current tag set.
      
      *Usage:* 
      <pre><code>
        <r:library:if_pages><h2>Pages</h2>...</r:library:if_pages>
      </code></pre>
    }
    tag "library:if_pages" do |tag|
      tag.expand if _get_pages(tag).any?
    end

    # desc %{
    #   Displays a list of the assets associated with the current tag set. If no tags are specified, this will show all assets.
    #   You can use all the usual r:assets tags within the list.
      
    #   By, order, limit and offset attributes are obeyed. The default is to sort by creation date, descending.
      
    #   To paginate the list, set paginated="true" and, optionally, per_page="xx".
      
    #   *Usage:* 
    #   <pre><code>
    #     <r:library:assets:each><li><r:assets:thumbnail /></li></r:library:assets:each>
    #   </code></pre>
    # }
    # tag "library:assets" do |tag|
    #   tag.locals.assets = _get_assets(tag)
    #   tag.expand
    # end
    tag "library:assets:each" do |tag|
      tag.render('asset_list', tag.attr.dup, &tag.block)       # r:page_list is defined in spanner's paperclipped
    end

    desc %{
      Expands if there are any assets associated with all of the current tag set.
      
      *Usage:* 
      <pre><code>
        <r:library:if_assets><h2>Assets</h2>...</r:library:if_assets>
      </code></pre>
    }
    tag "library:if_assets" do |tag|
      tag.expand if _get_assets(tag).any?
    end

    Asset.known_types.each do |type|
      these = type.to_s.pluralize
      
      desc %{
        Displays a list of the all the #{these} associated with the current tag set. If no tags are specified, this will show all such assets.
        You can use all the usual r:assets tags within the list.

        *Usage:* 
        <pre><code>
          <r:library:#{these}:each><li><r:assets:link /></li></r:library:#{these}:each>
        </code></pre>
      }
      tag "library:#{these}" do |tag|
        tag.locals.assets = _get_assets(tag).send(these.intern)
        tag.expand
      end
      tag "library:#{these}:each" do |tag|
        tag.render('asset_list', tag.attr.dup, &tag.block)
      end

      desc %{
        Expands if there are any #{these} associated with all of the current tag set.

        *Usage:* 
        <pre><code>
          <r:library:if_#{these}><h2>#{these.titlecase}</h2>...</r:library:if_#{these}>
        </code></pre>
      }
      tag "library:if_#{these}" do |tag|
        tag.locals.assets = _get_assets(tag).send(these.intern)
        tag.expand if tag.locals.assets.any?
      end
      
      desc %{
        The pagination tag is not usually called directly. Supply paginated="true" when you display a list and it will
        be automatically display only the current page of results, with pagination controls at the bottom.

        *Usage:*

        <pre><code><r:children:each paginated="true" per_page="50" container="false" previous_label="foo" next_label="bar">
          <r:child>...</r:child>
        </r:children:each>
        </code></pre>
      }
      tag 'pagination_with_tags' do |tag|
        if tag.locals.paginated_list
          will_paginate(tag.locals.paginated_list, will_paginate_options_with_tags(tag))
        end
      end

      private
      
        def will_paginate_options_with_tags(tag)
          attr = tag.attr.symbolize_keys
          if attr[:paginated] == 'true'
            attr.slice(:class, :previous_label, :next_label, :inner_window, :outer_window, :separator, :per_page).merge({:renderer => Radiant::Pagination::LinkRenderer.new(tag.globals.page.url_with_tags)})
          else
            {}
          end
        end

        def _get_requested_tags(tag)
          tag.locals.page.requested_tags
        end

        def _get_coincident_tags(tag)
          requested = _get_requested_tags(tag)
          limit = tag.attr['limit'] || 50
          if requested.any?
            Tag.coincident_with(requested)
          else
            Tag.most_popular(limit)
          end
        end
      end

      # a bit of extra logic so that in the absence of any requested tags we default to all, not none
      
      def _default_library_find_options
        {
          :by => 'created_at',
          :order => 'desc'
        }
      end
      
      def _get_pages(tag)        
        options = children_find_options(tag)
        paging = pagination_find_options(tag)
        
        requested = _get_requested_tags(tag)
                
        pages = Page.scoped(options)
        pages = pages.tagged_with(requested) if requested.any?
        pages = pages.paginate(options.merge(paging)) if paging
        pages
      end

      def _get_assets(tag)
        options = asset_find_options(tag)
        requested = _get_requested_tags(tag)
        assets = Asset.scoped(options)
        assets = assets.tagged_with(requested) if requested.any?
        assets
      end
      
      # duplicate of children_find_options except:
      # no virtual or status options
      # defaults to chronological descending
      
      def asset_find_options(tag)
        attr = tag.attr.symbolize_keys

        options = {}

        [:limit, :offset].each do |symbol|
          if number = attr[symbol]
            if number =~ /^\d{1,4}$/
              options[symbol] = number.to_i
            else
              raise TagError.new("`#{symbol}' attribute of `each' tag must be a positive number between 1 and 4 digits")
            end
          end
        end

        by = (attr[:by] || 'created_at').strip
        order = (attr[:order] || 'desc').strip
        order_string = ''
        if self.attributes.keys.include?(by)
          order_string << by
        else
          raise TagError.new("`by' attribute of `each' tag must be set to a valid field name")
        end
        if order =~ /^(asc|desc)$/i
          order_string << " #{$1.upcase}"
        else
          raise TagError.new(%{`order' attribute of `each' tag must be set to either "asc" or "desc"})
        end
        options[:order] = order_string
        
        # TODO: refactor to expansion from r:find
        if child_page = attr[:child_page]
          options[:conditions] = { :parent_id => Page.find_by_slug(child_page).id }
        end
        options
      end

    end

end
