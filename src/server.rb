require "sinatra"

data = {}

get '/:arg' do
  # Return the requested info.
  puts "Getting #{params['arg']}..."
  # Not actually what we want to do but that's ok
  return data["#{params['arg']}"]
end

put '/:sender' do
  # Save the supplied mapping information.
  puts "Putting for #{params['sender']} = #{:visible}..."
  data["#{params['sender']}"] = params[:visible]
  return 'ok'
end
