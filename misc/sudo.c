/* -*- mode: c; c-file-style: "openbsd" -*- */

/*	$OpenBSD: strtonum.c,v 1.8 2015/09/13 08:31:48 guenther Exp $	*/

/*
 * Copyright (c) 2004 Ted Unangst and Todd Miller
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#define	INVALID		1
#define	TOOSMALL	2
#define	TOOLARGE	3

static long long
strtonum(const char *numstr, long long minval, long long maxval,
    const char **errstrp)
{
	long long ll = 0;
	int error = 0;
	char *ep;
	struct errval {
		const char *errstr;
		int err;
	} ev[4] = {
		{ NULL,		0 },
		{ "invalid",	EINVAL },
		{ "too small",	ERANGE },
		{ "too large",	ERANGE },
	};

	ev[0].err = errno;
	errno = 0;
	if (minval > maxval) {
		error = INVALID;
	} else {
		ll = strtoll(numstr, &ep, 10);
		if (numstr == ep || *ep != '\0')
			error = INVALID;
		else if ((ll == LLONG_MIN && errno == ERANGE) || ll < minval)
			error = TOOSMALL;
		else if ((ll == LLONG_MAX && errno == ERANGE) || ll > maxval)
			error = TOOLARGE;
	}
	if (errstrp != NULL)
		*errstrp = ev[error].errstr;
	errno = ev[error].err;
	if (error)
		ll = 0;

	return (ll);
}

/**
 * Fake sudo.
 *
 * Needs to be setuid. Will grant root to anybody able to run it. Its
 * main purpose is to be able to become root in containers when we
 * drop privileges. On containers having only busybox, we don't have a
 * nifty executable for that because busybox will drop setuid bit.
 *
 * This doesn't implement all sudo options.
 *
 * License: CC0
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <grp.h>
#include <getopt.h>
#include <errno.h>

extern const char *__progname;

static void
usage(void) {
	fprintf(stderr, "Usage: %s [options] cmd\n", __progname);
	fprintf(stderr, "\n");
	fprintf(stderr, "Options:\n");
	fprintf(stderr, "   -u UID  change to selected UID (default: 0)\n");
	fprintf(stderr, "   -g GID  change to selected GID (default: 0)\n");
	fprintf(stderr, "   -c CWD  change current directory\n");
	fprintf(stderr, "   -H      set HOME variable to /root when UID == 0\n");
}

int
main(int argc, char * const argv[])
{
	int ch;
	int sethome = 0;
	uid_t uid = 0;
	gid_t gid = 0;
	gid_t gidset[1];
	const char *cwd = NULL;
	const char *errstr;

	while ((ch = getopt(argc, argv, "+u:g:c:hH")) != -1) {
		switch (ch) {
		case 'h':
			usage();
			exit(EXIT_SUCCESS);
			break;
		case 'H':
			sethome = 1;
			break;
		case 'c':
			cwd = optarg;
			break;
		case 'u':
			if (!strcmp(optarg, "root")) {
				uid = 0;
			} else {
				uid = strtonum(optarg, 0, 65535, &errstr);
				if (errstr != NULL) {
					fprintf(stderr, "Provided UID `%s' is %s\n", optarg, errstr);
					usage();
					exit(EXIT_FAILURE);
				}
			}
			break;
		case 'g':
			gid = strtonum(optarg, 0, 65535, &errstr);
			gidset[0] = gid;
			if (errstr != NULL) {
				fprintf(stderr, "Provided GID `%s' is %s\n", optarg, errstr);
				usage();
				exit(EXIT_FAILURE);
			}
			break;
		default:
			usage();
			exit(EXIT_FAILURE);
		}
	}

	if (optind >= argc) {
		fprintf(stderr, "Missing command to execute\n");
		usage();
		exit(EXIT_FAILURE);
	}

	if (setregid(gid, gid) == -1) {
		fprintf(stderr, "unable change GID %d: %m\n", gid);
		exit(EXIT_FAILURE);
	}
	if (setgroups(1, gidset) == -1) {
		fprintf(stderr, "unable change GID set %d: %m\n", gid);
		exit(EXIT_FAILURE);
	}
	if (setreuid(uid, uid) == -1) {
		fprintf(stderr, "unable to change UID %d: %m\n",
		    uid);
		exit(EXIT_FAILURE);
	}

	if (sethome && uid == 0) {
		setenv("HOME", "/root", 1);
	}

	if (cwd != NULL && chdir(cwd) == -1) {
		fprintf(stderr, "unable to change to `%s': %m\n", cwd);
		/* But continue */
	}

	if (execvp(argv[optind], &argv[optind]) == -1) {
		fprintf(stderr, "unable to execute `%s': %m\n", argv[optind]);
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
