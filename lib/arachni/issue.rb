=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.dir['lib'] + 'issue/severity'

# Represents a detected issue.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Issue

    # Attributes removed from a parent issue (i.e. an issues with variations)
    # and solely populating variations.
    VARIATION_ATTRIBUTES = Set.new([
        :@response, :@proof, :@signature, :@remarks, :@trusted
    ])

    # @return    [String]   The name of the issue.
    attr_accessor :name

    # @return    [String]   Brief description of the issue.
    attr_accessor :description

    # @return    [String]
    #   A brief text informing the user how to remedy the Issue.
    attr_accessor :remedy_guidance

    # @return    [String]
    #   A code snippet showing the user how to remedy the Issue.
    attr_accessor :remedy_code

    # @return    [String]   Severity of the issue.
    # @see Severity
    attr_accessor :severity

    # @return [Array<String>]   Tags categorizing the issue.
    attr_accessor :tags

    # @return    [Hash]     References related to the issue.
    attr_accessor :references

    # @return    [String]   The CWE ID number of the issue.
    # @see http://cwe.mitre.org/
    attr_accessor :cwe

    # @return    [Symbol]   Name of the vulnerable platform.
    # @see Platform::Manager
    attr_accessor :platform_name

    # @return    [Symbol]   Type of the vulnerable platform.
    # @see Platform::Manager
    attr_accessor :platform_type

    # @return    [Element::Base, Page, nil]
    #   Instance of the relevant vector if available.
    attr_accessor :vector

    # @return   [HTTP::Response]
    attr_accessor :response

    # @return   [Hash]  Information regarding the check that logged the issue.
    attr_accessor :check

    # @return    [String]   The signature that identified the issue.
    attr_accessor :signature

    # @return    [String]   Data that was matched by the {#signature}.
    attr_accessor :proof

    # @return   [Bool]
    #   `true` if the issue can be trusted (doesn't require manual verification),
    #   `false` otherwise.
    attr_accessor :trusted

    # @return [Hash]
    #   Remarks about the issue. Key is the name of the entity which
    #   made the remark, value is an `Array` of remarks.
    attr_accessor :remarks

    # @return   [Array<Issue>]  Variations of this issue.
    attr_accessor :variations

    def self.sort( issues )
        issues.sort_by { |i| i.severity }.reverse
    end

    # @param    [Hash]    options
    #   Configuration hash holding instance attributes.
    def initialize( options = {} )
        # Make sure we're dealing with UTF-8 data.
        options = options.recode

        options.each do |k, v|
            send( "#{k.to_s.downcase}=", v )
        end

        fail ArgumentError, 'Missing :vector' if !@vector

        @remarks    ||= {}
        @trusted      = true if @trusted.nil?
        @references ||= {}
        @tags       ||= []
        @variations ||= []
        @variation    = nil
    end

    # @return   [HTTP::Request]
    def request
        return if !response
        response.request
    end

    def vector=( vector )
        vector = vector.dup
        vector.remove_auditor
        @vector = vector
    end

    # Adds a remark as a heads-up to the end user.
    #
    # @param    [String, Symbol]    author  Component which made the remark.
    # @param    [String]    string  Remark.
    def add_remark( author, string )
        fail ArgumentError, 'Author cannot be blank.' if author.to_s.empty?
        fail ArgumentError, 'String cannot be blank.' if string.to_s.empty?

        (@remarks[author] ||= []) << string
    end

    # @return   [Boolean]
    #   `true` if the issue was discovered by manipulating an input,
    #   `false` otherwise.
    #
    # @see recon?
    def active?
        !!(vector.respond_to?( :affected_input_name ) && vector.affected_input_name)
    end

    # @return   [Boolean]
    #   `true` if the issue was discovered passively, `false` otherwise.
    #
    # @see audit?
    def passive?
        !active?
    end

    # @return   [Bool]
    #   `true` if the issue can be trusted (doesn't require manual verification),
    #   `false` otherwise.
    #
    # @see #requires_verification?
    def trusted?
        !!@trusted
    end

    # @see #trusted?
    def untrusted?
        !trusted?
    end

    # @private
    def cwe=( id )
        id = id.to_i
        return if id == 0
        @cwe = id
    end

    # @return   [String]    {#cwe CWE} reference URL.
    def cwe_url
        return if !cwe
        @cwe_url ||= "http://cwe.mitre.org/data/definitions/#{cwe}.html"
    end

    # @private
    def references=( refs )
        @references = refs || {}
    end

    # @private
    def signature=( signature )
        return if !signature
        @signature = signature.to_s
    end

    # @return   [Hash]
    def to_h
        h = {}

        self.instance_variables.each do |var|
            h[normalize_name( var )] = try_dup( instance_variable_get( var ) )
        end

        h[:vector] = vector.to_h
        h.delete( :unique_id )

        if solo?
            h.delete( :variation )
        else
            h[:vector].delete :default_inputs

            if variation?
                h[:vector].delete :type
                h[:vector].delete :url
                h[:vector].delete :action
            end
        end

        if !variation? || solo?
            h[:digest]   = digest
            h[:severity] = severity.to_sym
            h[:cwe_url]  = cwe_url if cwe_url

            # Since we're doing the whole cross-platform hash thing better switch
            # the Element classes in the check's info data to symbols.
            h[:check][:elements] ||= []
            h[:check][:elements]   = h[:check][:elements].map(&:type)

            h[:variations] = @variations.map(&:to_h)
        end

        if variation? || solo?
            h[:response] = response.to_h if response
            h[:request]  = request.to_h  if request
        end

        h
    end
    alias :to_hash :to_h

    # @return   [String]    A string uniquely identifying this issue.
    def unique_id
        return @unique_id if @unique_id
        vector_info = active? ? "#{vector.method}:#{vector.affected_input_name}:" : nil
        "#{name}:#{vector_info}#{vector.action.split( '?' ).first}"
    end

    # @return   [Integer]
    #   An Integer hash uniquely identifying this issue.
    #
    # @see #unique_id
    def digest
        unique_id.persistent_hash
    end

    # @return   [Bool]
    #   `true` if the issue neither has nor is a variation, `false` otherwise.
    def solo?
        @variation.nil?
    end

    # @return   [Bool] `true` if `self` is a variation.
    def variation?
        !!@variation
    end

    # @return   [Issue]
    #   A copy of `self` **without** {VARIATION_ATTRIBUTES specific} details
    #   and an empty array of {#variations} to be populated.
    #
    #   Also, the {#vector} attribute will hold the original, non-mutated vector.
    def with_variations
        issue = self.deep_clone

        instance_variables.each do |k|
            next if k == :@trusted || !VARIATION_ATTRIBUTES.include?( k ) ||
                !issue.instance_variable_defined?( k )

            issue.remove_instance_variable k
        end

        issue.vector.reset

        issue.unique_id = unique_id
        issue.variation = false
        issue
    end

    # @return   [Issue]
    #   A copy of `self` with {VARIATION_ATTRIBUTES specific} details **only**
    #   and the mutated {#vector}.
    def as_variation
        issue = self.deep_clone

        instance_variables.each do |k|
            next if k == :@vector || VARIATION_ATTRIBUTES.include?( k ) ||
                !issue.instance_variable_defined?( k )

            issue.remove_instance_variable k
        end

        issue.unique_id = unique_id
        issue.variation = true
        issue
    end

    # Converts `self` to a solo issue, in place.
    #
    # @param    [Issue] issue   Parent issue.
    # @return   [Issue]
    #   Solo issue, with generic vulnerability data filled in from `issue`.
    def to_solo!( issue )
        issue.instance_variables.each do |k|
            next if k == :@variations || k == :@vector
            next if (val = issue.instance_variable_get(k)).nil?
            instance_variable_set( k, issue.instance_variable_get( k ) )
        end

        @variations = []
        @variation  = nil

        self
    end

    # Copy of `self` as a solo issue.
    #
    # @param    [Issue] issue   Parent issue.
    # @return   [Issue]
    #   Solo issue, with generic vulnerability data filled in from `issue`.
    def to_solo( issue )
        deep_clone.to_solo!( issue )
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        unique_id.hash
    end

    def eql?( other )
        hash == other.hash
    end

    protected

    def unique_id=( id )
        @unique_id = id
    end

    def variation=( bool )
        @variation = bool
    end

    private

    def normalize_name( name )
        name.to_s.gsub( /@/, '' ).to_sym
    end

    def try_dup( obj )
        obj.dup rescue obj
    end

    protected :remove_instance_variable
end
end

Arachni::Severity = Arachni::Issue::Severity
