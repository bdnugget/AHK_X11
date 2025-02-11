# StringLower, OutputVar, InputVar [, T]
class Cmd::String::StringLower < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end
	def run(thread, args)
		out_var, in_var = args
		title_case = args[2]? && args[2].downcase == "t"
		text = thread.runner.get_user_var(in_var)
		if title_case
			text = text.titleize
		else
			text = text.downcase
		end
		thread.runner.set_user_var(out_var, text)
	end
end