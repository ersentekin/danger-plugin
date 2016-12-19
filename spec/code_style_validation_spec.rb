require File.expand_path('../spec_helper', __FILE__)

module Danger
  describe Danger::DangerCodeStyleValidation do
    it 'should be a plugin' do
      expect(Danger::DangerCodeStyleValidation.new(nil)).to be_a Danger::Plugin
    end

    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.code_style_validation
      end

      it 'Reports code style violation as error' do
        diff = File.read('spec/violated_diff.diff')

        @my_plugin.gitlab.stub(:mr_diff).and_return diff
        @my_plugin.check

        expect(@dangerfile.status_report[:errors]).to eq([VIOLATION_ERROR_MESSAGE])
      end

      it 'Does not report error when code not violated' do
        diff = File.read('spec/innocent_diff.diff')

        @my_plugin.gitlab.stub(:mr_diff).and_return diff
        @my_plugin.check

        expect(@dangerfile.status_report[:errors]).to eq([])
      end

      it 'Does not report error for different extension types of files' do
        diff = File.read('spec/ruby_diff.diff')

        @my_plugin.gitlab.stub(:mr_diff).and_return diff
        @my_plugin.check

        expect(@dangerfile.status_report[:errors]).to eq([])
      end
    end
  end
end
