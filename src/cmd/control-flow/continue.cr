require "../base"

class Cmd::ControlFlow::Continue < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread)
		true
	end
end