require 'spec_helper'
require 'stringio'

module Aws
  describe 'VERSION' do

    it 'is a semver compatible string' do
      expect(VERSION).to match(/\d+\.\d+\.\d+/)
    end

  end

  describe 'config' do

    it 'defaults to an empty hash' do
      expect(Aws.config).to eq({})
    end

    it 'does not allow assigning config object to non-hash objects' do
      expect(-> { Aws.config = [1,2,3] }).to raise_error(ArgumentError)
    end

  end

  describe 'add_plugin' do

    it 'adds a plugin to every client for all services' do
      client_class = double('client-class')
      allow(Aws).to receive(:client_classes).and_return([client_class])
      expect(client_class).to receive(:add_plugin).with('p')
      Aws.add_plugin('p')
    end

  end

  describe 'remove_plugin' do

    it 'removes a plugin from every client for each service' do
      client_class = double('client-class')
      allow(Aws).to receive(:client_classes).and_return([client_class])
      expect(client_class).to receive(:remove_plugin).with('p')
      Aws.remove_plugin('p')
    end

  end

  describe 'add_service' do

    let(:dummy_credentials) { Aws::Credentials.new('akid', 'secret') }

    before(:each) do
      Aws.config[:region] = 'region-name'
    end

    after(:each) do
      Aws.send(:remove_const, :DummyService)
      Aws.config = {}
    end

    it 'defines a new service module' do
      Aws.add_service('DummyService', api: File.join(GEM_ROOT, 'apis/S3.api.json'))
      expect(Aws::DummyService.ancestors).to include(Aws::Service)
    end

    it 'defines an errors module' do
      Aws.add_service('DummyService', api: File.join(GEM_ROOT, 'apis/S3.api.json'))
      errors = Aws::DummyService::Errors
      expect(errors::ServiceError.ancestors).to include(Aws::Errors::ServiceError)
      expect(errors::FooError.ancestors).to include(Aws::Errors::ServiceError)
    end

    it 'defines a client class' do
      Aws.add_service('DummyService', api: File.join(GEM_ROOT, 'apis/S3.api.json'))
      expect(Aws::DummyService::Client.ancestors).to include(Seahorse::Client::Base)
    end

    it 'loads API with relative paths from the GEM_ROOT' do
      path = File.join(Aws::GEM_ROOT, 'apis/S3.api.json')
      api = StringIO.new(File.read(path))
      expect(File).to receive(:open).with(path, 'r', encoding: 'UTF-8').and_return(api)
      Aws.add_service('DummyService', api: File.join(GEM_ROOT, 'apis/S3.api.json'))
    end

    it 'does not prefix absolute api paths with GEM_ROOT' do
      path = File.join(Aws::GEM_ROOT, 'apis/S3.api.json')
      api = StringIO.new(File.read(path))
      expect(File).to receive(:open).with(path, 'r', encoding: 'UTF-8').and_return(api)
      Aws.add_service('DummyService', api: path)
    end

  end
end
