require './nfl'
require 'mail'
require 'selenium-webdriver'

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

def email(subject, body)
	Mail.deliver do
	  from     'FanDuel Update'
	  to       '8608191255@vtext.com'
	  subject  subject
	  body     body
	end
end

def openPage(url, driverNum)
	@drivers[driverNum] = Selenium::WebDriver.for :chrome
	@drivers[driverNum].get url
end

openPage("https://www.fanduel.com/p/MyLiveEntries", 0)

if @drivers[0].find_element(:xpath => "//*[@id='body']").attribute("class").include?("logged-out")
	@drivers[0].execute_script("return document.getElementById('email').value = '#{yourEmail}';")
	@drivers[0].execute_script("return document.getElementById('password').value = '#{yourPassword}';")
	@drivers[0].find_element(:xpath => "//*/input[@type='submit']").click
end

@drivers[0].find_elements(:xpath => "//*/td[@class='id']/a").each_with_index do |id, i|
	url = id.attribute("href")
	driverNum = i + 1
	openPage(url, driverNum)
	thisDriver = @drivers[driverNum]

	if thisDriver.find_element(:id => "scoring-table-name").text.include?("NFL")
		thisDriver.find_elements(:class => "fixture-card").each do |game|
			puts game
		end
	end

	thisDriver.quit
end

@drivers[0].quit








