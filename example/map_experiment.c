/*
 * This file is modified from an automatically generated version by
 * oml2-scaffold 2.12.0pre.147-8fe8-dirty for map_experiment version 1.0.0.
 * The run() function contains application code.
 */

#include <unistd.h> /* Needed for usleep(3) in run() */
#include <signal.h>
#include <string.h>
#include <popt.h>
#include <oml2/omlc.h>
#include <curl/curl.h> /* To make requests to our controller */
#include <stdio.h>

#define USE_OPTS /* Include command line parsing code*/
#include "map_experiment_popt.h"

#define OML_FROM_MAIN /* Define storage for some global variables; #define this in only one file */
#include "map_experiment_oml.h"

#include "config.h"

int loop = 1;

static void
sighandler (int signum) {
  switch (signum) {
    case SIGINT:
      /* Terminate on SIGINT */
      loop = 0;
      break;

  }
}

/* Do application-specific work here.
 */
void
run(opts_t *opts, oml_mps_t *oml_mps)
{
  long val = 1;
  struct sigaction sa;

  bzero(&sa, sizeof(struct sigaction));
  sa.sa_handler = sighandler;
  sigaction(SIGINT, &sa, NULL);

  /* RESTful API request to the controller node to get a desired topology. Use
  this node as the context, and ask for a 2 hop topology. */
  CURL *curl;
  CURLcode res;

  curl = curl_easy_init();

  static const int32_t topology[] = {
    0, -1, 1, INT32_MIN, INT32_MAX
  };
  static const size_t topology_len = sizeof(topology)/sizeof(topology[0]);

  do {
    printf("DOING IT!!");
    if(curl) {
      curl_easy_setopt(curl, CURLOPT_URL, "10.10.0.10:4567/1");
      /* example.com is redirected, so we tell libcurl to follow redirection */
      curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);

      /* Perform the request, res will get the return code */
      res = curl_easy_perform(curl);
      /* Check for errors */
      if(res != CURLE_OK) {
        /* Could just be because the service isn't up yet, not fatal, just try
        again. */
      }

      curl_easy_cleanup(curl);
    }

    /* The oml_inject_MPNAME() helpers are defined in map_experiment_oml.h*/
    if(oml_inject_query(oml_mps->query, ((int32_t)-val), topology, topology_len) != 0) {
      logwarn("Failed to inject data into MP 'query'\n");
    }

    val += 2;
    /* The following depends on the delay command-line parameter in map_experiment.rb */
    usleep(g_opts_storage.delay*1000000);
  } while (loop);
}

int
main(int argc, const char *argv[])
{
  int c, i, ret;

  /* Reconstruct command line */
  size_t cmdline_len = 0;
  for(i = 0; i < argc; i++) {
    cmdline_len += strlen(argv[i]) + 1;
  }
  char cmdline[cmdline_len + 1];
  cmdline[0] = '\0';
  for(i = 0; i < argc; i++) {
    strncat(cmdline, argv[i], cmdline_len);
    cmdline_len -= strlen(argv[i]);
    strncat(cmdline, " ", cmdline_len);
    cmdline_len--;
  }

  /* Initialize OML */
  if((ret = omlc_init("map_experiment", &argc, argv, NULL)) < 0) {
    logerror("Could not initialise OML\n");
    return -1;
  }

  /* Parse command line arguments */
  poptContext optCon = poptGetContext(NULL, argc, argv, options, 0); /* options is defined in map_experiment_popt.h */
  while ((c = poptGetNextOpt(optCon)) > 0) {}

  /* Initialise measurement points and start OML */
  oml_register_mps(); /* Defined in map_experiment_oml.h */
  if(omlc_start()) {
    logerror("Could not start OML\n");
    return -1;
  }

  /* Inject some metadata about this application */
  OmlValueU v;
  omlc_zero(v);
  omlc_set_string(v, PACKAGE_NAME);
  omlc_inject_metadata(NULL, "appname", &v, OML_STRING_VALUE, NULL);

  omlc_set_string(v, PACKAGE_VERSION);
  omlc_inject_metadata(NULL, "version", &v, OML_STRING_VALUE, NULL);

  omlc_set_string(v, cmdline);
  omlc_inject_metadata(NULL, "cmdline", &v, OML_STRING_VALUE, NULL);
  omlc_reset_string(v);

  /* Inject measurements */
  run(g_opts, g_oml_mps_map_experiment); /* Do some work and injections, see above */

  omlc_close();

  return 0;
}

/*
 Local Variables:
 mode: C
 tab-width: 2
 indent-tabs-mode: nil
 End:
 vim: sw=2:sts=2:expandtab
*/
