require 'spec_helper'

describe Arachni::Page::DOM do

    def create_page( options = {} )
        Arachni::Page.new response: Arachni::HTTP::Response.new(
              request: Arachni::HTTP::Request.new(
                           url:    'http://a-url.com/',
                           method: :get,
                           headers: {
                               'req-header-name' => 'req header value'
                           }
                       ),

              code:    200,
              url:     'http://a-url.com/?myvar=my%20value',
              body:    options[:body],
              headers: options[:headers]
          )
    end

    let( :dom ) { create_page.dom }

    describe '#transitions' do
        it 'defaults to an empty Array' do
            dom.transitions.should == []
        end
    end

    describe '#transitions=' do
        it 'sets #transitions' do
            transitions = [ { element: :stuffed } ]

            dom.transitions = transitions
            dom.transitions.should == transitions
        end
    end

    describe '#depth' do
        it 'returns the amount of DOM transitions' do
            dom.depth.should == 0

            dom.transitions = [
                { "http://test.com/"                 => :request },
                { :page                              => :load },
                { "<body onload='loadStuff();'>"     => :onload },
                { "http://test.com/ajax"             => :request },
                { "<a href='javascript:clickMe();'>" => :click },
            ]

            dom.depth.should == 3
        end
    end

    describe '#push_transition' do
        it 'pushes a state transition' do
            transitions = [
                { element: :stuffed },
                { element2: :stuffed2 }
            ].each do |transition|
                dom.push_transition transition
            end

            dom.transitions.should == transitions
        end
    end

    describe '#hash' do
        it 'calculates a hash based on nodes' do
            body = <<-EOHTML
                Blah blah.

                <div id='my-div' class='stuff here'>
                    Text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body ).dom

            dom.hash.should == dom2.hash

            body2 = <<-EOHTML
                <div id='my-div' class='stuff here'>
                    Different text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should == dom2.hash

            body2 = <<-EOHTML
                <div id='my-div' class='stuff here'>
                    Different text here.
                </div>
                <a href="stuff">Stuff</a>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should_not == dom2.hash
        end

        it 'calculates a hash based on node attributes' do
            body = <<-EOHTML
                Blah blah.

                <div id='my-div' class='stuff here'>
                    Text here.
                </div>
            EOHTML

            body2 = <<-EOHTML
                Blah blah.

                <div id='div' class='here'>
                    Text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should_not == dom2.hash
        end

        it 'ignores paragraphs' do
            body = <<-EOHTML
                <p>Blah blah.</p>
            EOHTML

            body2 = <<-EOHTML
                <p>More blah blah.</p>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should == dom2.hash
        end

        it 'ignores text' do
            body = <<-EOHTML
                Blah blah.

                <div id='my-div' class='stuff here'>
                    Text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body ).dom

            dom.hash.should == dom2.hash

            body2 = <<-EOHTML
                <div id='my-div' class='stuff here'>
                    Different text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should == dom2.hash
        end

    end

end
