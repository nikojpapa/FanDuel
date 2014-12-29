require 'mail'
require 'selenium-webdriver'
require 'pp'
require 'ruby-notify-my-android'

abbrevs = {
	"Arizona"=> "ARI",
	"Atlanta"=> "ATL",
	"Baltimore"=> "BAL",
	"Buffalo"=> "BUF",
	"Carolina"=> "CAR",
	"Chicago"=> "CHI",
	"Cincinnati"=> "CIN",
	"Cleveland"=> "CLE",
	"Dallas"=> "DAL",
	"Denver"=> "DEN",
	"Detroit"=> "DET",
	"Green Bay"=> "GB",
	"Houston"=> "HOU",
	"Indianapolis"=> "IND",
	"Jacksonville"=> "JAX",
	"Kansas City"=> "KC",
	"Miami"=> "MIA",
	"Minnesota"=> "MIN",
	"New England"=> "NE",
	"New Orleans"=> "NO",
	"New York"=> "NYG",
	"New York"=> "NYJ",
	"Oakland"=> "OAK",
	"Philadelphia"=> "PHI",
	"Pittsburgh"=> "PIT",
	"San Diego"=> "SD",
	"Seattle"=> "SEA",
	"San Francisco"=> "SF",
	"St. Louis"=> "STL",
	"Tennessee"=> "TEN",
	"Tampa Bay"=> "TB",
	"Washington"=>" WSH"
}

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

def email(subject, body)
	Mail.deliver do
	  from     'FanDuel Update'
	  to       '8608191255@vtext.com'
	  subject  subject
	  body     body
	end
end

def notify(subject, body)
	NMA.notify do |n| 
	  n.apikey = "7ab69fd514c41a71749b097b786fafe46ec938411dac8d16"
	  n.priority = NMA::Priority::MODERATE
	  n.application = "FanDuel Update"
	  n.event = body
	  n.description = subject
	end
end

def getElementText(by)

	begin
		if by.is_a?(Hash)
			return @driver.find_element(by).text
		else
			return by.text
		end
	rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
		staleRetries ||= 0
		staleRetries += 1
		if staleRetries < 3
			retry
		else
			return nil
			# waitForSkip(true)
			# raise e
		end
	rescue Selenium::WebDriver::Error::NoSuchElementError => e
		noneRetries ||= 0
		noneRetries += 1
		if noneRetries < 3
			retry
		else
			return nil
			# waitForSkip(true)
			# raise e
		end
	end
end

def getElementAttribute(by, attrib)

	begin
		if by.is_a?(Hash)
			return @driver.find_element(by).attribute(attrib)
		else
			return by.attribute(attrib)
		end
	rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
		staleRetries ||= 0
		staleRetries += 1
		if staleRetries < 3
			retry
		else
			return nil
			# waitForSkip(true)
			# raise e
		end
	rescue Selenium::WebDriver::Error::NoSuchElementError => e
		noneRetries ||= 0
		noneRetries += 1
		if noneRetries < 3
			retry
		else
			return nil
			# waitForSkip(true)
			# raise e
		end
	end
end

def waitForSkip(finish)
	wait = Selenium::WebDriver::Wait.new(:timeout => 30) # seconds
	begin
		wait.until { @driver.find_element(:id => "skip").attribute("style") == "display: inline;" }
		@driver.find_element(:id => "skip").click
	rescue
		if finish
			puts "Skip not found"
			@driver.quit
		end
	end
end

def waitForElement(by, driver)
	wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
	wait.until { driver.find_element( by ) }
end

def getGameIDs(currentGames, team)

	driver = Selenium::WebDriver.for :chrome
	driver.get "http://scores.espn.go.com/nfl/gamecast"

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
	gamecastGames = driver.find_elements(:xpath => "//*/ul[@id='oot-games']/li/div[@class='oot-game-link']/div[@class='teams']").map {|x| getElementText(x)}
	gamecastGameClocks = driver.find_elements(:xpath => "//*/ul[@id='oot-games']/li/div[@class='oot-game-link']/div[@class='status']/div[@class='clock']").map {|x| getElementText(x)}
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

@drivers = []
def startDrivers(gameIds)
	gameIds.each_with_index do |id, index|
		driverNum = @drivers.length
		@drivers[driverNum] = Selenium::WebDriver.for :chrome
		@drivers[driverNum].get "http://scores.espn.go.com/nfl/gamecast?gameId=#{id}"
	end
end

