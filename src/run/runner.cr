require "./ahk-string"
require "./thread"
require "./timer"
require "./hotkey"
require "../cmd/base"
require "./gui"
require "./x11"
require "x_do"

module Run
	# can start a completely fresh and isolated ahk execution instance with its own
	# variables etc. All properties can and will be heavily accessed from outside (commands).
	class Runner
		@user_vars = {
			# INCOMPAT(fix?) static built-in variables can be overridden
			"a_space" => " "
		}
		@escape_char = '`'
		protected getter labels : Hash(String, Cmd::Base)
		@threads = [] of Thread
		@auto_execute_thread : Thread?
		@run_thread_channel = Channel(Nil).new
		@exit_code = 0
		@timers = {} of String => Timer
		@default_thread_settings = ThreadSettings.new
		@hotkeys = {} of String => Hotkey
		@x11 = X11.new
		getter x_do = XDo.new
		getter gui = Gui.new

		def initialize(*, @labels, @escape_char)
		end
		def run(*, hotkey_labels : Array(String), auto_execute_section : Cmd::Base)
			hotkey_labels.each { |l| add_hotkey l }
			spawn @x11.run self
			spawn @gui.run
			spawn same_thread: true { clock }
			@auto_execute_thread = add_thread auto_execute_section, 0
		end

		# add to the thread queue. Depending on priority and @threads, it may be picked up
		# by the clock fiber immediately afterwards
		protected def add_thread(cmd, priority) : Thread
			thread = Thread.new(self, cmd, priority, @default_thread_settings)
			i = @threads.index { |t| t.priority > thread.priority } || @threads.size
			@threads.insert(i, thread)
			@run_thread_channel.send(nil) if i == @threads.size - 1
			thread
		end

		# there must only be one
		private def clock
			loop do
				while thread = @threads.last?
					select
					when @run_thread_channel.receive
						# current command may finish in the background, but its result handling and thread continuation
						# will have to wait: probably because another, more important thread came along which will now
						# get attention in the next iteration
					when exit_code = thread.next.receive?
						if ! exit_code.nil?
							@exit_code = exit_code
							@threads.pop
							if thread == @auto_execute_thread
								@default_thread_settings = thread.settings
								# ::exit @exit_code
							end
						end
					end
				end
				# all done, now wait for something new to do
				@run_thread_channel.receive
			end
		end

		def get_var(var)
			@user_vars[var.downcase]? || ""
		end
		def set_var(var, value)
			@user_vars[var.downcase] = value
		end
		def print_vars
			puts @user_vars
		end
		
		def str(str)
			AhkString.process(str, @escape_char) do |var_name_lookup|
				get_var(var_name_lookup)
			end
		end

		def get_timer(label)
			@timers[label]?
		end
		def add_timer(label, period, priority)
			cmd = labels[label]?
			raise RuntimeException.new "add timer: label '#{label}' not found" if ! cmd
			timer = Timer.new(self, cmd, period, priority)
			@timers[label] = timer
			timer
		end

		def add_hotkey(label)
			cmd = labels[label]?
			raise RuntimeException.new "add hotkey: label '#{label}' not found" if ! cmd
			hotkey = Hotkey.new(self, cmd, label)
			@hotkeys[label] = hotkey
			@x11.register_hotkey hotkey
			hotkey
		end
		def remove_hotkey(label)
			hotkey = @hotkeys.delete(label)
			raise Cmd::RuntimeException.new "remove hotkey: label '#{label}' not found" if ! hotkey
			@x11.unregister_hotkey hotkey
		end
		def pause_x11
			@x11.pause
		end
		def resume_x11
			@x11.resume
		end
	end

	class RuntimeException < Exception end
end