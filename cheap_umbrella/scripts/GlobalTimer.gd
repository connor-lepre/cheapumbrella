extends Node

var max_time_sec := 600.0  # Or whatever you want as the default timer
var time_left := 600.0
var paused := false

func reset(new_time = null):
	time_left = float(new_time) if new_time != null else max_time_sec
	paused = false
	print("TIMER RESET: time_left = ", time_left, "paused =", paused)
