main.md: main.tex
	pandoc  -t markdown -o main.md -s main.tex

index.html: main.md
	pandoc -t html -o index.html -s main.tex

main.aux: main.tex refs.bib
	pdflatex main.tex

main.pdf: main.aux refs.bib
	biber main && pdflatex main && pdflatex main

deliver: build/index.html
	rsync -a build/ jpfnet:~/public/doc/aske
