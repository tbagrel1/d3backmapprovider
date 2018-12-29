FROM node:10

# https://paul.kinlan.me/fr/hosting-puppeteer-in-a-docker-container/
# https://github.com/GoogleChrome/puppeteer/blob/master/docs/troubleshooting.md

RUN apt-get update && apt-get install -yq libgconf-2-4

# Install latest chrome dev package and fonts to support major 
# charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version 
# of Chromium that Puppeteer
# installs, work.
RUN apt-get update && apt-get install -y wget --no-install-recommends \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst ttf-freefont \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge --auto-remove -y curl \
    && rm -rf /src/*.deb

# It's a good idea to use dumb-init to help prevent zombie chrome processes.
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

COPY . /app/
WORKDIR app
RUN npm i

# altering chrome in puppeteer after npm install to suppress sandbox
# (docker specifid)
RUN cd node_modules/puppeteer/.local-chromium/linux-609904/chrome-linux/ \
    && mv chrome chrome_wrapped \
    && echo -e '#!/bin/sh\n'$(pwd)'/chrome_wrapped --no-sandbox "$@"' > chrome \
    && chmod +x chrome

# Launch
EXPOSE 8080
ENTRYPOINT ["dumb-init", "--"]
CMD ["npm", "start"]

