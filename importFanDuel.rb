require './nfl'
require 'mail'
require 'selenium-webdriver'
require 'pp'

yourEmail = "nicholas.papadopoulos@comcast.net"
yourPassword = "fdk11lKake"

options = { :address              => "smtp.gmail.com",
            :port                 => 587,
            :domain               => 'your.host.name',
            :user_name            => 'npapa@bu.edu',
            :password             => 'K11lKake!!',
            :authentication       => 'plain',
            :enable_starttls_auto => true  }

Mail.defaults do
  delivery_method :smtp, options
end

@drivers = []

def openPage(url, driverNum)
	@drivers[driverNum] = Selenium::WebDriver.for :chrome
	@drivers[driverNum].get url
end

@wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
def waitForElement(element, driver)
	@wait.until { driver.find_element( element ) }
end

driver0 = Selenium::WebDriver.for :chrome
driver0.get "https://www.fanduel.com/p/MyLiveEntries"

waitForElement({:xpath => "//*[@id='body']"}, driver0)
if driver0.find_element(:xpath => "//*[@id='body']").attribute("class").include?("logged-out")
	driver0.execute_script("return document.getElementById('email').value = '#{yourEmail}';")
	driver0.execute_script("return document.getElementById('password').value = '#{yourPassword}';")
	driver0.find_element(:xpath => "//*/input[@type='submit']").click
end

@teams = {}
@drivers = {}

def getGameIDs(currentGames, team, league)

	driver = Selenium::WebDriver.for :chrome
	driver.get "http://scores.espn.go.com/#{league}/gamecast"

	allIds = []
	waitForElement({:xpath => "//*/ul[@id='oot-games']/li"}, driver)
	driver.find_elements(:xpath => "//*/ul[@id='oot-games']/li").each do |id|
		id = id.attribute("id")
		allIds << id[4..id.length]
	end
	# pp allIds
	driver.find_element(:id => "oot-right").click
	driver.find_element(:id => "oot-right").click
	driver.find_element(:id => "oot-right").click
	driver.find_element(:id => "oot-right").click
	driver.find_element(:id => "oot-right").click
	gamecastGames = driver.find_elements(:xpath => "//*/ul[@id='oot-games']/li/div[@class='oot-game-link']/div[@class='teams']").map {|x| getElementText(x, driver)}
	gamecastGameClocks = driver.find_elements(:xpath => "//*/ul[@id='oot-games']/li/div[@class='oot-game-link']/div[@class='status']/div[@class='clock']").map {|x| getElementText(x, driver)}
	pp gamecastGames

	ids = []
	allIds.each do |id|
		index = allIds.index(id)
		currentGames.each do |teams|
			if gamecastGames[index].include?(teams[0]) and gamecastGames[index].include?(teams[1]) and not gamecastGameClocks[index].include?("Final")
				ids << id
			end
		end
	end
	
	driver.quit
	pp ids
	return ids
end

def startDrivers(gameIds, teamID, league)
	@teams[teamID]["gameIDs"] ||= []

	gameIds.each_with_index do |id, index|
		@teams[teamID]["gameIDs"] << id
		@drivers[id] = Selenium::WebDriver.for :chrome
		@drivers[id].get "http://scores.espn.go.com/#{league}/gamecast?gameId=#{id}"
	end
end


waitForElement({:xpath => "//*/td[@class='id']/a"}, driver0)
driver0.find_elements(:xpath => "//*/td[@class='id']/a").each_with_index do |id, i|
	@teams[id.text] = {}
	@teams[id.text]["currentGames"] = []
	@teams[id.text]["players"] = {}
	currentGames = @teams[id.text]["currentGames"]
	team = @teams[id.text]["players"]

	url = id.attribute("href")
	thisDriver = Selenium::WebDriver.for :chrome
	thisDriver.get url

	waitForElement({:xpath => "//*/div[@class='roster']/div/div/div/div[@class='name']"}, thisDriver)
	thisDriver.find_elements(:xpath => "//*/div[@class='roster']/div/div/div/div[@class='name']").each do |name|
		team[name.text] = {}
	end

	thisDriver.find_elements(:xpath => "//*/div[@class='roster']/div/div/div/div[@class='pos']").each_with_index do |pos, index|
		team.keys.each_with_index do |name, ind|
			if ind == index
				team[name]["pos"] = pos.text
				break
			end
		end
	end

	thisDriver.find_elements(:xpath => "//*/div[@class='roster']/div/div/div/div[@class='fixture-info']/div/span[contains(@class, 'player-team-highlight')]").each_with_index do |t, index|
		team.keys.each_with_index do |name, ind|
			if ind == index
				team[name]["team"] = t.text
				break
			end
		end
	end

	thisDriver.find_elements(:class => "fixture-card").each do |game|
		info = game.text

		firstTeamEnd = info.index(/[^A-Z]/) - 1
		secondTeamStart = info.index(/[A-Z]/, firstTeamEnd+1)
		secondTeamEnd = info.index(/[^A-Z]/, secondTeamStart) - 1
		currentGames << [info[0..firstTeamEnd], info[secondTeamStart..secondTeamEnd]]
	end

	currentGames.each_with_index do |teams, index|
		important = false
		team.values.each do |playerInfo|
			if teams.include?(playerInfo["team"])
				important = true
			end
		end

		if important == false
			currentGames[index] = nil
		end
	end
	currentGames.compact!

	if thisDriver.find_element(:id => "scoring-table-name").text.include?("NFL")
		@teams[id.text]["league"] = "nfl"

		team.each do |name, info|
			if info["pos"] == "D"
				currentGames.each do |teams|
					if teams.include?(info["team"])
						otherTeamIndex = 1 - teams.index(info["team"])
						info["team"] = teams[otherTeamIndex]
						break
					end
				end
				break
			end
		end

		pp team

		gameIds = getGameIDs(currentGames, team, "nfl")
		startDrivers(gameIds, id.text, "nfl")

	elsif thisDriver.find_element(:id => "scoring-table-name").text.include?("NBA")
		@teams[id.text]["league"] = "nba"

		pp team

		gameIds = getGameIDs(currentGames, team, "nba")
		startDrivers(gameIds, id.text, "nba")
	end

	thisDriver.quit

end

driver0.quit

while true
	teamsDone = 0
	@teams.each do |teamID, info|
		gameIDs = info["gameIds"]
		league = info["league"]
		players = info["players"]

		finishedGames = 0
		gameIDs.each_with_index do |id, ind|
			driver = @drivers[id]

			if driver != nil
				if league == "nfl"
					@drivers[id] = getNFLUpdates(playeres, driver)
				elsif league == "nba"
					@drivers[id] = getNBAUpdates(players, driver)
				end
			else
				finishedGames += 1
			end
		end

		if finishedGames.length == gameIDs.length
			teamsDone += 1
		end
	end

	if teamsDone == @teams.length
		break
	end
end






