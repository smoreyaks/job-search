Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Search page
  get  "jobs/search",          to: "jobs#search"
  post "jobs/saveAll",         to: "jobs#save_all"
  post "jobs/refreshListings", to: "jobs#refresh_listings"

  # Edit page
  get  "jobs/savedList",       to: "jobs#saved_list"
  get  "resumes/savedList",    to: "resumes#saved_list"
  post "resume/upload",        to: "resumes#upload"
  get  "resumes/:id/file",     to: "resumes#file"
  get  "cover/savedList",      to: "cover#saved_list"
  post "cover/upload",         to: "cover#upload"
  get  "cover/:id/file",       to: "cover#file"
  post "compare",              to: "compare#create"
  post "applications/save",    to: "applications#create"

  # Tracking page
  get   "tracking",            to: "tracking#index"
  patch "tracking/rowSave",    to: "tracking#row_save"
  patch "tracking/saveAll",    to: "tracking#save_all"

  # Config
  get   "config",              to: "config#show"
  patch "config/saveAll",      to: "config#save_all"
end
