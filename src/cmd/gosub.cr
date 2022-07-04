require "./cmd"

class GosubCmd < Cmd
	def self.name; "gosub"; end
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(runner)
		runner.gosub(runner.str(@args[0]))
	end
end