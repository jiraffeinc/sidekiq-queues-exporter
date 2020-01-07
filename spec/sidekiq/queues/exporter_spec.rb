require 'spec_helper'

RSpec.describe Sidekiq::Queues::Exporter do
  let(:app) { described_class.to_app }

  it 'has a version number' do
    expect(Sidekiq::Queues::Exporter::VERSION).not_to be nil
  end

  context 'when get request to /metrics' do
    subject { last_response }

    before do
      allow(Sidekiq::Queue).to receive(:all).and_return(
        [
          double(name: 'mailer', size: 10),
          double(name: 'jobs', size: 2),
          double(name: 'some queue', size: 1)
        ]
      )
      get '/metrics'
    end


    it { is_expected.to have_attributes status: 200 }
    it { is_expected.to have_attributes body: include('sidekiq_queue {queue_name="jobs"} 2') }
    it { is_expected.to have_attributes headers: include('Cache-Control' => 'no-cache') }
  end

  context 'when post request to /metrics' do
    before { post '/metrics' }

    it { expect(last_response).to have_attributes status: 404 }
  end

  context 'when get request to /foo' do
    before { post '/foo' }

    it { expect(last_response).to have_attributes status: 404 }
  end
end
