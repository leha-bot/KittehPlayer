
#include <stdexcept>
#include <clocale>

#include "mpvobject.h"
#include "config.h"


#include <QObject>
#include <QtGlobal>
#include <QOpenGLContext>

#include <QGuiApplication>
#include <QtQuick/QQuickWindow>
#include <QtQuick/QQuickView>
#include <QQuickFramebufferObject>
#include <QOpenGLContext>
#include <QtQuick/QQuickWindow>
#include <QtQuick/QQuickView>
#include <QtGui/QOpenGLFramebufferObject>

#include <QJsonDocument>

namespace
{

void wakeup(void *ctx)
{
    QMetaObject::invokeMethod((MpvObject*)ctx, "on_mpv_events", Qt::QueuedConnection);
}

#ifdef USE_RENDER
void on_mpv_redraw(void *ctx)
{
    MpvObject::on_update(ctx);
}

static void *get_proc_address_mpv(void *ctx, const char *name)
{
    Q_UNUSED(ctx)

    QOpenGLContext *glctx = QOpenGLContext::currentContext();
    if (!glctx) return nullptr;

    return reinterpret_cast<void *>(glctx->getProcAddress(QByteArray(name)));
}
#endif


}

class MpvRenderer : public QQuickFramebufferObject::Renderer
{
#ifdef USE_RENDER
    MpvObject *obj;
#else
    static void *get_proc_address(void *ctx, const char *name) {
        (void)ctx;
        QOpenGLContext *glctx = QOpenGLContext::currentContext();
        if (!glctx)
            return NULL;
        return (void *)glctx->getProcAddress(QByteArray(name));
    }
      mpv::qt::Handle mpv;
    QQuickWindow *window;
    mpv_opengl_cb_context *mpv_gl;
#endif    

public:

#ifdef USE_RENDER

    MpvRenderer(MpvObject *new_obj)
        : obj{new_obj}
    {
    }

    virtual ~MpvRenderer() {}

    // This function is called when a new FBO is needed.
    // This happens on the initial frame.
    QOpenGLFramebufferObject * createFramebufferObject(const QSize &size)
    {
        // init mpv_gl:
        if (!obj->mpv_gl)
        {
            mpv_opengl_init_params gl_init_params{get_proc_address_mpv, nullptr, nullptr};
            mpv_render_param params[]{
                {MPV_RENDER_PARAM_API_TYPE, const_cast<char *>(MPV_RENDER_API_TYPE_OPENGL)},
                {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params},
                {MPV_RENDER_PARAM_INVALID, nullptr}
            };

            if (mpv_render_context_create(&obj->mpv_gl, obj->mpv, params) < 0)
                throw std::runtime_error("failed to initialize mpv GL context");
            mpv_render_context_set_update_callback(obj->mpv_gl, on_mpv_redraw, obj);
        }

        return QQuickFramebufferObject::Renderer::createFramebufferObject(size);
        }

#else 

       MpvRenderer(const MpvObject *obj)
        : mpv(obj->mpv), window(obj->window()), mpv_gl(obj->mpv_gl)
           {
        int r = mpv_opengl_cb_init_gl(mpv_gl, NULL, get_proc_address, NULL);
        if (r < 0)
            throw std::runtime_error("could not initialize OpenGL");
        }

        virtual ~MpvRenderer() {
            mpv_opengl_cb_uninit_gl(mpv_gl);
        }

#endif



