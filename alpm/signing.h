#ifndef SIGNING_H
#define SIGNING_H

int gpgme_sign(int fd, int sigfd, const char *key);
int gpgme_verify(int fd, int sigfd);

#endif
