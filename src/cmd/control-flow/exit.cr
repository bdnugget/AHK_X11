require "../base"

class Cmd::ControlFlow::Exit < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def run(thread)
		code = thread.runner.str(@args[0]? || "").to_i? || 0
		thread.exit code
	end
end