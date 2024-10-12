class Post < ApplicationRecord

  belongs_to :user
  belongs_to :region

  has_many_attached :images # Для использования Active Storage для хранения изображений.
  has_many_attached :files   # Для использования Active Storage для хранения файлов.

  has_rich_text :content # Добавляем Action Text для content.

  enum status: [:draft, :pending, :approved, :rejected]

  validates :title, :content, presence: true


  # Добавляем логику, чтобы обычные пользователи могли писать посты только в свой регион.
  validate :user_can_write_in_own_region

  def self.ransackable_attributes(auth_object = nil)
    %w[username title status region_id created_at] # Разрешаем атрибуты для фильтрации.
  end


  private

  def user_can_write_in_own_region
    if user && region && !user.admin? && user.region != region
      errors.add(:user_id, "cannot write in a different region")
    end
  end

end


