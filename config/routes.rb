Rails.application.routes.draw do
  root "products#index"
  resources :products
  resources :orders
end
