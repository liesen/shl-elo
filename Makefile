YEARS=$(shell seq 2006 2014)
GAME_TYPES=SHL SMSlutspel
GAME_FILES=$(addprefix data/,$(addsuffix .csv,$(foreach year,$(YEARS),$(addprefix $(year)-,$(GAME_TYPES)))))

$(GAME_FILES):
	mkdir -p data
	python scraper.py $(subst -, ,$*) > $@

data/shl.se/shl-arena:
	wget -nv -r --accept-regex 'http://shl.se/shl-arena/[0-9]*/live/' -P data http://shl.se/spelschema/shl.print

data/shl.se/statistics:
	for year in $(shell seq 2006 2014); do \
		for game_type in SHL SMSlutspel; do \
			printf 'http://shl.se/statistics/games/base/Time/%d/%s/All/All/All/All/true/All/inv' $$year $$game_type | xargs -0 wget -nv -x -P data ; \
		done \
	done

data/shl.se/%/liveevents/playerstats: data/shl.se/shl-arena
	find data/shl.se/shl-arena/*/live/index.html -exec grep -oP 'RamsesLive.variables.gameIsaId = \K\d+' {} \; |\
		xargs printf 'http://shl.se/shl-arena/%s/liveevents/playerstats\0' | xargs -0 wget -nv -x -P data

playerstats: data/shl.se/%/liveevents/playerstats

data/shl.se/%/liveevents/0: data/shl.se/shl-arena
	find data/shl.se/shl-arena/*/live/index.html -exec grep -oP 'RamsesLive.variables.gameIsaId = \K\d+' {} \; |\
		xargs printf 'http://shl.se/shl-arena/%s/liveevents/0\0' | xargs -0 wget -nv -x -P data

gamestats: data/shl.se/%/liveevents/0

liveevents: gamestats playerstats

all: $(GAME_FILES) data/shl.se/shl-arena data/shl.se/statistics liveevents

