Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: 'main#index'

  # Маршруты для управления пользователями
  resources :users, only: [:index, :show, :edit, :update, :destroy] do
    member do
      patch 'promote_to_admin'
      patch 'demote_from_admin'
    end
  end

  # Маршруты для управления регионами
  resources :regions, only: [:index, :show]

  # Маршруты для управления заметками
  resources :posts, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    member do
      patch 'send_for_approval'
      patch 'change_status'
    end
    collection do
      get 'pending'  # Добавляем этот маршрут для вывода постов в состоянии ожидания
      get 'approved'
      get 'my_posts'
      get 'rejected'
      # get 'generate_report'
      post 'generate_report'
    end
  end

  # Маршруты для управления ролями и разрешениями
  resources :abilities, only: [:index]

end
