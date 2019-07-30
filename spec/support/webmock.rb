require 'webmock/rspec'
allowed_list = []
allowed_list << "localhost:4502"
allowed_list << "localhost:5000"
allowed_list << "localhost:4452"
allowed_list << "localhost:3451"
allowed_list << "localhost:3501"
allowed_list << "localhost:3453"
allowed_list << "localhost:4506"
allowed_list << /\.internal/
WebMock.disable_net_connect!(allow: allowed_list)
