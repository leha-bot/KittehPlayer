#ifndef CONFIG_H
#define CONFIG_H

#include <mpv/client.h>

#if MPV_CLIENT_API_VERSION >= MPV_MAKE_VERSION(1, 28)
// good
#else
#error "Old MPV versions without render API are not supported."
#endif

#endif // CONFIG_H
