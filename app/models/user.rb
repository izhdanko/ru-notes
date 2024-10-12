class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:username]

  validates :full_name, presence: true
  validates :username, presence: true, uniqueness: true
  validates :password, presence: true, if: :password_required?
  validates :region_id, presence: true, if: -> { !admin? }

  belongs_to :region, optional: true # Поле региона не обязательно для администраторов.
  has_many :posts, dependent: :destroy

  def promote_to_admin
    update(admin: true)
  end

  def demote_from_admin
    update(admin: false)
  end

  def can_send_for_approval?(post)
    !admin? && post.user.region == region && post.draft?
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[full_name username admin region_id] # Разрешаем атрибуты для фильтрации.
  end


  private

  def password_required?
    new_record? || !password.blank? || !password_confirmation.blank?
  end

end


