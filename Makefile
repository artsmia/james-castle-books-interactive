transformToJpeg:
	ls 151008*.tif | xargs vipsthumbnail -t --size 1000 --output=%s.jpg
	ls *.tif | grep -v 151008 | xargs vipsthumbnail -t --size 2000 --output=%s.jpg

# the first book is photographed sideways? Rotate all the pages to their proper orientation
# it's photographed in 3 different rotations somehow, adjust so adjust all pages face each other
rotateRight='151008_mia335_504745[5,7].jpg'
dontRotate='151008_mia335_5047459.jpg\|151008_mia335_504746[0,3-8]'
rotateFirstBook:
	ls 151008*.jpg \
	| grep -v $(rotateRight) \
	| grep -v $(dontRotate) \
	| xargs -I '{}' sh -c "echo {} && jpegtran -rotate 270 {} | sponge {}"
	ls 151008*.jpg \
	| grep $(rotateRight) \
	| xargs -I '{}' sh -c "echo {} && jpegtran -rotate 90 {} | sponge {}"

# The last 3 books are photographed in 2-page spreads.
# Break them apart and stash the original image (`spreads/*`)
cropDoublePages:
	ls 20150507_mia335_18* | grep -v '-' | tail -n+3 | while read spread; do \
		convert -crop 50%x100% $$spread $$spread; \
		mv $$spread spreads; \
	done
	ls 20150507_mia335_19* | grep -v '-' | tail -n+2 | while read spread; do \
		convert -crop 50%x100% $$spread $$spread; \
		mv $$spread spreads; \
	done
	ls mia_5045* | grep -v '-' | tail -n+2 | head -9 | while read spread; do \
		convert -crop 50%x100% $$spread $$spread; \
		mv $$spread spreads; \
	done
	ls mia_5051* | grep -v '-' | while read spread; do \
		convert -crop 50%x100% $$spread $$spread; \
		mv $$spread spreads; \
	done
	rm mia_5051449-0.jpg mia_5051462-1.jpg

# TODO: those two getting rm`d don't crop correctly - some of the fringe of the page gets lost. Fix maybe

# replace the original, un-split double page images
resetCrops:
	rm *-*.jpg
	mv spreads/* .

# echo the pages as a JS array, ready to paste into the bookreader JS
# `spacedPages` puts a blank page between sibling pages
listPagesJS:
	@pages=$$(ls -1 *.jpg | tr '\n' ',' | sed 's/,$$//'); \
	spacedPages=$$(echo $$pages | sed ' \
		s/\(20150507_mia335_181847.jpg\)/blank.jpg,\1/; \
		s/\(20150507_mia335_193736.jpg\)/blank.jpg,\1/; \
		s/\(mia_5045614.jpg\)/blank.jpg,\1/; \
		s/\(mia_5051449-1.jpg\)/blank.jpg,blank.jpg,\1/; \
	'); \
	echo "var pages = \"$$spacedPages\"\n  .split(',')"

# ----------------
#  done with images
#  everything else below
# ----------------

cloneBookReaderRepo:
	[[ -d bookreader ]] || git clone openlibrary/bookreader
	cp reader.js bookreader/BookReaderDemo/BookReaderJSSimple.js

symlinkImages:
	ln -s $(imageLocation) images

serve:
	cd bookreader && http-server -p 4005 --cors &
	cd images && http-server -p 4007 --cors &

deploy:
	rsync -zva images/*.jpg $(deployLocation)/images
	rsync -zvaL bookreader/ $(deployLocation)

# keep running if the wifi goes down in the galleries
localizeJSDependencies:
	@cd bookreader/BookReaderDemo; \
	grep 'script.*src="http:' index.html \
	| sed -e 's/.*src="\(.*\)".*/\1/' \
	| xargs wget; \
	sed -i '' 's|http://www.archive.org/bookreader/||g' index.html

