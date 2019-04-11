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

  describe 'get_images' do
    let!(:een) { described_class.new }

    around(:each) { |example| VCR.use_cassette('/multi_images', :record => :new_episodes) { example.run } }

    subject do
      een.get_images(20, random_camera_id)
    end

    before do
      een.authenticate
      een.authorize
    end

    context '20 images with 5 concurrent worker' do
      let!(:random_camera_id) { een.camera_list.map(&:camera_id).sample }

      it 'will execute workers withouth error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
