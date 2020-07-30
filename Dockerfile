FROM jekyll/jekyll
EXPOSE 4000
RUN gem install jekyll-theme-minimal
COPY . .
CMD ["jekyll", "serve"]
