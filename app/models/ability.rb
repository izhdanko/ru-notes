class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # Если пользователь не вошёл в систему.

    if user.admin?
      can :read, Post
      can :manage, :all
      can :promote_to_admin, User
      can :demote_from_admin, User
      can :send_for_approval, Post
      can :approve_or_reject, Post
      can :update_status, Post
    else
      can :read, Post
      can :create, Post
      can :update, Post, user_id: user.id, status: 'draft'  # Пользователь может редактировать свои черновики.
      can :destroy, Post, user_id: user.id, status: 'draft'  # Пользователь может удалять свои черновики.
      can :create, User if User.count.zero? # Разрешить создавать первого администратора.

      can :my_posts, Post, user_id: user.id
      can :approved, Post, status: 'approved'
      can :pending, Post, status: 'pending'

      can :send_for_approval, Post, user_id: user.id, status: 'draft' # Добавлено разрешение для отправки на утверждение.
    end
  end
end
