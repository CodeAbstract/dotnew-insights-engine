require 'rails_helper'

RSpec.describe ErrorHandler do
  let(:controller_class) do
    Class.new(ApplicationController) do
      include ErrorHandler
      
      def test_action
        raise StandardError, 'Test error'
      end
      
      def test_record_not_found
        raise ActiveRecord::RecordNotFound, 'Record not found'
      end
      
      def test_record_invalid
        record = Visit.new # real AR model
        record.errors.add(:base, 'Name cannot be blank')
        raise ActiveRecord::RecordInvalid.new(record)
      end
      
      def test_parameter_missing
        raise ActionController::ParameterMissing.new(:required_param)
      end
      
      def test_log_error
        log_error(StandardError.new('Test error'))
      end
    end
  end
  
  let(:controller) { controller_class.new }

  describe 'error handling' do
    before do
      allow(controller).to receive(:render)
      allow(Rails.logger).to receive(:error)
    end

    context 'with StandardError' do
      it 'returns internal server error' do
        error = StandardError.new('Test error')
        allow(error).to receive(:backtrace).and_return(['line1', 'line2'])
        
        expect(controller).to receive(:render).with(
          hash_including(
            json: hash_including(
              error: hash_including(
                status: :internal_server_error,
                message: 'An unexpected error occurred'
              )
            ),
            status: :internal_server_error
          )
        )
        
        controller.send(:handle_error, error)
      end
    end

    context 'with RecordNotFound' do
      it 'returns not found error' do
        expect(controller).to receive(:render).with(
          hash_including(
            json: hash_including(
              error: hash_including(
                status: :not_found,
                message: 'Record not found'
              )
            ),
            status: :not_found
          )
        )
        
        controller.send(:handle_error, ActiveRecord::RecordNotFound.new('Record not found'))
      end
    end

    context 'with RecordInvalid' do
      it 'returns unprocessable entity error' do
        record = Visit.new # real AR model
        record.errors.add(:base, 'Name cannot be blank')
        error = ActiveRecord::RecordInvalid.new(record)
        
        expect(controller).to receive(:render).with(
          hash_including(
            json: hash_including(
              error: hash_including(
                status: :unprocessable_entity,
                message: ['Name cannot be blank']
              )
            ),
            status: :unprocessable_entity
          )
        )
        
        controller.send(:handle_error, error)
      end
    end

    context 'with ParameterMissing' do
      xit 'returns bad request error' do
        error = ActionController::ParameterMissing.new(:required_param)
        allow(error).to receive(:backtrace).and_return(['line1', 'line2'])
        
        expect(controller).to receive(:render).with(
          hash_including(
            json: hash_including(
              error: hash_including(
                status: 400,
                message: 'param is missing or the value is empty or invalid: required_param'
              )
            ),
            status: 400
          )
        )
        
        controller.send(:handle_error, error)
      end
    end
  end

  xit '#log_error logs error details' do
    error = StandardError.new('Test error')
    allow(error).to receive(:backtrace).and_return(['line1', 'line2'])
    
    expect(Rails.logger).to receive(:error).with('StandardError: Test error')
    expect(Rails.logger).to receive(:error).with("line1\nline2")
    
    controller.send(:log_error, error)
  end

  describe '#render_error' do
    it 'renders error response with correct format' do
      expect(controller).to receive(:render).with(
        hash_including(
          json: {
            error: {
              status: :test_status,
              message: 'Test message'
            }
          },
          status: :test_status
        )
      )
      
      controller.send(:render_error, :test_status, 'Test message')
    end
  end

  describe '#handle_error' do
    context 'with unexpected error type' do
      it 'logs and renders internal server error' do
        unexpected_error = RuntimeError.new('Unexpected error')
        allow(unexpected_error).to receive(:backtrace).and_return(['line1', 'line2'])
        
        expect(Rails.logger).to receive(:error).with(
          "Unexpected error: RuntimeError - Unexpected error\nline1\nline2"
        )
        expect(controller).to receive(:render).with(
          hash_including(
            json: hash_including(
              error: hash_including(
                status: :internal_server_error,
                message: 'An unexpected error occurred'
              )
            ),
            status: :internal_server_error
          )
        )
        
        controller.send(:handle_error, unexpected_error)
      end
    end
  end
end 