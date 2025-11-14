# Pundit policy governing which users can perform actions on UserImport records.
# Only admins have access to import functionality.
class UserImportPolicy < ApplicationPolicy
  # Only admins can list imports
  def index?
    user.admin?
  end

  # Only admins can view imports
  def show?
    user.admin?
  end

  # Only admins can create imports
  def create?
    user.admin?
  end

  # Only admins can delete imports
  def destroy?
    user.admin?
  end

  # Scope class for filtering import collections
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all # Admins see all imports
      else
        scope.none # Regular users don't see imports
      end
    end
  end
end
