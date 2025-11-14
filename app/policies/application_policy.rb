# Base policy class for Pundit authorization.
# All policy classes should inherit from this class.
# By default, all actions are denied unless explicitly allowed in subclasses.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @record = record
  end

  # Default policy methods - deny all actions by default
  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  # Helper to get the policy scope for the record class
  def scope
    Pundit.policy_scope!(user, record.class)
  end

  # Scope class for filtering collections based on user permissions
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, "must be logged in" unless user
      @user = user
      @scope = scope
    end

    # Default scope returns all records - override in subclasses to restrict
    def resolve
      scope.all
    end
  end
end
