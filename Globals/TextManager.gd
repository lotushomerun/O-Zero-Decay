class_name TextManager

#Accepts a string and parses it to third person if not player
static func parse(text: String, chara: Char, parseType: int=0):
	if (Player.this != null):
		if (chara == Player.this.character):
			return text
	var regex = RegEx.new()
	var stringList: PackedStringArray
	#Really lazy, just _assume_ you have one space for each word
	var word_count = text.count(" ") + 1
	if word_count == 1:
		if has_str(text,"(?i)you're"):
				regex.compile("(?i)you're")
				text = regex.sub(text,chara.char_data.known_as+"'s" if parseType == 0 else (chara.hes_shes().capitalize() if text.count("Y") else chara.hes_shes()))
		elif has_str(text,"(?i)you've"):
				regex.compile("(?i)you've")
				text = regex.sub(text,chara.char_data.known_as+" has" if parseType == 0 else (chara.he_she().capitalize() if text.count("Y") else chara.he_she())+" has")
		elif has_str(text,"(?i)yourself"):
				regex.compile("(?i)yourself")
				text = regex.sub(text,chara.himself_herself().capitalize() if text.count("Y") else chara.himself_herself())
		elif has_str(text,"(?i)yours"):
				regex.compile("(?i)yours")
				text = regex.sub(text,chara.char_data.known_as+"'s" if parseType == 0 else (chara.his_hers().capitalize() if text.count("Y") else chara.his_hers()))
		elif has_str(text,"(?i)your"):
				regex.compile("(?i)your")
				text = regex.sub(text,chara.char_data.known_as+"'s" if parseType == 0 else (chara.his_her().capitalize() if text.count("Y") else chara.his_her()))
		elif has_str(text,"(?i)you"):
				regex.compile("(?i)you")
				if (parseType == 2):
					text = regex.sub(text,chara.char_data.known_as if parseType == 0 else (chara.him_her().capitalize() if text.count("Y") else chara.him_her()))
				else:
					text = regex.sub(text,chara.char_data.known_as if parseType == 0 else (chara.he_she().capitalize() if text.count("Y") else chara.he_she()))
		else:
			if special_verbs(text) != null:
					text = special_verbs(text)
			else:
					text = conjugator(text)
	elif word_count == 2:
		#"you [second person verb]", or "[third person verb] you, or "do you"
		#Begins with "you"
		if has_str(text,"^(?i)You"):
			regex.compile("^(?i)You")
			text = regex.sub(text,chara.char_data.known_as if parseType == 0 else (chara.he_she().capitalize() if text.count("Y") else chara.he_she()))
			stringList = text.split(" ")
			if special_verbs(stringList[1]) != null:	
				stringList[1] = " "+special_verbs(stringList[1]);
			else:
				stringList[1] = " "+conjugator(stringList[1]+":s");
			text = stringList[0]+stringList[1]
		#Do you, NOTE - do not write "Do you want to save?" as "Does master want to save?" is weird
		elif has_str(text,"^(?i)Do"):
			regex.compile("^(?i)Do")
			text = regex.sub(text,"$1es")
			regex.compile("(?i)You$")
			text = regex.sub(text,chara.char_data.known_as if parseType == 0 else (chara.he_she().capitalize() if text.count("Y") else chara.he_she()))
		#Begins with third person verb, meaning it's "gives Anon" or "gives him"
		elif has_str(text,"^(?i)You$"):
			regex.compile("^(?i)You$")
			text = regex.sub(text,chara.char_data.known_as if parseType == 0 else (chara.him_her().capitalize() if text.count("Y") else chara.him_her()))
		#Begins with third person verb, meaning it's "gives his" or "give your"
		elif has_str(text,"^(?i)Your$"):
			stringList = text.split(" ")
			if special_verbs(stringList[0]) != null:	
				stringList[0] = special_verbs(stringList[0]);
			else:
				stringList[0] = conjugator(stringList[0]+":s");
			regex.compile("^(?i)Your$")
			stringList[1] = regex.sub(text,chara.char_data.known_as+"'s" if parseType == 0 else (chara.his_her().capitalize() if text.count("Y") else chara.his_her()))
	elif word_count == 3:
		#You verb your etc.
		if has_str(text,"^(?i)You"):
			regex.compile("^(?i)You")
			text = regex.sub(text,chara.char_data.known_as if parseType == 0 else (chara.he_she().capitalize() if text.count("Y") else chara.he_she()))
		stringList = text.split(" ")
		if special_verbs(stringList[1]) != null:
				stringList[1] = special_verbs(stringList[1])
		else:
				stringList[1] = conjugator(stringList[1]+":s")
		regex.compile("(?i)your$")
		stringList[2] = regex.sub(stringList[2],parse("your",chara,1))
		text = "%s %s %s" % [stringList[0], stringList[1], stringList[2]]
	return text
	
