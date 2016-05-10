transformToJpeg:
	vipsthumbnail -t --size 2000 --output=%s.jpg *.tif

# the first book is photographed sideways? Rotate all the pages to their proper orientation
rotateFirstBook:
	ls 151008*.jpg | xargs -I '{}' sh -c "echo {} && jpegtran -rotate 270 {} | sponge {}"

# The last 3 books are photographed in 2-page spreads.
# Break them apart and stash the original image (`spreads/*`)
cropDoublePages:
	ls 20150507_mia335_18* | grep -v '-' | tail -n+3 | while read spread; do \
		convert -crop 1000x1337x1100 $$spread $$spread; \
		mv $$spread spreads; \
	done
	ls 20150507_mia335_19* | grep -v '-' | tail -n+2 | while read spread; do \
		convert -crop 1000x1337x1100 $$spread $$spread; \
		mv $$spread spreads; \
	done
	ls mia_5045* | grep -v '-' | tail -n+2 | head -9 | while read spread; do \
		convert -crop 1000x1284x1100 $$spread $$spread; \
		mv $$spread spreads; \
	done
	ls mia_5051* | grep -v '-' | while read spread; do \
		convert -crop 1000x1061x1100 $$spread $$spread; \
		mv $$spread spreads; \
	done
	rm mia_5051449-0.jpg mia_5051462-1.jpg

# TODO: those two getting rm`d don't quite crop correctly - some of the fringe of the page gets lost. Fix maybe
# Maybe todo: measure each image and automatically choose the (width/2, 1*height) page splits?

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
