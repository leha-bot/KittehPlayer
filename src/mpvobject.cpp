
#include <stdexcept>
#include <clocale>

#include "mpvobject.h"

#include <QApplication>
#include <QQuickWindow>
#include <QOpenGLContext>
#include <QOpenGLFramebufferObject>


namespace
{

void wakeup(void *ctx)
{
    QMetaObject::invokeMethod((MpvObject*)ctx, "on_mpv_events", Qt::QueuedConnection);
}

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


}

class MpvRenderer : public QQuickFramebufferObject::Renderer
{
    MpvObject *obj;  

public:

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
            mpv_opengl_init_params gl_init_params{get_proc_address_mpv};
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


    void render()
    {
            
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
    }
};

MpvObject::MpvObject(QQuickItem * parent)
    : QQuickFramebufferObject(parent), mpv{mpv_create()}, mpv_gl(nullptr)
{

    if (!mpv)
        throw std::runtime_error("could not create mpv context");

    mpv_set_option_string(mpv, "terminal", "yes");
    mpv_set_option_string(mpv, "msg-level", "all=v");

    // Fix?
    mpv_set_option_string(mpv, "ytdl", "yes");
    mpv_set_option_string(mpv, "vo", "libmpv");
    //mpp_set_option_string(mpv, "no-sub-ass", "yes)

    mpv_set_option_string(mpv, "slang", "en");

    mpv_set_option_string(mpv, "config", "yes");
    //mpv_set_option_string(mpv, "sub-visibility", "no");





        mpv_observe_property(mpv, 0, "playback-abort", MPV_FORMAT_NONE);
        mpv_observe_property(mpv, 0, "chapter-list", MPV_FORMAT_NODE);
        mpv_observe_property(mpv, 0, "track-list", MPV_FORMAT_NODE);
        mpv_observe_property(mpv, 0, "playlist-pos", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "volume", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "muted", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "duration", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "media-title", MPV_FORMAT_STRING);
        mpv_observe_property(mpv, 0, "sub-text", MPV_FORMAT_STRING);
        mpv_observe_property(mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "demuxer-cache-duration", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_NONE);
        mpv_set_wakeup_callback(mpv, wakeup, this);

    if (mpv_initialize(mpv) < 0)
        throw std::runtime_error("could not initialize mpv context");

    connect(this, &MpvObject::onUpdate, this, &MpvObject::doUpdate,
            Qt::QueuedConnection);

}

MpvObject::~MpvObject()
{
    if (mpv_gl) 
    {
        mpv_render_context_free(mpv_gl);
    }

    mpv_terminate_destroy(mpv);
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

void MpvObject::launchAboutQt()
{
    QApplication *qapp = qobject_cast<QApplication *>(QCoreApplication::instance());
    qapp->aboutQt();
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
                double volume = *(double *)prop->data;
                QMetaObject::invokeMethod(this,"updateVolume",Q_ARG(QVariant,volume));
            }
        } else if (strcmp(prop->name, "muted") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double muted = *(double *)prop->data;
                QMetaObject::invokeMethod(this,"updateMuted",Q_ARG(QVariant,muted));
            }
        } else if (strcmp(prop->name, "media-title") == 0) {
            if (prop->format == MPV_FORMAT_STRING) {
                char *title = *(char **)prop->data;
                QMetaObject::invokeMethod(this,"setTitle",Q_ARG(QVariant,title));
            }
        } else if (strcmp(prop->name, "sub-text") == 0) {
            if (prop->format == MPV_FORMAT_STRING) {
                char *subs = *(char **)prop->data;
                QMetaObject::invokeMethod(this,"setSubtitles",Q_ARG(QVariant,subs));
            }
        } else if (strcmp(prop->name, "demuxer-cache-duration") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double duration = *(double *)prop->data;
                QMetaObject::invokeMethod(this,"setCachedDuration",Q_ARG(QVariant,duration));
            }
        } else if (strcmp(prop->name, "playlist-pos") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double pos = *(double *)prop->data;
                QMetaObject::invokeMethod(this,"updatePrev",Q_ARG(QVariant,pos));
            }
        } else if (strcmp(prop->name, "pause") == 0) {
            QMetaObject::invokeMethod(this,"updatePlayPause");
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

    return new MpvRenderer(const_cast<MpvObject *>(this));
}