# regex get string
static func has_str(arg: String, findArg: String) -> bool:
	var regex = RegEx.new()
	regex.compile(findArg)
	if regex.search(arg):
		return true
	return false

#--------------------------------------------------------
#modified the function in STR_BODY to be less restrictive (string:string:string, matching string, matching string, etc)
#--------------------------------------------------------
static func split_check(arg: String, substring: Array[String]) -> bool:
	var regex = RegEx.new()
	var matchStr: String = "(^|:)("
	for i in range(substring.size()):
		var a = substring[i]
		if i > 0:
			matchStr += "|"
		matchStr += a
	matchStr += ")($|:)"
	regex.compile(matchStr)
	return (regex.search(arg) != null)
	
# Conjugates strings into past, simple, and continuous forms
static func conjugator(arg: String):
	if split_check(arg, ["ing"]):
		return verbt_continuous(arg.split(":")[0])
	elif split_check(arg, ["s"]):
		return verbt_simple(arg.split(":")[0])
	elif split_check(arg, ["ed"]):
		return verbt_past(arg.split(":")[0])
	else:
		return arg.split(":")[0]

#--------------------------------------------------------
#Check if first word in string ARGS:0 ends in any specified substring ARGS:1 through ARGS:9
#--------------------------------------------------------
static func word_ends_in(arg: String, substring: Array[String]):
	var regex = RegEx.new()
	var matchStr: String = "^[^\\s]*("
	for i in range(substring.size()):
		var a = substring[i]
		if i > 0:
			matchStr += "|"
		matchStr += a
	matchStr += ")(?=\\s|$)"
	regex.compile(matchStr)
	return (regex.search(arg) != null)

#--------------------------------------------------------
#changes verbs to present continuous tense (ing), not exactly correct on the CVC rule for multi-syllable words
#note this function acts on the first word of the string
#--------------------------------------------------------
static func verbt_continuous(arg: String):
	var regex = RegEx.new()
	if word_ends_in(arg, ["[^aieou][aeiou][^aeiouwxy]"]): #complicated to explain... CVC rule for doubling last letter + some exception
		regex.compile("(^[^\\s]*[^aieou][aeiou]([^aeiouwxy]))(?=\\s|$)")
		arg = regex.sub(arg,"$1$2ing")
	elif word_ends_in(arg, ["ie"]): #if word ends in "ie", drop and add "ying"
		regex.compile("(^[^\\s]+)ie(?=\\s|$)")
		arg = regex.sub(arg,"$1ying")
	elif word_ends_in(arg, ["[^aeiou]e"]): #if word ends in silent "e", drop and add "ing"
		regex.compile("(^[^\\s]+[^aeiou])e(?=\\s|$)")
		arg = regex.sub(arg,"$1ing")
	elif word_ends_in(arg, ["sue"]): #try resolving the problem with words like sue, issue, pursue, etc
		regex.compile("(^[^\\s]+)e(?=\\s|$)")
		arg = regex.sub(arg,"$1ing")
	else:
		regex.compile("(^[^\\s]+)(?=\\s|$)")
		arg = regex.sub(arg,"$1ing")
	return arg
	
