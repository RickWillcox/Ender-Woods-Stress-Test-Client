extends Node

var network : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
var gateway_api : MultiplayerAPI = MultiplayerAPI.new()
var port : int = 1910
var dedicated_server_ip : String = "45.58.43.202"
var local_ip : String = "127.0.0.1"
var login_ip : String = "127.0.0.1"
var connected : bool = false
var username : String 
var password : String = "1"
var new_account : bool = true
var cert : Resource = load("res://Assets/Certificate/X509_Certificate.crt")

var characters = 'abcdefghijklmnopqrstuvwxyz'

onready var Server = get_parent()

func _ready():
	randomize()
	username = generate_word(characters, 25)
	connect_to_server(username, password, true)

func _process(_delta):
	if get_custom_multiplayer() == null:
		return
	if not custom_multiplayer.has_network_peer():
		return;
	custom_multiplayer.poll();
		
func connect_to_server(_username : String, _password : String, _new_account : bool):
	network = NetworkedMultiplayerENet.new()
	gateway_api = MultiplayerAPI.new()
	network.set_dtls_enabled(true)
	network.set_dtls_verify_enabled(false) #set to true when using signed cert (this is for testing only)
	network.set_dtls_certificate(cert)
	username = _username
	password = _password
	new_account = _new_account
	network.create_client(dedicated_server_ip, port)
	set_custom_multiplayer(gateway_api)
	custom_multiplayer.set_root_node(self)
	custom_multiplayer.set_network_peer(network)
	
	network.connect("connection_succeeded", self, "_on_connection_succeeded")	
	network.connect("connection_failed", self, "_on_connection_failed")

func _on_connection_failed():	
	print("Failed to connect to the login server")
	
func _on_connection_succeeded():
	connected = true
	print("Successfully connected to login server")
	if not new_account:
		request_login()
		print("request login done")
	else:
		request_create_account()

func request_create_account():
	print("Requesting to make new account")
	rpc_id(1, "create_account_request", username, password.sha256_text())
	
func request_login():
	print("Connecting to gateway to request login")
	rpc_id(1, "login_request", username, password.sha256_text())

remote func return_login_request(results : bool, token : String):
	print("Login results received: Result: %s | Token: %s" % [results, token])
	if results == true:
		Server.token = token
		Server.connect_to_server()
	else:
		print("Login Failed -- Please provide a valid username and password")

#	network.disconnect("connection_failed", self, "_on_connection_failed")
#	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	
# warning-ignore:unused_argument
remote func return_create_account_request(valid_request : bool, message : int):
	#1 = failed to create, 2 = username already in use, 3 = account created successfully
	if valid_request == true:
		print("Account Created")
		yield(get_tree().create_timer(2),"timeout")
		request_login()
	elif message == 1:
		print("Couldnt Create Account, please try again")
	elif message == 2:
		print("Username already exists")

	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")

func generate_word(chars, length):
	var word: String
	var n_char = len(chars)
	for i in range(length):
		word += chars[randi()% n_char]
	return word
