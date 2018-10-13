#ifndef CONFIG_H
#define CONFIG_H

#include <mpv/client.h>

#if MPV_CLIENT_API_VERSION >= MPV_MAKE_VERSION(1, 28)
#define USE_RENDER
#else
#warning "Using deprecated MPV..."
#endif



#endif // CONFIG_H
