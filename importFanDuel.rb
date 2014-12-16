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

def email(subject, body)
	Mail.deliver do
	  from     'FanDuel Update'
	  to       '8608191255@vtext.com'
	  subject  subject
	  body     body
	end
end

driver = Selenium::WebDriver.for :chrome
driver.get "https://www.fanduel.com/p/MyLiveEntries"

if driver.find_element(:xpath => "//*[@id='body']").attribute("class").include?("logged-out")
	driver.execute_script("return document.getElementById('email').value = '#{yourEmail}';")
	driver.execute_script("return document.getElementById('password').value = '#{yourPassword}';")
	driver.find_element(:xpath => "//*/input[@type='submit']").click
end

driver.find_elements(:xpath => "//*/td[@class='id']/a")[0].click








