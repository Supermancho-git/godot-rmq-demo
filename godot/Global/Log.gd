extends Node

enum eLogLevel {
	ALL,
	DEBUG,
	ASYNC,
	INFO,
	WARN,
	ERROR,
}

var ColorMap:Dictionary = {
	eLogLevel.ALL : "none",
	eLogLevel.DEBUG : "lightblue",
	eLogLevel.ASYNC : "green",
	eLogLevel.INFO : "orange",
	eLogLevel.WARN : "yellow",
	eLogLevel.ERROR : "red",
}

static var loggingAt:eLogLevel = eLogLevel.ASYNC

#-----
func log(logLevel:eLogLevel, message:String, args:Array = [], opts:Dictionary = {}) -> void:
	if (loggingAt <= logLevel):
		_doPrint(Callable(print), ColorMap[logLevel], message, args, opts)
	return
#-----
func all(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.ALL, message, args, { stack = get_stack(), newlines = _newlines})
	return
#-----
func async(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.ASYNC, message, args, { stack = get_stack(), newlines = _newlines})
	return
#-----
func debug(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.DEBUG, message, args, { stack = get_stack(), newlines = _newlines})
	return
#-----
func info(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.INFO, message, args, { stack = get_stack(), newlines = _newlines})
	return
#-----
func warn(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.WARN, message, args, { stack = get_stack(), newlines = _newlines})
	return
#-----
func error(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.ERROR, message, args, { stack = get_stack(), newlines = _newlines})
	push_error(message, args)
	return
#-----
func _doPrint(printAction:Callable, coloring:String, message:String, args:Array, opts:Dictionary) -> void:
	var plainMessage = _assembleMessage(opts, message, args)
	if coloring == "none":
		printAction.call(plainMessage)
	else:
		var coloredMessage = "[color=" + coloring + "]" + plainMessage + "[/color]"
		printAction.call(coloredMessage)
	return
#-----
func _stringifyArgs(args:Array) -> String:
	var aggregate = ""
	for arg in args:
		if aggregate.length() > 0:
			aggregate = aggregate + ", " + str(arg)
		else:
			aggregate = aggregate + " - " + str(arg)
	return aggregate
#-----
func _stringifyStack(stack:Array) -> String:
	if len(stack) > 1:
		var call_site: Dictionary = stack[1]
		var call_site_source: String = call_site.get("source", "")
		var basename: String = call_site_source.get_file().get_basename()
		var line_num: String = str(call_site.get("line", 0))
		if call_site_source.match("*/test/*"):
			return "{" + basename + ":" + line_num + "}: "
		elif call_site_source.match("*/addons/*"):
			return "<" + basename + ":" + line_num + ">: "
		else:
			return "[" + basename + ":" + line_num + "]: "
	return ""
#-----
func _assembleMessage(opts:Dictionary, message:String, args:Array) -> String:
	var logPrefix = ""
	if opts.has("stack"):
		logPrefix = _stringifyStack(opts.stack)
		pass

	if message.contains("%"):
		return _substituteArgs(logPrefix, message, args)

	return logPrefix + message + _stringifyArgs(args)
#-----
func _substituteArgs(logPrefix:String, message:String, args:Array) -> String:
	var finalArgs:Array = []
	for arg in args:
		if message.contains("%"):
			message = _str_replace_first(
				message,
				RegEx.create_from_string("%"),
				func(_text: String) -> String:
				return str(arg)
			)
		else:
			finalArgs.push_front(arg)

	var finalAssembly:String = logPrefix + message

	if finalArgs.size() > 0:
		finalAssembly = finalAssembly + _stringifyArgs(finalArgs)

	return finalAssembly
#-----
func _str_replace_first(target:String, pattern:RegEx, cb:Callable) -> String:
	var out = ""
	var last_pos = 0
	var regex_matches:Array[RegExMatch] = pattern.search_all(target)
	if regex_matches.size() > 0:
		var regex_match:RegExMatch = regex_matches[0]
		var start := regex_match.get_start()
		out += target.substr(last_pos, start - last_pos)
		out += str(cb.call(regex_match.get_string()))
		last_pos = regex_match.get_end()

	out += target.substr(last_pos)
	return out
#-----
func _str_replace_all(target:String, pattern:RegEx, cb:Callable) -> String:
	var out = ""
	var last_pos = 0
	for regex_match in pattern.search_all(target):
		var start := regex_match.get_start()
		out += target.substr(last_pos, start - last_pos)
		out += str(cb.call(regex_match.get_string()))
		last_pos = regex_match.get_end()

	out += target.substr(last_pos)
	return out
#-----
