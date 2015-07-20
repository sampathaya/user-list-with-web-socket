class MySocket
	def initialize app
		@app = app
		@clients = {}
	end

	def call env
		@env = env
		if Faye::WebSocket.websocket? env
			socket = spawn_socket
			@clients << socket
			socket.rack_response
		else
			@app.call env
		end
	end

	private

	attr_reader :env

	def spawn_socket
		socket = Faye::WebSocket.new env

		socket.on :open do
			socket.send 'init connection_open'
		end

		socket.on :message do |event|
			socket.send event.data
      tokens = event.data.split " "
      _type = tokens.delete_at 0
      begin
	      case _type
	      when "new_session"
	      	handle_new_sessions(tokens,socket)
	      	user = User.find(find_user_id(socket))
	      	user.update_attribute(:status, user.status)
	      	# broadcast("online", user.id)
	      	public_broadcast
	      when 'change_status'
	      	user = User.find(find_user_id(socket))
	      	user.update_attribute(:status, tokens[1])
	      	public_broadcast
	      end

	    rescue Exception => e
	    	puts e
	    	puts e.backtrace
	    end
		end

		socket.on :close do |event|

			user_id = find_user_id(socket)
			@clients.delete(user_id.to_i) if user_id
			broadcast("ofline", user_id) if user_id
		end

		socket
	end

	def broadcast(status, user_id)
		@clients.values.flatten.each do |client|
			client.send "status #{status} #{user_id}"
		end
	end

	def public_broadcast
		@clients.values.flatten.each do |client|
			user_id = find_user_id(client)
			user = User.find(user_id) if user_id
			broadcast(user.status, user.id) if user_id
		end
	end

	def find_user_id socket
		user_id = nil
		@clients.each do |client|
			if client[1].class == Array
				user_id = client[0] if client[1].include?(socket)
			else
				user_id = client[0] if client[1] == socket
			end
		end
		user_id
	end

	def handle_new_sessions(tokens, socket)
		user_id = tokens[0]
		user = User.find(user_id.to_i)
  	if @clients.keys.include?(user_id.to_i)
  		tmp_array = []
  		tmp_array << @clients.fetch(user_id.to_i)
  		tmp_array << socket
  		@clients[user_id.to_i] = tmp_array
  	else
  		@clients[user_id.to_i] = socket
  	end

  	@clients.values.flatten.each do |client|
			client.send "users #{User.all.count} #{@clients.count} #{user.id} #{user.name} #{user.email}"
		end



  	
  	# User.admin_users.each do |admin_user|
  	# 	if @clients.fetch(admin_user).class == Array
  	# 		@clients.fetch(admin_user).flatten.collect{|skt| skt.send "users #{User.all.count} #{@clients.count} #{user.id} #{user.name} #{user.email}"}
  	# 	else
  	# 		@clients.fetch(admin_user).send "users #{User.all.count} #{@clients.count} #{user.id} #{user.name} #{user.email}"
  	# 	end
  	# end
	end
end