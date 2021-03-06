# frozen_string_literal: true

RSpec.describe Karafka::Params::ParamsBatch do
  subject(:params_batch) { described_class.new(params_array) }

  let(:serialized_payload) { { rand.to_s => rand.to_s } }
  let(:deserialized_payload) { serialized_payload.to_json }
  let(:topic) { build(:routing_topic) }
  let(:kafka_message1) { build(:kafka_fetched_message, value: deserialized_payload) }
  let(:kafka_message2) { build(:kafka_fetched_message, value: deserialized_payload) }
  let(:params_array) do
    [
      Karafka::Params::Builders::Params.from_kafka_message(kafka_message1, topic),
      Karafka::Params::Builders::Params.from_kafka_message(kafka_message2, topic)
    ]
  end

  describe '#to_a' do
    it 'expect not to deserialize data and return raw params_batch' do
      expect(params_batch.to_a.first['deserialized']).to eq nil
    end
  end

  describe '#deserialize!' do
    it 'expect to deserialize all the messages and return deserialized' do
      params_batch.deserialize!
      params_batch.to_a.each { |params| expect(params['deserialized']).to eq true }
    end
  end

  describe '#each' do
    it 'expect to deserialize each at a time' do
      params_batch.each_with_index do |params, index|
        expect(params['deserialized']).to eq true
        next if index > 0

        expect(params_batch.to_a[index + 1]['deserialized']).to eq nil
      end
    end
  end

  describe '#payloads' do
    it 'expect to return deserialized payloads from params within params batch' do
      expect(params_batch.payloads).to eq [serialized_payload, serialized_payload]
    end

    context 'when payloads were used for the first time' do
      before { params_batch.payloads }

      it 'expect to mark as serialized all the params inside the batch' do
        expect(params_batch.to_a.all? { |params| params['deserialized'] }).to eq true
      end
    end
  end

  describe '#first' do
    it 'expect to return first element after deserializing' do
      expect(params_batch.first).to eq params_batch.to_a[0]
      expect(params_batch.first['deserialized']).to eq true
    end
  end

  describe '#last' do
    it 'expect to return last element after deserializing' do
      expect(params_batch.last).to eq params_batch.to_a[-1]
      expect(params_batch.last['deserialized']).to eq true
    end
  end
end