#--------------------------------------------------------
#changes verbs to 3rd person simple present tense (s)
#note this function acts on the first word of the string
#--------------------------------------------------------
static func verbt_simple(arg: String):
	var regex = RegEx.new()
	if word_ends_in(arg, ["[^aeiou]y"]): #if last letter is "y" not preceded by a vowel, drop it and add "ies"
		regex.compile("(^[^\\s]+[^aeiou])y(?=\\s|$)")
		arg = regex.sub(arg,"$1ies")
	elif word_ends_in(arg, ["x", "s", "ch", "sh", "o"]): #if word ends in "x", "s", "ss" "sh", "o" for does or "ch" add "es"
		regex.compile("(^[^\\s]+)(?=\\s|$)")
		arg = regex.sub(arg,"$1es")
	else:
		regex.compile("(^[^\\s]+)(?=\\s|$)")
		arg = regex.sub(arg,"$1s")
	return arg

#--------------------------------------------------------
#changes verbs to past tense (ed)
#note this function acts on the first word of the string
#--------------------------------------------------------
static func verbt_past(arg: String):
	var regex = RegEx.new()
	if irregular_past_verbs(arg) != null:
		regex.compile(arg)
		arg = regex.sub(arg,irregular_past_verbs(arg))
	elif word_ends_in(arg, ["[^aieou][aeiou][^aeiouwxy]"]): #complicated to explain... CVC rule for doubling last letter + some exception
		regex.compile("(^[^\\s]*[^aieou][aeiou]([^aeiouwxy]))(?=\\s|$)")
		arg = regex.sub(arg,"$1$2ed")
	elif word_ends_in(arg, ["[^aieou]y"]): #if word ends in a consonant and "y", change it to "i" and add "ed"
		regex.compile("(^[^\\s]+[^aeiou])y(?=\\s|$)")
		arg = regex.sub(arg,"$1ied")
	elif word_ends_in(arg, ["[aieou]", "ue", "oe", "ie"]): #if word ends in silent "e", drop and add "ing"
		regex.compile("(^[^\\s]+)(?=\\s|$)")
		arg = regex.sub(arg,"$1d")
	else:
		regex.compile("(^[^\\s]+)(?=\\s|$)")
		arg = regex.sub(arg,"$1ed")
	return arg

