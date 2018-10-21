#include <stdexcept>
#include <clocale>

#include "config.h"
#include "mpvobject.h"


#include <QApplication>

#include <QGuiApplication>
#include <QMainWindow>

#include <QQmlApplicationEngine>
#include <QObject>
#include <QWidget>
#include <QtGui/QOpenGLFramebufferObject>
#include <QQuickView>


int main( int argc, char *argv[] )
{
    setenv("QT_QUICK_CONTROLS_STYLE","Desktop",1); 
    QApplication app(argc, argv);
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    qmlRegisterType<MpvObject>("player", 1, 0, "MpvObject");


    std::setlocale(LC_NUMERIC, "C");

/*QQuickView *view = new QQuickView();
view->setResizeMode(QQuickView::SizeRootObjectToView);
view->setSource(QUrl("qrc:///player/main.qml"));
view->show();*/

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:///player/main.qml")));
    return app.exec();
}
