#ifndef MPVOBJECT_H
#define MPVOBJECT_H

#include <QQuickFramebufferObject>

#include "config.h"

#include <mpv/client.h>

#ifdef USE_RENDER
#include <mpv/render_gl.h>
#else
#include <mpv/opengl_cb.h>
#endif

#include <mpv/qthelper.hpp>

#include <QObject>
#include <QtGlobal>
#include <QOpenGLContext>
#include <QGuiApplication>

#include <QQuickFramebufferObject>

#include <QtQuick/QQuickWindow>
#include <QtQuick/QQuickView>

#include <QProcess>

class MpvRenderer;

class MpvObject : public QQuickFramebufferObject
{
    Q_OBJECT
#ifdef USE_RENDER
    mpv_handle *mpv;
    mpv_render_context *mpv_gl;
#else
    mpv::qt::Handle mpv;
    mpv_opengl_cb_context *mpv_gl;
#endif

    friend class MpvRenderer;

public:
    static void on_update(void *ctx);

    MpvObject(QQuickItem * parent = 0);
    virtual ~MpvObject();
    virtual Renderer *createRenderer() const;


public slots:
    void command(const QVariant& params);
    void setProperty(const QString& name, const QVariant& value);
    void setOption(const QString& name, const QVariant& value);
    QVariant getProperty(const QString& name) const;


signals:
    void onUpdate();
    void positionChanged(int value);
    void mpv_events();

private slots:
    void doUpdate();
    void on_mpv_events();

private:
    void handle_mpv_event(mpv_event *event);


};



#endif
