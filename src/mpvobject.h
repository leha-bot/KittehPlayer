#ifndef MPVOBJECT_H
#define MPVOBJECT_H

#include <mpv/client.h>
#include <mpv/render_gl.h>
#include "mpv/qthelper.hpp"

#include <QObject>
#include <QOpenGLContext>
#include <QQuickFramebufferObject>



class MpvRenderer;

class MpvObject : public QQuickFramebufferObject
{
    Q_OBJECT
    mpv_handle *mpv;
    mpv_render_context *mpv_gl;

    friend class MpvRenderer;

public:
    static void on_update(void *ctx);

    MpvObject(QQuickItem * parent = 0);
    virtual ~MpvObject();
    virtual Renderer *createRenderer() const;


public slots:
    void launchAboutQt();
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
