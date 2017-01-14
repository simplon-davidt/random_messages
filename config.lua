
random_messages.options = {}
			
	-- True / False : Should messages be displayed on chat
random_messages.options.display_chat_messages	= false
			
	-- True / False : Should signs with messages be places around the world
random_messages.options.place_messages_signs	= true
			
	--Time between two subsequent messages.
	-- 0 to use default (120)
random_messages.options.messages_interval = 300
			
	-- Default messages file name
random_messages.options.default_messages_file_name = "messages"
			
	-- Signs optiosn
random_messages.options.signs = {
			
		-- height limits for signs to be places 
		h_min = -200,
		h_max = 200,

		-- Increase this value will to see more signs in the world
		signs_per_chunk= 1,
	}
