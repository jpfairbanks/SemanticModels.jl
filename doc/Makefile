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
	scp -r build aske:~/httpdocs/

doc.tar.gz: build/index.html
	tar zcf doc.tar.gz build

slides.slides.html: slides.ipynb
	jupyter nbconvert --to slides --reveal-prefix reveal.js $^

workflow.slides.html: workflow.ipynb
	jupyter nbconvert --to slides --reveal-prefix reveal.js $^

serve: slides.slides.html workflow.slides.html
	go run server.go -d . -p 8080 &

open: slides.slides.html workflow.slides.html
	open $^

uploadimages:
	# scp -r src/img jpfnet:public/doc/slides/ufdsi/src/
	scp -r src/ jpfnet:public/doc/slides/juliacon2019/

uploadreveal: reveal.js
	scp -r $^ jpfnet:public/doc/slides/ufdsi/

upload: slides.slides.html
	scp -r $^ jpfnet:public/doc/slides/juliacon2019/
	# scp -r reveal.js jpfnet:public/doc/slides/act/
