=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element
class Body < Base

    attr_accessor :auditor

    def initialize( page )
        @page = page
        super url: page.url
    end

    def action
        url
    end

    def remove_auditor
        @auditor = nil
    end

    def dup
        self.class.new( @page ) { |b| b.auditor = @auditor }
    end

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

    # Matches an array of regular expressions against a string and logs the
    # result as an issue.
    #
    # @param    [Array<Regexp>]     patterns
    #   Array of regular expressions to be tested.
    # @param    [Block] block
    #   Block to verify matches before logging, must return `true`/`false`.
    def match_and_log( patterns, &block )
        elements = auditor.class.info[:elements]
        elements = auditor.class::OPTIONS[:elements] if !elements || elements.empty?

        return if !elements.include?( Body )

        [patterns].flatten.each do |pattern|
            auditor.page.body.scan( pattern ).flatten.uniq.compact.each do |proof|
                next if block_given? && !block.call( proof )

                auditor.log(
                    signature: pattern,
                    proof:     proof,
                    vector:    self
                )
            end
        end
    end

end
end
