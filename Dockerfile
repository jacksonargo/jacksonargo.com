FROM jekyll/jekyll
EXPOSE 4000
RUN gem install github-pages jekyll-theme-minimal
VOLUME /srv
WORKDIR /srv
CMD ["jekyll", "serve"]
