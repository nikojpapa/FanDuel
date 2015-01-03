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
	  n.event = subject
	  n.description = body
	end
end

def getElementText(by, driver, num=0)

	begin
		if by.is_a?(Hash)
			return driver.find_elements(by)[num].text
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

def getElementAttribute(by, attrib, driver, num=0)

	begin
		if by.is_a?(Hash)
			return driver.find_elements(by)[num].attribute(attrib)
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

def waitForSkip(finish, driver)
	wait = Selenium::WebDriver::Wait.new(:timeout => 30) # seconds
	begin
		wait.until { driver.find_element(:id => "skip").attribute("style") == "display: inline;" }
		driver.find_element(:id => "skip").click
	rescue
		if finish
			puts "Skip not found"
			driver.quit
		end
	end
end

def waitForElement(by, driver)
	wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
	wait.until { driver.find_element( by ) }
end

@lastUpdates = {}
def getNFLUpdates(team, drivers)
	drivers["nfl"].each_with_index do |driver, i|
	
		gcClock = getElementText({:class => "gc-clock"}, driver)
		if gcClock != "Final"
			waitForSkip(false, driver)

			homeTeam = getElementText({:xpath => "//div[@id='content-wrap']/div[@id='linescore']/div[@class='linescore clear']/table/tbody/tr[@class='home']/td[@class='gc-team']/a"}, driver)
			awayTeam = getElementText({:xpath => "//div[@id='content-wrap']/div[@id='linescore']/div[@class='linescore clear']/table/tbody/tr[@class='away']/td[@class='gc-team']/a"}, driver)

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

				homeTeamBall = getElementAttribute({:xpath => "//*/div[@id='homeScoreBox']/div[contains(@class, 'gc-ball')]"}, "class", driver)
				awayTeamBall = getElementAttribute({:xpath => "//*/div[@id='awayScoreBox']/div[contains(@class, 'gc-ball')]"}, "class", driver)

				if homeTeamBall.include?("gc-ball-on") and lastTeamWithBall != homeTeam
					@lastUpdates["#{homeTeam}#{awayTeam}"][:lastTeamWithBall] = homeTeam
					notify("#{homeTeam} has the ball", "Root for #{homeTeamPlayers.join(', ')}")
				elsif awayTeamBall.include?("gc-ball-on") and lastTeamWithBall != awayTeam
					@lastUpdates["#{homeTeam}#{awayTeam}"][:lastTeamWithBall] = awayTeam
					notify("#{awayTeam} has the ball", "Root for #{awayTeamPlayers.join(', ')}")
				end

				lastPlay = getElementText({:xpath => "//*[@id='lastPlay-text']"}, driver)
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
			drivers[i] = nil
			drivers.compact!
		end
	end

	return drivers
end

def getNBAUpdates(team, drivers)
	drivers.each_with_index do |driver, i|
	
		if not getElementAttribute({:xpath => "//div[@id='content-wrap']/div[@id='linescore']/ul[@class='period-header']/li[contains(@class, 'current')]"}, "class").include?("end-period")
			waitForSkip(false, driver)

			homeTeam = getElementText({:xpath => "//div[@id='content-wrap']/div[@id='linescore']/ul[@class='period-scores']/li[@class='team-abbrevs']/p"}, driver)
			awayTeam = getElementText({:xpath => "//div[@id='content-wrap']/div[@id='linescore']/ul[@class='period-scores']/li[@class='team-abbrevs']/p"}, driver, 1)

			puts "#{homeTeam} VS #{awayTeam} (#{rand})"

			gcClock = getElementText({:xpath => "//div[@id='content-wrap']/div[@id='linescore']/ul[@class='period-header']/li[contains(@class, 'current')]"}, driver)
			if gcClock.include?("1ST") or gcClock.include?("2ND") or gcClock.include?("3RD") or gcClock.include?("4TH") or gcClock.include?("Halftime")

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

				lastPlay = getElementText({:xpath => "//*[@id='lastPlayList']/li/div[@class='mod-play-text']/p"}, driver)
				if lastPlay.include?("END QUARTER")
					if lastUpdate != lastPlay
						@lastUpdates["#{homeTeam}#{awayTeam}"][:lastUpdate] = lastPlay
						notify("Quarter End", lastPlay)
					end
				else
					playersInGame.keys.each do |name|
						if lastPlay.include?(name) and lastUpdate != lastPlay
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
			drivers[i] = nil
			drivers.compact!
		end
	end

	return drivers
end

def startNFL(currentGames, team)
	gameIds = getNFLGameIDs(currentGames, team)
	startDrivers(gameIds)

	while @drivers["nfl"].length + @drivers["nba"].length > 0
		getNFLUpdates(team)
	end
end













