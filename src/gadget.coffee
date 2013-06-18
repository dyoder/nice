{include,Property} = require "fairmont"
{EventChannel} = require "mutual"
EventedData = require "./evented-data"

# Convert title-case to corset-case
convert = (s) -> s.replace(/^([A-Z])/, (c) -> c.toLowerCase()).replace(/([A-Z])/g, (c) -> "-" + c.toLowerCase())

# Convert a class name (ex: ArticleSummary) into a CSS class name ("article-summary")
cname = (self) -> convert( self.constructor.name )

module.exports = class Gadget
  
  include @, Property
  
  constructor: (@name) ->
    @decorators = []
    @events = new EventChannel
  
  # Find a DOM node within $ to bind to, if possible, otherwise
  # render - useful when you don't know if the content was pre-
  # rendered or not
  activate: (container) ->
    unless @$?
      candidates = container.find( ".#{cname(@)}" ).not( "[name]" )
      if candidates.length > 0
        @bind $(candidates[0])
      else
        @render container
    else
      container.append @$
    @
    
  # Bind to DOM element in the case where the component is already rendered.
  # This will also ::decorate the associated DOM tree.
  bind: (@$) ->
    @decorate()
    @$.attr("name", @name)
    @

  # Render the HTML, appending to a given dom element. This will also 
  # ::decorate the DOM tree.
  render: (container) ->
    @$ = $( @html )
    @decorate()
    container.append @$
    @
    
  @property renderer: 
    get: -> @_html ?= new @constructor.HTML( @data )
    
  @property html:
    get: -> @renderer.render => @renderer.main()
    
  # Add all the event handlers associated with this component.
  decorate: ->
    decorator( @ ) for decorator in @decorators  
    @
    
  decorator: (fn) ->
    @decorators.push fn
    
  # TODO: this is super-simplistic right now. we should handle
  # more data types and allow for custom render functions, too.
  dataDecorator: =>
    # map all the named DOM elements to the @data property
    for el in @$.find("[name]")
      do (el=$(el)) =>

        el.prop("disabled", true)

        name = el.attr("name")

        type = el.data("type")
        type ?= "string"   
        switch type

          when "string"
            update = (value) -> 
              if el.prop("tagName") in ["INPUT","TEXTAREA"]
                switch el.prop("type")
                  when "checkbox"
                    el.prop("checked", value )
                  else
                    el.val( value ) if el.val() != value
              else
                el.text( value )
            @events.on "data.refresh", => 
              el.prop( "disabled",false )
              update( @data.$get( name ) )
            @events.on "data.#{name}.change", update
            el.change => 
              switch el.prop("type")
                when "checkbox"
                  @data.$set( name, el.prop("checked") )
                else
                  @data.$set( name, el.val()  )
              false
        
          when "array"
            update = (value) -> 
              if el.prop("tagName") in ["INPUT","TEXTAREA"]
                el.val( value ) if el.val() != value
              else
                el.text( value )
            @events.on "data.refresh", => 
              el.prop( "disabled",false )
              update( @data.$get( name ).join(", ") )
            @events.on "data.#{name}.change", update
            el.change => 
              value = el.val().split(",")
              value = (item.trim() for item in value)
              @data.$set( name, value )
              false
          
        
  detach: ->
    @$.detach()
    @
    
  # Get/set the data element, converting to/from EventedData.
   
  @property data:
  
    get: -> @_data
  
    set: (data) -> @_data = new EventedData( data, @events.source( "data" ) )

  # Get/set the html property, rendering it anew if necessary.
  # Should be defined in the descendent classes.
  #
  # @property html:  
  # 
  #   get: ->
  # 
  #   set: (data) ->
  #
  
  # Iterate through all the child components, execution an action
  # for each one.
  each: (action) ->
  
  
  
  