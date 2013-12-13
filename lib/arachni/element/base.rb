=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Element

module Capabilities
end

# load and include all available capabilities
lib = File.dirname( __FILE__ ) + '/capabilities/*.rb'
Dir.glob( lib ).each { |f| require f }

# Base class for all element types.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Base
    include Utilities
    extend Utilities

    def initialize( options )
        options = options.symbolize_keys( false )

        if !(options[:url] || options[:action])
            fail 'Needs :url or :action option.'
        end

        @initialised_options = options.deep_clone

        self.url = options[:url] || options[:action]
    end

    # @return  [Element::Base] Reset the element to its original state.
    # @abstract
    def reset
        self
    end

    # @return  [String] String uniquely identifying self.
    # @abstract
    def id
        "#{action}:#{method}:#{inputs}"
    end

    # @return   [Hash] Simple representation of self.
    def to_h
        {
            type: type,
            url:  url
        }
    end

    # @return  [String]
    #   URL of the page that owns the element.
    def url
        @url.freeze
    end

    # @see #url
    def url=( url )
        @url = normalize_url( url )
    end

    # @return [Symbol]  Element type.
    def type
        self.class.type
    end

    # @return [Symbol]  Element type.
    def self.type
        name.split( ':' ).last.downcase.to_sym
    end

    def dup
        self.class.new @initialised_options
    end

end
end
end
