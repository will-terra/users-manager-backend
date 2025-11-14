# Service object to filter a User scope by role, free-text search, and a created_at date range.
class UserSearchService
  def initialize(scope, params)
    @scope = scope
    @params = params
  end

  def call
    # Apply filters in sequence; each step returns a narrowed ActiveRecord::Relation
    @scope = filter_by_role
    @scope = filter_by_search
    @scope = filter_by_date_range
    @scope
  end

  private

  def filter_by_role
    # Filter by exact role if provided (e.g., "admin", "user")
    return @scope unless @params[:role].present?

    @scope.where(role: @params[:role])
  end

    def filter_by_search
    # Case-insensitive match on full_name or email using ILIKE
    return @scope unless @params[:search].present?

    # Use left-anchored search for more precise matching
    search_term = "#{@params[:search]}%"
    @scope.where("full_name ILIKE ? OR email ILIKE ?", search_term, search_term)
  end
  def filter_by_date_range
    # Restrict by created_at between optional start_date and end_date (inclusive)
    return @scope unless @params[:start_date].present? || @params[:end_date].present?

    scope = @scope
    scope = scope.where("created_at >= ?", Date.parse(@params[:start_date])) if @params[:start_date].present?
    scope = scope.where("created_at <= ?", Date.parse(@params[:end_date]).end_of_day) if @params[:end_date].present?
    scope
  end
end
