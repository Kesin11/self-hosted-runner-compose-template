FROM cimg/base:edge

WORKDIR /actions-runner
RUN curl -o actions-runner-linux-x64-2.278.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.278.0/actions-runner-linux-x64-2.278.0.tar.gz \
  && tar xzf ./actions-runner-linux-x64-2.278.0.tar.gz \
  && rm actions-runner-linux-x64-2.278.0.tar.gz
