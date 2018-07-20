module VenvFormatter

	class PrettyPrint
		# Generate a backtrace string for given exception.
		# Generated string is a series of lines, each beginning with a tab and "at ".
		def backtrace(exception)
		  "\tat #{exception.backtrace.join("\n\tat ")}"
		end

		# Generate a string containing exception message followed by backtrace.
		def exception(exception)
		  "#{exception.message}\n#{pretty_backtrace(exception)}"
		end
	end

end