FROM myoung34/github-runner

# Overwrite own entrypoint.sh for enable --ephemeral runner option
COPY run.sh server.py /
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]
