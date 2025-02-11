# MouseClick, WhichButton [, X, Y, ClickCount, Speed, D|U, R]
class Cmd::X11::Mouse::MouseClick < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 7 end
	def run(thread, args)
		button = case args[0].downcase
		when "right", "r" then XDo::Button::Right
		when "middle", "m" then XDo::Button::Middle
		when "wheelup", "wu" then XDo::Button::ScrollUp
		when "wheeldown", "wd" then XDo::Button::ScrollDown
		when "wheelleft", "wl" then XDo::Button::ScrollLeft
		when "wheelright", "wr" then XDo::Button::ScrollRight
		when "xbutton1", "x1" then XDo::Button::Button8
		when "xbutton2", "x2" then XDo::Button::Button9
		else XDo::Button::Left
		end
		current_x, current_y, screen = thread.runner.display.x_do.mouse_location
		x = args[1]?.try &.to_i?
		y = args[2]?.try &.to_i?
		if x && y
			if thread.settings.coord_mode_mouse == ::Run::CoordMode::RELATIVE
				x, y = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x, y)
			end
		else
			x = current_x
			y = current_y
		end
		count = args[3]?.try &.to_i? || 1
		up = down = false
		case args[5]?.try &.downcase
		when "d" then down = true
		when "u" then up = true
		end
		relative = args[6]?.try &.downcase == "r"
		thread.runner.display.pause do
			count.times do
				if relative
					thread.runner.display.x_do.move_mouse x, y
				else
					thread.runner.display.x_do.move_mouse x, y, screen
				end
				thread.runner.display.x_do.mouse_down button if ! up
				thread.runner.display.x_do.mouse_up button if ! down
			end
		end
	end
end