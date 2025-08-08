class_name Util

#-----
static func checkForBadKey(x) -> bool:
	#Log.info("checking", [x])
	if typeof(x) == TYPE_STRING:
		if (x == null or x == ""):
			Log.warn("Bad key: ", [x])
		return (x == null or x == "")
	if (x == null):
		Log.warn("Bad key: ", [x])
	return x == null
#-----
static func assertRequiredFields(config:Dictionary, className:String, requiredFields:Array[String], skipBadKeys=false) -> void:
	if config == null || config.size() < 1:
		Log.warn("empty config")
	elif not config.has_all(requiredFields):
		Log.warn("missing required fields:", [findMissingRequiredFields(requiredFields, config)])
	elif not skipBadKeys and config.values().any(Util.checkForBadKey):
		Log.warn("found bad key")
	else:
		return
	Log.error(className + " not intialized")
	push_error("Class initialization failed")
#-----
static func findMissingRequiredFields(requiredFields:Array, config:Dictionary) -> Array:
	var missingFields:Array[String] = []
	for v in requiredFields:
		if not config.has(v):
			missingFields.append(v)
	return missingFields
#-----
