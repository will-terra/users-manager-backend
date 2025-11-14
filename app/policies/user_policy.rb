# Pundit policy governing which users can perform actions on User records.
# - Admins can perform all actions (except deleting themselves)
# - Regular users can only view/update their own profile
class UserPolicy < ApplicationPolicy
  # Only admins can list all users
  def index?
    user.admin?
  end

  # Admins or the user viewing themselves
  def show?
    user.admin? || user == record
  end

  # Only admins can create new users
  def create?
    user.admin?
  end

  # Admins or the user editing their own record
  def update?
    user.admin? || user == record
  end

  # Admins can delete users (but controller will prevent self-deletion with validation error)
  def destroy?
    user.admin?
  end

  # Admins can change roles, but not their own
  def toggle_role?
    user.admin? && user != record
  end

  # Any authenticated user can view their own profile
  def profile?
    true
  end

  # Verify user is admin (for admin action authorization)
  def admin?
    user.admin?
  end

  # Determines if admin-only params are permitted
  def admin_user_params?
    user.admin?
  end

  # Scope class for filtering user collections
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all # Admins see all users
      else
        scope.where(id: user.id) # Regular users only see themselves
      end
    end
  end
end
