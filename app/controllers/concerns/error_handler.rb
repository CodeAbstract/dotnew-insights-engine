module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |e|
      handle_error(e)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      render_error(:not_found, e.message)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_error(:unprocessable_entity, e.record.errors.full_messages)
    end

    rescue_from ActionController::ParameterMissing do |e|
      render_error(400, e.message)
    end

    private

    def handle_error(error)
      case error
      when ActiveRecord::RecordNotFound
        render_error(:not_found, error.message)
      when ActiveRecord::RecordInvalid
        render_error(:unprocessable_entity, error.record.errors.full_messages)
      else
        Rails.logger.error("Unexpected error: #{error.class} - #{error.message}\n#{error.backtrace.join("\n")}")
        render_error(:internal_server_error, 'An unexpected error occurred')
      end
    end

    def render_error(status, message)
      error_response = {
        error: {
          status: status,
          message: message
        }
      }

      render json: error_response, status: status
    end

    def log_error(error)
      Rails.logger.error "#{error.class}: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")
    end
  end
end 