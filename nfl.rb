
gameID = 400554427
team = {
	"Brandon Weeden"=> {"pos"=> "QB", "team"=> "DAL"},
	"DeMarco Murray"=> {"pos"=> "RB", "team"=> "DAL"},
	"Mark Ingram"=> {"pos"=> "RB", "team"=> "NO"},
	"Jeremy Maclin"=> {"pos"=> "WR", "team"=> "PHI"},
	"Kenny Stills"=> {"pos"=> "WR", "team"=> "NO"},
	"Jordan Matthews"=> {"pos"=> "WR", "team"=> "PHI"},
	"Martellus Bennett"=> {"pos"=> "TE", "team"=> "CHI"},
	"Dan Bailey"=> {"pos"=> "K", "team"=> "DAL"}
}

require 'mail'
require 'selenium-webdriver'

abrevs = {
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

def getElementText(by)

	begin
		return @driver.find_element(by).text
	rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
		retries ||= 0
		retries += 1
		if retries < 3
			retry
		else
			waitForSkip(true)
			raise e
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

def getNFLUpdates(gameID, team)
	@driver = Selenium::WebDriver.for :chrome
	@driver.get "http://scores.espn.go.com/nfl/gamecast?gameId=#{gameID}"
	
	if getElementText({:class => "gc-clock"}) != "Final"
		waitForSkip(false)

		homeTeam = getElementText({:xpath => "//div[@id='content-wrap']/div[@id='linescore']/div[@class='linescore clear']/table/tbody/tr[@class='home']/td[@class='gc-team']/a"})
		awayTeam = getElementText(:xpath => "//div[@id='content-wrap']/div[@id='linescore']/div[@class='linescore clear']/table/tbody/tr[@class='away']/td[@class='gc-team']/a")
		puts "#{homeTeam} VS #{awayTeam}"

		homeTeamPlayers = []
		awayTeamPlayers = []
		playersInGame = {}
		team.each do |name, info|
			if info["team"] == homeTeam
				homeTeamPlayers << "#{name} #{info['pos']}"
				playersInGame[name] = info
			elsif info["team"] == awayTeam
				awayTeamPlayers << "#{name} #{info['pos']}"
				playersInGame[name] = info
			end
		end

		lastTeamWithBall = ""
		lastUpdate = ""
		while getElementText({:class => 'gc-clock'}) != "Final"
			driveInfo = getElementText({:xpath => "//div[@id='content-wrap']/div[@id='info-box']/div[@id='plays-tab']/ul/li[contains(@class,'feed-mod play drive expanded  ')]/p[@class='play-text expander']/a"})
			#puts driveInfo
			if driveInfo.include?(homeTeam) and lastTeamWithBall != homeTeam
				lastTeamWithBall = homeTeam
				email("#{homeTeam} has the ball", "Root for #{homeTeamPlayers.join(', ')}")
			elsif driveInfo.include?(awayTeam) and lastTeamWithBall != awayTeam
				lastTeamWithBall = awayTeam
				email("#{awayTeam} has the ball", "Root for #{awayTeamPlayers.join(', ')}")
			end

			lastPlay = getElementText({:xpath => "//*[@id='lastPlay-text']"})
			playersInGame.keys.each do |name|
				lastNameStart = name.rindex(" ") + 1
				abbrevName = "#{name[0]}.#{name[lastNameStart, name.length - lastNameStart]}"
				if lastPlay.include?(abbrevName) and lastUpdate != lastPlay
					lastUpdate = lastPlay
					email(name, lastPlay)
				end
			end
	  	end
		@driver.quit
	end
end

#getNFLUpdates(gameID, team)












