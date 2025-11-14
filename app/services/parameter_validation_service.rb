# Service for validating API request parameters.
# Checks for required parameters and rejects unpermitted ones.
# Usage: ParameterValidationService.new(params, required: [:email], optional: [:name]).validate
class ParameterValidationService
  def initialize(params, required: [], optional: [])
    @params = params
    @required = required
    @optional = optional
    @errors = []
  end

  # Validates parameters and returns array of error messages
  def validate
    validate_required_params
    validate_allowed_params
    @errors
  end

  # Returns true if no validation errors
  def valid?
    validate.empty?
  end

  private

  # Check that all required parameters are present
  def validate_required_params
    @required.each do |param|
      if @params[param].blank?
        @errors << "Missing required parameter: #{param}"
      end
    end
  end

  # Check that only allowed parameters are present
  def validate_allowed_params
    allowed_params = @required + @optional
    extra_params = @params.keys.map(&:to_sym) - allowed_params

    extra_params.each do |param|
      @errors << "Unpermitted parameter: #{param}"
    end
  end
end
