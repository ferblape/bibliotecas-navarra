Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "searches#index"
  resources :records, only: :show do
    resource :bookmark, only: %i[ create destroy ], module: :records
  end
  resources :lists, path: "listas", only: :show do
    resource :selection, only: %i[ create destroy ], module: :lists
  end

  # The catalog for AI agents, over the Model Context Protocol (Streamable HTTP). The protocol
  # also uses GET and DELETE on the same URL, and the MCP transport answers them.
  match "mcp" => "mcp#create", via: %i[ get post delete ]
end
