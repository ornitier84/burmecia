module VenvUtilPrompt

	class Prompt

		def ask(message, valid_options)
		  if valid_options
		    answer = get_stdin("#{message} #{valid_options.to_s.gsub(/"/, '').gsub(/, /,'/')} ") while !valid_options.include?(answer)
		  else
		    answer = get_stdin(message)
		  end
		  answer
		end

		def get_stdin(message)
		  print message
		  STDIN.gets.chomp
		end		

	end

end