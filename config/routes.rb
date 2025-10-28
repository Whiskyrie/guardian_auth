Rails.application.routes.draw do
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql' if Rails.env.development?

  post '/graphql', to: 'graphql#execute'

  # Health check endpoints
  get 'health' => 'health#index'
  get 'health/detailed' => 'health#detailed'
  get 'up' => 'rails/health#show', as: :rails_health_check
end
