# smax-server
The minimal server set up needed to get SMA-X running on a host computer.

To set up the server:
1 - install redis.
2 - run `sudo install.sh`.
3 - make sure that redis is configured to your liking.
4 - use `systemctl` to restart redis and smax-scripts services.

The default set up here will allow redis connections to 127.0.0.1 only (i.e. localhost). This is fine for testing, but not for a production environment.
