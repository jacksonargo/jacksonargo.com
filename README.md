# jacksonargo.com
My personal website written in markdown. I use a ruby script to convert the markdown in html via github's markdown api. It's rough and ugly, but it gets the job done.

### Directory structure

 * src - All the source files.
 * public\_html - The document root for the website. This directory is created by the build script.
 * src/markdown - All markdown files in this directory are converted into html and copied to public\_html.
 * src/assets - All files in this directory are copied to public\_html.
 * src/templates - Template files used when generating the html.
