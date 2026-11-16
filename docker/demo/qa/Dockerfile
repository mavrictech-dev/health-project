FROM mcr.microsoft.com/playwright:v1.56.1-noble@sha256:f1e7e01021efd65dd1a2c56064be399f3e4de00fd021ac561325f2bfbb2b837a
WORKDIR /qa
RUN npm init -y && npm install --save-exact --no-audit --no-fund playwright@1.56.1
COPY docker/demo/qa/run.cjs /qa/run.cjs
ENTRYPOINT ["node", "/qa/run.cjs"]
