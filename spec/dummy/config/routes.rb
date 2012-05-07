Dummy::Application.routes.draw do
  root :to => "welcome#index"
  match '/javascript_test', :to => "welcome#javascript_test"
  match '/access_db', :to => "welcome#access_db"
end
