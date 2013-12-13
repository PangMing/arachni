=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Checks::Cookies < Arachni::Check::Base

    def prepare
        @prepared = true
    end

    def run
        return if !@prepared
        @ran = true
    end

    def clean_up
        return if !@ran
        log_issue( vector: Factory.create( :unique_active_vector, :Cookie ) )
    end

    def self.info
        {
            name:        'Test check',
            description: %q{Test description},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1',
            references:  {
                'Wikipedia' => 'http://en.wikipedia.org/'
            },
            elements: [ Element::Cookie ],
            targets:     { 'Generic' => 'all' },
            issue:       {
                name:            "Test issue #{name.to_s}",
                description:     %q{Test description},
                tags:            ['some', 'tag'],
                cwe:             '0',
                severity:        Severity::HIGH,
                remedy_guidance: %q{Watch out!.},
                remedy_code:     ''
            }
        }
    end

end
