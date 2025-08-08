extends Node

# exports
# vars
static var loggingAt:eLogLevel = eLogLevel.ASYNC
# onready vars
# signals

static var regexCls:RegEx = RegEx.new()
# built-in override methods
#func _ready() -> void:pass
#func _process(delta:float) -> void:pass

# signal handlers

# methods
func log(logLevel:int, message:String, args:Array = [], opts:Dictionary = {}) -> void:
	if (loggingAt <= logLevel):
		match logLevel:
			eLogLevel.ALL:
				doPrint(Callable(print), "none", message, args, opts)
				pass
			eLogLevel.ASYNC:
				doPrint(Callable(print_rich), "green", message, args, opts)
				pass
			eLogLevel.INFO:
				doPrint(Callable(print_rich), "orange", message, args, opts)
				pass
			eLogLevel.WARN:
				doPrint(Callable(print_rich), "yellow", message, args, opts)
				pass
			eLogLevel.ERROR:
				doPrint(Callable(print_rich), "red", message, args, opts)
				pass
			var _unknown:
				pass
		pass
	pass

func all(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.ALL, message, args, { stack = get_stack(), newlines = _newlines})
	pass

func async(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.ASYNC, message, args, { stack = get_stack(), newlines = _newlines})
	pass

func info(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.INFO, message, args, { stack = get_stack(), newlines = _newlines})
	pass

func warn(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.WARN, message, args, { stack = get_stack(), newlines = _newlines})
	#push_warning(message, args)
	pass

func error(message:String, args:Array = [], _newlines = false) -> void:
	self.log(eLogLevel.ERROR, message, args, { stack = get_stack(), newlines = _newlines})
	push_error(message, args)
	pass

func doPrint(printAction:Callable, coloring:String, message:String, args:Array, opts:Dictionary) -> void:
	var plainMessage = assembleMessage(opts, message, args)
	if coloring == "none":
		printAction.call(plainMessage)
	else:
		var coloredMessage = "[color=" + coloring + "]" + plainMessage + "[/color]"
		printAction.call(coloredMessage)
	pass

func stringifyArgs(args:Array) -> String:
	var aggregate = ""
	for arg in args:
		if aggregate.length() > 0:
			aggregate = aggregate + ", " + str(arg)
		else:
			aggregate = aggregate + " - " + str(arg)
	return aggregate

func stringifyStack(stack:Array) -> String:
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

func assembleMessage(opts:Dictionary, message:String, args:Array) -> String:
	var logPrefix = ""
	if opts.has("stack"):
		logPrefix = stringifyStack(opts.stack)
		pass

	if message.contains("%"):
		return substituteArgs(logPrefix, message, args)

	return logPrefix + message + stringifyArgs(args)

func substituteArgs(logPrefix:String, message:String, args:Array) -> String:
	var finalArgs:Array = []
	for arg in args:
		if message.contains("%"):
			message = str_replace_first(
				message,
				RegEx.create_from_string("%"),
				func(_text: String) -> String:
				return str(arg)
			)
		else:
			finalArgs.push_front(arg)

	var finalAssembly:String = logPrefix + message

	if finalArgs.size() > 0:
		finalAssembly = finalAssembly + stringifyArgs(finalArgs)

	return finalAssembly

func str_replace_first(target:String, pattern:RegEx, cb:Callable) -> String:
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

func str_replace_all(target:String, pattern:RegEx, cb:Callable) -> String:
	var out = ""
	var last_pos = 0
	for regex_match in pattern.search_all(target):
		var start := regex_match.get_start()
		out += target.substr(last_pos, start - last_pos)
		out += str(cb.call(regex_match.get_string()))
		last_pos = regex_match.get_end()

	out += target.substr(last_pos)
	return out

# statics
# enums
enum eLogLevel {
	ALL,
	ASYNC,
	INFO,
	WARN,
	ERROR
}
# consts