@lastUpdates = {}
def getNFLUpdates(team)
	@drivers.each_with_index do |driver, i|
		@driver = driver
	
		gcClock = getElementText({:class => "gc-clock"})
		if gcClock != "Final"
			waitForSkip(false)

			homeTeam = getElementText({:xpath => "//div[@id='content-wrap']/div[@id='linescore']/div[@class='linescore clear']/table/tbody/tr[@class='home']/td[@class='gc-team']/a"})
			awayTeam = getElementText(:xpath => "//div[@id='content-wrap']/div[@id='linescore']/div[@class='linescore clear']/table/tbody/tr[@class='away']/td[@class='gc-team']/a")

			puts "#{homeTeam} VS #{awayTeam} (#{rand})"

			if gcClock.include?("1st") or gcClock.include?("2nd") or gcClock.include?("3rd") or gcClock.include?("4th") or gcClock.include?("Halftime")

				homeTeamPlayers = []
				awayTeamPlayers = []
				playersInGame = {}
				lastTeamWithBall = ""
				lastUpdate = ""
				if not @lastUpdates["#{homeTeam}#{awayTeam}"]
					@lastUpdates["#{homeTeam}#{awayTeam}"] = {}
					
					team.each do |name, info|
						if info["team"] == homeTeam
							homeTeamPlayers << "#{name} #{info['pos']}"
							playersInGame[name] = info
						elsif info["team"] == awayTeam
							awayTeamPlayers << "#{name} #{info['pos']}"
							playersInGame[name] = info
						end
					end

					@lastUpdates["#{homeTeam}#{awayTeam}"][:homeTeamPlayers] = homeTeamPlayers
					@lastUpdates["#{homeTeam}#{awayTeam}"][:awayTeamPlayers] = awayTeamPlayers
					@lastUpdates["#{homeTeam}#{awayTeam}"][:playersInGame] = playersInGame
					@lastUpdates["#{homeTeam}#{awayTeam}"][:lastTeamWithBall] = ""
					@lastUpdates["#{homeTeam}#{awayTeam}"][:lastUpdate] = ""
				else
					homeTeamPlayers = @lastUpdates["#{homeTeam}#{awayTeam}"][:homeTeamPlayers]
					awayTeamPlayers = @lastUpdates["#{homeTeam}#{awayTeam}"][:awayTeamPlayers]
					playersInGame = @lastUpdates["#{homeTeam}#{awayTeam}"][:playersInGame]
					lastTeamWithBall = @lastUpdates["#{homeTeam}#{awayTeam}"][:lastTeamWithBall]
					lastUpdate = @lastUpdates["#{homeTeam}#{awayTeam}"][:lastUpdate]
				end

				homeTeamBall = getElementAttribute({:xpath => "//*/div[@id='homeScoreBox']/div[contains(@class, 'gc-ball')]"}, "class")
				awayTeamBall = getElementAttribute({:xpath => "//*/div[@id='awayScoreBox']/div[contains(@class, 'gc-ball')]"}, "class")

				if homeTeamBall.include?("gc-ball-on") and lastTeamWithBall != homeTeam
					@lastUpdates["#{homeTeam}#{awayTeam}"][:lastTeamWithBall] = homeTeam
					notify("#{homeTeam} has the ball", "Root for #{homeTeamPlayers.join(', ')}")
				elsif awayTeamBall.include?("gc-ball-on") and lastTeamWithBall != awayTeam
					@lastUpdates["#{homeTeam}#{awayTeam}"][:lastTeamWithBall] = awayTeam
					notify("#{awayTeam} has the ball", "Root for #{awayTeamPlayers.join(', ')}")
				end

				lastPlay = getElementText({:xpath => "//*[@id='lastPlay-text']"})
				if lastPlay.include?("END QUARTER")
					if lastUpdate != lastPlay
						@lastUpdates["#{homeTeam}#{awayTeam}"][:lastUpdate] = lastPlay
						notify("Quarter End", lastPlay)
					end
				else
					playersInGame.keys.each do |name|
						lastNameStart = name.rindex(" ") + 1
						abbrevName = "#{name[0]}.#{name[lastNameStart, name.length - lastNameStart]}"
						if lastPlay.include?(abbrevName) and lastUpdate != lastPlay
							@lastUpdates["#{homeTeam}#{awayTeam}"][:lastUpdate] = lastPlay
							notify(name, lastPlay)
						end
					end
				end
			else
				puts "    Hasn't Started"
			end
		else
			driver.quit
			@drivers[i] = nil
			@drivers.compact!
		end
	end
end

def startNFL(currentGames, team)
	gameIds = getGameIDs(currentGames, team)
	startDrivers(gameIds)

	while @drivers.length > 0
		getNFLUpdates(team)
	end
end













