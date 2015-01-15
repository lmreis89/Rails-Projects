EventsFCT::Application.routes.draw do
 match "" => "events#index", :defaults => {:format => :xml}
 match "metainfo" => "events#metainfo" , :defaults => {:format=>:xml}
match ":id" => "events#show", :defaults =>{:format => :xml}

end