#--------------------------------------------------------
# check if a word is an irregular verb and return correct past tense form, currently supports only simple past
# for now it also contains only commonly used words
#--------------------------------------------------------
static func irregular_past_verbs(arg: String):
	match arg.to_lower():
		"cum":
			return "came"
		"awake":
			return "awoke"
		"be":
			return "was"
		"beat":
			return "beat"
		"become":
			return "became"
		"begin":
			return "began"
		"bend":
			return "bent"
		"bet":
			return "bet"
		"bid":
			return "bid"
		"bind":
			return "bound"
		"bite":
			return "bit"
		"bleed":
			return "bled"
		"blow":
			return "blew"
		"break":
			return "broke"
		"breed":
			return "bred"
		"bring":
			return "brought"
		"build":
			return "built"
		"burn":
			return "burnt"
		"burst":
			return "burst"
		"buy":
			return "bought"
		"can":
			return "could"
		"cast":
			return "cast"
		"catch":
			return "caught"
		"choose":
			return "chose"
		"cling":
			return "clung"
		"come":
			return "came"
		"cost":
			return "cost"
		"cut":
			return "cut"
		"deal":
			return "dealt"
		"dig":
			return "dug"
		"do":
			return "did"
		"draw":
			return "drew"
		"drink":
			return "drank"
		"drive":
			return "drove"
		"eat":
			return "ate"
		"fall":
			return "fell"
		"feed":
			return "fed"
		"feel":
			return "felt"
		"fight":
			return "fought"
		"find":
			return "found"
		"flee":
			return "fled"
		"fly":
			return "flew"
		"forbid":
			return "forbade"
		"forecast":
			return "forecast"
		"forget":
			return "forgot"
		"forsake":
			return "forsook"
		"freeze":
			return "froze"
		"get":
			return "got"
		"give":
			return "gave"
		"go":
			return "went"
		"grind":
			return "ground"
		"grow":
			return "grew"
		"hang":
			return "hung"
		"have":
			return "had"
		"hear":
			return "heard"
		"hide":
			return "hid"
		"hit":
			return "hit"
		"hold":
			return "held"
		"hurt":
			return "hurt"
		"keep":
			return "kept"
		"kneel":
			return "knelt"
		"know":
			return "knew"
		"lay":
			return "laid"
		"lead":
			return "led"
		"leave":
			return "left"
		"lend":
			return "lent"
		"let":
			return "let"
		"lie":
			return "lay"
		"light":
			return "lit"
		"lose":
			return "lost"
		"make":
			return "made"
		"may":
			return "might"
		"mean":
			return "meant"
		"meet":
			return "met"
		"pay":
			return "paid"
		"put":
			return "put"
		"quit":
			return "quit"
		"read":
			return "read"
		"rid":
			return "rid"
		"ride":
			return "rode"
		"ring":
			return "rang"
		"rise":
			return "rose"
		"run":
			return "ran"
		"say":
			return "said"
		"see":
			return "saw"
		"seek":
			return "sought"
		"sell":
			return "sold"
		"send":
			return "sent"
		"set":
			return "set"
		"shake":
			return "shook"
		"shall":
			return "should"
		"shed":
			return "shed"
		"shoot":
			return "shot"
		"shit":
			return "shat"
		"shrink":
			return "shrank"
		"shut":
			return "shut"
		"sing":
			return "sang"
		"sink":
			return "sank"
		"sit":
			return "sat"
		"slay":
			return "slew"
		"sleep":
			return "slept"
		"slide":
			return "slid"
		"sling":
			return "slung"
		"slit":
			return "slit"
		"smite":
			return "smote"
		"speak":
			return "spoke"
		"speed":
			return "sped"
		"spend":
			return "spent"
		"spin":
			return "spun"
		"spit":
			return "spat"
		"split":
			return "split"
		"spread":
			return "spread"
		"spring":
			return "sprang"
		"stand":
			return "stood"
		"steal":
			return "stole"
		"stick":
			return "stuck"
		"sting":
			return "stung"
		"stink":
			return "stank"
		"stride":
			return "strode"
		"strike":
			return "struck"
		"string":
			return "strung"
		"strive":
			return "strove"
		"swear":
			return "swore"
		"sweat":
			return "sweat"
		"sweep":
			return "swept"
		"swim":
			return "swam"
		"swing":
			return "swung"
		"take":
			return "took"
		"teach":
			return "taught"
		"tear":
			return "tore"
		"tell":
			return "told"
		"think":
			return "thought"
		"throw":
			return "threw"
		"thrust":
			return "thrust"
		"tread":
			return "trod"
		"understand":
			return "understood"
		"wake":
			return "woke"
		"wear":
			return "wore"
		"weave":
			return "wove"
		"weep":
			return "wept"
		"wet":
			return "wet"
		"win":
			return "won"
		"wind":
			return "wound"
		"wring":
			return "wrung"
		"write":
			return "wrote"

static func special_verbs(arg: String):
	match arg.to_lower():
		"have":
			return "has"
		"haven't":
			return "hasn't"
		"are":
			return "is"
		"aren't":
			return "isn't"
		"were":
			return "was"
		"weren't":
			return "wasn't"
		"don't":
			return "doesn't"
