/home/danl/.cabal/bin/daninst: src/Main.hs
	mkdir -p ../build && ghc -cpp -O2 --make src/Main.hs -odir ../build \
		-hidir ../build -Wall -o /home/danl/.cabal/bin/daninst \
		-package HSH \
		-package split
