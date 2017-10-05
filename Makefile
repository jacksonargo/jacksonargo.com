main: html resume
html:
	bundle install
	bundle exec ruby ./render.rb
resume:
	mkdir -p tmp
	mkdir -p assets/documents
	pdflatex -output-directory tmp src/latex/Resume.tex
	cp tmp/Resume.pdf assets/documents
clean: clean_html clean_resume
clean_html:
	rm -rf cache public_html Gemfile.lock
clean_resume:
	rm -rf tmp \
		src/latex/Resume.tex \
		src/markdown/Resume.md \
		assets/documents/Resume.pdf \
