
#!/usr/bin

from twisted.internet import reactor
from twisted.internet import protocol
from twisted.application import service
from twisted.application import internet
from twisted.protocols.basic import LineReceiver
from twisted.python import log
from twisted.web.client import getPage
import time
import datetime
import logging
import re
import sys
import json

GOOGLE_API_KEY = "AIzaSyDPj7m6LZt0aU78xX0-C-_zVFR01I3eO_s"
GOOGLE_PLACES_API_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"

serverHerdDict = {
	"Alford" : {
		"portNumber" : 5027,
		"neighbors" : ["Parker", "Welsh"]
	},
	
	"Bolden" : {
		"portNumber" : 5028,
		"neighbors" : ["Parker", "Welsh"]
	},

	"Hamilton" : {
		"portNumber" : 5029,
		"neighbors": ["Parker"]
	},

	"Parker" : {
		"portNumber" : 5030,
		"neighbors" :["Alford", "Bolden", "Hamilton"]
	},

	"Welsh" : {
		"portNumber" : 5031,
		"neighbors": ["Alford", "Bolden"]
	}
}

class herdServerProtocol(LineReceiver):
	def __init__(self, factory):
		self.factory = factory

	def connectionMade(self):
		logging.info("Successfully established Connection!")

	def lineReceived(self, message):
		logMessage = "Recieved message:" + "\n" + message
		logging.info(logMessage)
		tokens = message.split(" ")

		if (tokens[0] == "IAMAT"):
			self.funcIAMAT(message)
		elif (tokens[0] == "WHATSAT"):
			self.funcWHATSAT(message)
		elif (tokens[0] == "AT"):
			self.funcAT(message)
		else:
			logging.info("Error: message contents not valid")
			self.transport.write("? " + message + "\n")
		return

	def funcIAMAT(self, message):
		tokens = message.split(" ")
		if len(tokens) != 4:
			logging.info("Error: message contents not valid. Incorrect number of elements")
			self.transport.write("? " + message + "\n")
			return

		commandID = tokens[0]
		clientID = tokens[1]
		latLong = tokens[2]
		clientTimeSent = tokens[3]

		time_diff =  time.time() - float(clientTimeSent)

		if time_diff >= 0:
			response = "AT {0} +{1} {2} {3} {4} {5}".format(self.factory.serverName,
				time_diff, commandID, clientID, latLong, clientTimeSent)
		else:
			response = "AT {0} {1} {2} {3} {4} {5}".format(self.factory.serverName,
				time_diff, commandID, clientID, latLong, clientTimeSent)

		if clientID in self.factory.clients:
			logMessage = "Messaged recieved from preexisting client " + clientID
			logging.info(logMessage)
		else:
			logMessage = "Messaged recieved from new client " + clientID
			logging.info(logMessage)

		self.factory.clients[clientID] = {
			"message":response, 
			"time":clientTimeSent
		}

		logMessage = "Server " + self.factory.serverName + " response message: " + response
		logging.info(logMessage)
		self.transport.write(response + "\n")

		logging.info("Flooding location to neighbors")
		self.flood(response)

	def funcWHATSAT(self, message):
		tokens = message.split()
		if len(tokens) != 4:
			logging.info("Error: message contents not valid. Incorrect number of elements")
			self.transport.write("? " + message + "\n")
			return
		

		commandID = tokens[0]
		clientID = tokens[1]
		radius = tokens[2]
		infoBound = tokens[3]

		cachedResponse = self.factory.clients[clientID]["message"]
		logging.info("Cached response: " + cachedResponse)

		tokens2 = cachedResponse.split()
		location = tokens2[5]

		location = re.sub(r'[-]', ' -', location)
		location = re.sub(r'[+]', ' +', location).split()
		locationFormatted = location[0] + "," + location[1]

		GoogleAPIRequest = "{0}location={1}&radius={2}&key={3}".format(
			GOOGLE_PLACES_API_URL, locationFormatted, radius, GOOGLE_API_KEY)
		logging.info("Made Google Places API request: " + GoogleAPIRequest)
		GoogleAPIResponse = getPage(GoogleAPIRequest)
		GoogleAPIResponse.addCallback(callback = lambda x:(self.printJSON(x, clientID, infoBound)))

	def funcAT(self, message):
		tokens = message.split()
		if len(tokens) != 7:
			logging.error("Error: message contents not valid. Incorrect number of elements")
			self.transport.write("? " + message + "\n")
			return

		ATCommand = tokens[0]
		serverID = tokens[1]
		timeDiff = tokens[2]
		commandID = tokens[3]
		clientID = tokens[4]
		latLong = tokens[5]
		clientTimeSent = tokens[6]

		if clientID in self.factory.clients:
			if clientTimeSent <= self.factory.clients[clientID]["time"]:
				logging.info("Already received this location update. Stop flooding location message.")
			else:	
				logMessage = "Updated location recieved from preexisting client " + clientID
				logging.info(logMessage)
		else:
			logMessage = "Updated location recieved from new client " + clientID
			logging.info(logMessage)

		self.factory.clients[clientID] = { 
			"message" : ("{0} {1} {2} {3} {4} {5} {6}".format(ATCommand, serverID, timeDiff, commandID, clientID, latLong, clientTimeSent)), 
			"time" : clientTimeSent 
			}

		logMessage = "Added " + clientID + " with message: " + self.factory.clients[clientID]["message"]
		logging.info(logMessage)

		self.flood(self.factory.clients[clientID]["message"])
		return

	def printJSON(self, googlePlacesResponse, clientID, infoBound):
		JSONData = json.loads(googlePlacesResponse)
		results = JSONData["results"]
		JSONData["results"] = results[0:int(infoBound)]
		JSONDump = json.dumps(JSONData, indent = 3)
		logging.info("API Response: " + JSONDump)
		message = self.factory.clients[clientID]["message"]
		responseWithJSON = message + "\n" + JSONDump + "\n\n"
		self.transport.write(responseWithJSON)

	def flood(self, responseMessage):
		neighborList = serverHerdDict[self.factory.serverName]["neighbors"]
		for neighbor in neighborList:
			reactor.connectTCP('localhost',serverHerdDict[neighbor]["portNumber"], herdClientFactory(responseMessage))
			logMessage = "Updated location sent: " + self.factory.serverName + " -> " + neighbor
			logging.info(logMessage)
		return

	def connectionLost(self, reason):
		logging.info("Lost connection")

class herdServerFactory(protocol.ServerFactory):
	def __init__(self, serverName):
		self.serverName = serverName
		self.portID = serverHerdDict[self.serverName]["portNumber"]
		self.clients = {}
		filename = self.serverName + ".log"
		logging.basicConfig(filename = filename, level=logging.DEBUG)
		logging.info('Initialized server {0} with corresponding port number {1}'.format(serverName, self.portID))


	def buildProtocol(self, address):
		return herdServerProtocol(self)

	def stopFactory(self):
		logging.info(self.serverName + " has shutdown")

class herdClientProtocol(LineReceiver):
	def __init__ (self, factory):
		self.factory = factory

	def connectionMade(self):
		self.sendLine(self.factory.message)
		self.transport.loseConnection()

class herdClientFactory(protocol.ClientFactory):
	def __init__(self, message):
		self.message = message

	def buildProtocol(self, address):
		return herdClientProtocol(self)

if __name__ == '__main__':
	if len(sys.argv) != 2:
		print("Error: this program requires two arguments")
		exit()
	newServerfactory = herdServerFactory(sys.argv[1])
	reactor.listenTCP(serverHerdDict[sys.argv[1]]["portNumber"], newServerfactory)
	reactor.run()
