
gameID = 400554425
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

require 'open-uri'
require 'mail'

Mail.defaults do
  delivery_method :smtp, options
end

getTeamsLines = []
open("http://scores.espn.go.com/nfl/playbyplay?gameId=#{gameID}&period=0") do |f|
	f.each {|line| getTeamsLines << line}
end
getTeamsText = getTeamsLines.join

teamsInGame = {}
lastTeamIndex = 0
for i in 0..1
	startTeamSearch = getTeamsText.index("<td class=\"team\">", lastTeamIndex)
	endTeamSearch = getTeamsText.index("</a>", startTeamSearch)
	lastTeamIndex = endTeamSearch
	searchString = getTeamsText[startTeamSearch, endTeamSearch - startTeamSearch]
	abrevs.each do |region, abrev|
		if searchString.include?(abrev)
			teamsInGame[region] = abrev
		end
	end
end
puts teamsInGame.values.join(" VS ")

playersInGame = {}
team.each do |name, info|
	if teamsInGame.values.include?(info["team"])
		playersInGame[name] = info
	end
end

fileText = ""
lastUpdate = ""
lastTeam = ""
while not fileText.include?("END GAME")
	fileLines = []
	open("http://scores.espn.go.com/nfl/playbyplay?gameId=#{gameID}&period=0") do |f|
		f.each {|line| fileLines << line}
	end
	fileText = fileLines.join

	nameIndex = 0
	playerName = ""
	playersInGame.keys.each do |name|
		lastNameStart = name.rindex(" ") + 1
		lastNameLength = name.length - lastNameStart
		abbrName = "#{name[0]}.#{name[lastNameStart, lastNameLength]}"
		index = fileText.rindex(abbrName)
		if index
			if index > nameIndex
				nameIndex = index
				playerName = name
			end
		end
	end
	if playerName != ""
		begIndex = fileText.rindex(">", nameIndex) + 1
		endIndex = fileText.index("<", nameIndex)
		update = fileText[begIndex, endIndex - begIndex]
		if update != lastUpdate
			lastUpdate = update

			# Mail.deliver do
			#   from     'FanDuel Update'
			#   to       '8608191255@vtext.com'
			#   subject  playerName
			#   body     update
			# end

		end
	end

	teamIndex = fileText.length
	teamName = ""
	teamsInGame.keys.each do |region|
		index = fileText.rindex("#{region} at")
		#puts fileText[index, 50]
		if index
			if index < teamIndex
				teamIndex = index
				teamName = region
			end
		end
	end
	#puts teamIndex
	#puts fileText.rindex("Dallas at")
	#puts fileText
	if teamName != ""
		if teamName != lastTeam
			lastTeam = teamName

			playersOnTeam = []
			playersInGame.each do |name, info|
				if info["team"] == teamsInGame[teamName]
					playersOnTeam << "#{name} #{info['pos']}"
				end
			end

			Mail.deliver do
			  from     'FanDuel Update'
			  to       '8608191255@vtext.com'
			  subject  "#{teamName} has the ball"
			  body     "Root for #{playersOnTeam.join(', ')}"
			end

		end
	end
end














