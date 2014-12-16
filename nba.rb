
gameID = 400578650
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

require 'open-uri'
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

driver = Selenium::WebDriver.for :chrome
driver.get "http://scores.espn.go.com/nfl/gamecast?gameId=#{gameID}"

wait = Selenium::WebDriver::Wait.new(:timeout => 30) # seconds
begin
	if driver.find_element(:class => "gc-clock").text != "Final"
		element = wait.until { driver.find_element(:id => "skip").attribute("style") == "display: inline;" }
		driver.find_element(:id => "skip").click
	end
ensure
	homeTeam = driver.find_element(:xpath => "//div[@id='content-wrap']/div[@id='linescore']/ul[@class='period-scores']/li[@class='team-abbrevs']").size
	puts homeTeam
	awayTeam = driver.find_element(:xpath => "//div[@id='content-wrap']/div[@id='linescore']/div[@class='linescore clear']/table/tbody/tr[@class='away']/td[@class='gc-team']/a").text
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
	while driver.find_element(:class => "gc-clock").text != "Final"
		driveInfo = driver.find_element(:xpath => "//div[@id='content-wrap']/div[@id='info-box']/div[@id='plays-tab']/ul/li[@class='feed-mod play drive expanded  ']/p[@class='play-text expander']/a").text
		puts driveInfo
		if driveInfo.include?(homeTeam)
			if lastTeamWithBall != homeTeam
				lastTeamWithBall = homeTeam
				email("#{homeTeam} has the ball", "Root for #{homeTeamPlayers.join(', ')}")
			end
		elsif driveInfo.include?(awayTeam)
			if lastTeamWithBall != awayTeam
				lastTeamWithBall = awayTeam
				email("#{awayTeam} has the ball", "Root for #{awayTeamPlayers.join(', ')}")
			end
		end

		lastPlay = driver.find_element(:xpath => "//div[@id='content-wrap']/div[@id='info-box']/div[@id='plays-tab']/ul/li[@class='feed-mod play drive expanded  ']/ul[@class='plays clear']/li[@class='expanded']/p").text
		playersInGame.keys.each do |name|
			if lastPlay.include?(name) and lastUpdate != lastPlay
				lastUpdate = lastPlay
				email("name", lastPlay)
			end
		end
  	end
	driver.quit
end














