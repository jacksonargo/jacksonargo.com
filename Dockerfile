FROM jekyll/jekyll
EXPOSE 4000
RUN gem install github-pages jekyll-theme-minimal
COPY . .
CMD ["jekyll", "serve"]