    void render()
    {
            
#ifdef USE_RENDER
        obj->window()->resetOpenGLState();

        QOpenGLFramebufferObject *fbo = framebufferObject();
        mpv_opengl_fbo mpfbo{.fbo = static_cast<int>(fbo->handle()), .w = fbo->width(), .h = fbo->height(), .internal_format = 0};
        int flip_y{0};

        mpv_render_param params[] = {
            // Specify the default framebuffer (0) as target. This will
            // render onto the entire screen. If you want to show the video
            // in a smaller rectangle or apply fancy transformations, you'll
            // need to render into a separate FBO and draw it manually.
            {MPV_RENDER_PARAM_OPENGL_FBO, &mpfbo},
            // Flip rendering (needed due to flipped GL coordinate system).
            {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
            {MPV_RENDER_PARAM_INVALID, nullptr}
        };
        // See render_gl.h on what OpenGL environment mpv expects, and
        // other API details.
        mpv_render_context_render(obj->mpv_gl, params);

        obj->window()->resetOpenGLState();
#else
        QOpenGLFramebufferObject *fbo = framebufferObject();
        window->resetOpenGLState();
        mpv_opengl_cb_draw(mpv_gl, fbo->handle(), fbo->width(), fbo->height());
        window->resetOpenGLState();
#endif
    }
};

MpvObject::MpvObject(QQuickItem * parent)
#ifdef USE_RENDER
    : QQuickFramebufferObject(parent), mpv{mpv_create()}, mpv_gl(nullptr)
#else
    : QQuickFramebufferObject(parent), mpv_gl(0)
#endif
{


#ifndef USE_RENDER
    mpv = mpv::qt::Handle::FromRawHandle(mpv_create());
#endif


    if (!mpv)
        throw std::runtime_error("could not create mpv context");

    mpv_set_option_string(mpv, "terminal", "yes");
    //mpv_set_option_string(mpv, "msg-level", "all=v");

    if (mpv_initialize(mpv) < 0)
        throw std::runtime_error("could not initialize mpv context");

#ifndef USE_RENDER
    mpv::qt::set_option_variant(mpv, "vo", "opengl-cb");
#else
    mpv::qt::set_option_variant(mpv, "vo", "libmpv");
#endif

    // Enable default bindings, because we're lazy. Normally, a player using
    // mpv as backend would implement its own key bindings.
    mpv_set_option_string(mpv, "input-default-bindings", "yes");

    // Enable keyboard input on the X11 window. For the messy details, see
    // --input-vo-keyboard on the manpage.
    mpv_set_option_string(mpv, "input-vo-keyboard", "yes");

    // Fix?
    mpv::qt::set_option_variant(mpv, "ytdl", "yes");

    mpv_set_option_string(mpv, "input-default-bindings", "yes");
    mpv_set_option_string(mpv, "input-vo-keyboard", "yes");

    mpv::qt::set_option_variant(mpv, "idle", "once");


    mpv::qt::set_option_variant(mpv, "hwdec", "off");
    mpv::qt::set_option_variant(mpv, "slang", "en");
    mpv::qt::set_option_variant(mpv, "sub-font", "Noto Sans");
    mpv::qt::set_option_variant(mpv, "sub-ass-override", "force");
    mpv::qt::set_option_variant(mpv, "sub-ass", "off");
    mpv::qt::set_option_variant(mpv, "sub-border-size", "0");
    mpv::qt::set_option_variant(mpv, "sub-bold", "off");
    mpv::qt::set_option_variant(mpv, "sub-scale-by-window", "on");
    mpv::qt::set_option_variant(mpv, "sub-scale-with-window", "on");

    mpv::qt::set_option_variant(mpv, "sub-back-color", "#C0080808");



        mpv_observe_property(mpv, 0, "playback-abort", MPV_FORMAT_NONE);
        mpv_observe_property(mpv, 0, "chapter-list", MPV_FORMAT_NODE);
        mpv_observe_property(mpv, 0, "track-list", MPV_FORMAT_NODE);

        mpv_observe_property(mpv, 0, "duration", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "media-title", MPV_FORMAT_STRING);

        mpv_observe_property(mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);

        mpv_set_wakeup_callback(mpv, wakeup, this);

#ifndef USE_RENDER
mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    if (!mpv_gl)
        throw std::runtime_error("OpenGL not compiled in");
    mpv_opengl_cb_set_update_callback(mpv_gl, MpvObject::on_update, (void *)this);
#endif

    connect(this, &MpvObject::onUpdate, this, &MpvObject::doUpdate,
            Qt::QueuedConnection);
}

MpvObject::~MpvObject()
{
#ifdef USE_RENDER
    if (mpv_gl) 
    {
        mpv_render_context_free(mpv_gl);
    }

    mpv_terminate_destroy(mpv);
#else
    if (mpv_gl)
        mpv_opengl_cb_set_update_callback(mpv_gl, NULL, NULL);
#endif
}

void MpvObject::on_update(void *ctx)
{
    MpvObject *self = (MpvObject *)ctx;
    emit self->onUpdate();
}

// connected to onUpdate(); signal makes sure it runs on the GUI thread
void MpvObject::doUpdate()
{
    update();
}


QVariant MpvObject::getThumbnailFile(const QString &name) const
{
    QProcess process;
    process.start("youtube-dl --get-thumbnail " + name);
    process.waitForFinished(-1);
    return process.readAllStandardOutput();

}





QVariant MpvObject::getProperty(const QString &name) const
{
    return mpv::qt::get_property_variant(mpv, name);
}


void MpvObject::command(const QVariant& params)
{
    mpv::qt::command_variant(mpv, params);
}

void MpvObject::setProperty(const QString& name, const QVariant& value)
{
    mpv::qt::set_property_variant(mpv, name, value);
}

void MpvObject::setOption(const QString& name, const QVariant& value)
{
    mpv::qt::set_option_variant(mpv, name, value);
}

void MpvObject::on_mpv_events()
{
    while (mpv) {
        mpv_event *event = mpv_wait_event(mpv, 0);

        if (event->event_id == MPV_EVENT_NONE) {
            break;
        }
        handle_mpv_event(event);
    }

}
 
void MpvObject::handle_mpv_event(mpv_event *event)
{
    switch (event->event_id) {
    case MPV_EVENT_PROPERTY_CHANGE: {
        mpv_event_property *prop = (mpv_event_property *)event->data;
        if (strcmp(prop->name, "time-pos") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double time = *(double *)prop->data;
                QMetaObject::invokeMethod(this,"setProgressBarValue",Q_ARG(QVariant,time));
            }
        } else if (strcmp(prop->name, "duration") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double time = *(double *)prop->data;Q_ARG(QVariant,"txt1"),
                QMetaObject::invokeMethod(this,"setProgressBarEnd",Q_ARG(QVariant,time));
            }
        } else if (strcmp(prop->name, "volume") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                QMetaObject::invokeMethod(this,"updateVolume");
            }
        } else if (strcmp(prop->name, "media-title") == 0) {
            if (prop->format == MPV_FORMAT_STRING) {
                QMetaObject::invokeMethod(this,"setTitle");
            }
        }
        break;
    }
    case MPV_EVENT_SHUTDOWN: {
        exit(0);
        break;
    }
    default: {
        break;
    }
    }
}

QQuickFramebufferObject::Renderer *MpvObject::createRenderer() const
{
    window()->setPersistentOpenGLContext(true);
    window()->setPersistentSceneGraph(true);
#ifdef USE_RENDER
    return new MpvRenderer(const_cast<MpvObject *>(this));
#else
    return new MpvRenderer(this);
#endif
}
