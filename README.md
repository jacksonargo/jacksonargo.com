# jacksonargo.com
My personal website written in markdown. I use a ruby script to convert the markdown in html via github's markdown api. It's rough and ugly, but it gets the job done.

### Directory structure

 * src - All the source files.
 * src/markdown - All markdown files in this directory are converted into html and copied to public\_html.
 * src/latex - Latex source files that are converted into pdfs.
 * src/templates - Template files used when generating html and latex.
 * public\_html - The document root for the website. This directory is created by the ruby script and contains all the site html.
 * assets - This directory is symlinked inside public\_html, and contains everything else the site needs.

## Requirements:
In order to build the site, you will need make, ruby, bundler, and texlive.

        # yum install make ruby rubygem-bundler texlive -y

## To build the site:
I've included a make file for easier build and clean, specifically when generating the pdfs.

        $ make
