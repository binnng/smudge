req = require "req-fast"
fs = require "fs"
download = require "download-file"
colors = require "colors"

SMG_URL = "http://www.smudgestore.com/smudge_store/public/en/index/index/category/refucoreca"
SMG_DOMAIN = "http://www.smudgestore.com"
SMG_SEASONS = {}
SMG_SEASONS_KEY = []

current_season = 0
num = 0
output = "output"


fetch = ->
	req SMG_URL, (err, res) ->
		{
			body
		} = res

		if body
			seasons = get_seasons body
			SMG_SEASONS = seasons

			seasons_key = Object.keys seasons
			SMG_SEASONS_KEY = seasons_key

			fetch_seasons seasons_key[current_season]

get_seasons = (body) ->
	start = "<div class=\"navi-title\">SEASON</div>"
	end = "<div class=\"navi-title\">SPECIAL</div>"

	body = body.replace /\n|\t/g, ""
	result = {}

	reg = new RegExp start + "(.*)" + end, "g"
	seasons = (body.match reg)[0]

	seasons_list = seasons.match /<a href=\"\/smudge_store.*?<\/a>/g

	seasons_list.map (item) ->
		link = (item.match /<a href="(.*?)">/)[1]
		cat = (item.match /<p>(.*?)<\/p>/)[1]
		cat = cat
			.replace /\s/g, ""
			.replace /\//g, ""

		result[cat] = link

	result


fetch_seasons = (season, link) ->
	link = SMG_DOMAIN + (link or SMG_SEASONS[season])

	console.log "start #{link}".yellow

	req link, (err, res) ->
		{
			body
		} = res

		body = body.replace /\n|\t/g, ""
		body = body.replace '<img src="images/logo.jpg" />', ""

		imgs = []
		_imgs = body.match /img src=".*?" width="80"/g

		next = get_next_page body

		_imgs.map (item) ->
			imgs.push (item.match /(images.*?jpg)/)[0]

		download_images imgs, season, next

get_next_page = (body) ->
	next = ""
	_next = (body.match /margin-left: 12px;(.*?)<a href="(.*?)" class="pageNext"><\/a>/g) || []

	if _next[0]
		next = (_next[0].match /href="(.*?)"/)[1]

	next

download_images = (images = [], season, next) ->
	down =  (index) ->
		item = images[index]

		unless item
			if next
				fetch_seasons season, next
			else
				current_season += 1
				if SMG_SEASONS_KEY[current_season]
					fetch_seasons SMG_SEASONS_KEY[current_season]
				else
					console.log "---download #{num} images---"

			return no


		image_name = (item.match /list\/(.*?.jpg)/)[1]
		image_url = SMG_DOMAIN + "/smudge_store/public/" + item
		image_url = image_url.replace "list", "demo"

		req image_url, (err, res) ->
			directory = output + "/" + season

			download image_url,
				directory: directory
				filename: image_name
			, (err) ->
				if err
					console.log image_url, err
					color = "red"
				else
					color = "green"

				console.log image_url[color]
				num++

				down index + 1

	down 0


fetch()