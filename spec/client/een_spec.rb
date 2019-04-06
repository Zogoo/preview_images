require './spec/spec_helper.rb'

RSpec.describe Client::Een do
  describe 'authenticate' do
    subject do
      described_class.new.authenticate
    end

    context 'with correct username and password' do
      around(:each) { |example| VCR.use_cassette('/authenticate') { example.run } }

      it 'will not return nil' do
        expect(subject.nil?).not_to be_truthy
      end
      it 'will return token as string' do
        expect(subject.token).to be_a(String)
      end
    end
  end

  describe 'authorize' do
    let!(:een) { described_class.new }

    subject do
      een.authorize
    end

    before do
      een.authenticate
    end

    context 'with correct token' do
      around(:each) { |example| VCR.use_cassette('/authorize') { example.run } }

      it 'will not return nil' do
        expect(subject.nil?).not_to be_truthy
      end
      it 'will assign active brand subdomain' do
        subject
        expect(een.subdomain.nil?).not_to be_truthy
        expect(een.subdomain).to be_a(String)
      end
    end
  end

  describe 'camera_list' do
    let!(:een) { described_class.new }

    subject do
      een.camera_list
    end

    before do
      een.authenticate
      een.authorize
    end

    context 'with correct cookie' do
      around(:each) { |example| VCR.use_cassette('/camera_list') { example.run } }

      it 'will return array' do
        expect(subject.nil?).not_to be_truthy
        expect(subject).to be_a(Array)
      end
    end
  end
end
