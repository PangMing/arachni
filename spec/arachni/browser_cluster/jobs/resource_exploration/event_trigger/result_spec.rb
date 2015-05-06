require 'spec_helper'

describe Arachni::BrowserCluster::Jobs::ResourceExploration::EventTrigger::Result do
    subject { described_class.new }
    it { should respond_to :page }
    it { should respond_to :page= }
end