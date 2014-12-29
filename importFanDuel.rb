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

gameDrivers = {}

team = {}
currentNFLGames = []

waitForElement({:xpath => "//*/td[@class='id']/a"}, driver0)
driver0.find_elements(:xpath => "//*/td[@class='id']/a").each_with_index do |id, i|
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

	if thisDriver.find_element(:id => "scoring-table-name").text.include?("NFL")
		thisDriver.find_elements(:class => "fixture-card").each do |game|
			info = game.text

			firstTeamEnd = info.index(/[^A-Z]/) - 1
			secondTeamStart = info.index(/[A-Z]/, firstTeamEnd+1)
			secondTeamEnd = info.index(/[^A-Z]/, secondTeamStart) - 1
			currentNFLGames << [info[0..firstTeamEnd], info[secondTeamStart..secondTeamEnd]]
		end
	end

	thisDriver.quit
end

currentNFLGames.each_with_index do |teams, index|
	important = false
	team.values.each do |playerInfo|
		if teams.include?(playerInfo["team"])
			important = true
		end
	end

	if important == false
		currentNFLGames[index] = nil
	end
end
currentNFLGames.compact!

team.each do |name, info|
	if info["pos"] == "D"
		currentNFLGames.each do |teams|
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
pp currentNFLGames

driver0.quit

startNFL(currentNFLGames, team)








