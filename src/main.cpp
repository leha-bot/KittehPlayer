#include <stdexcept>
#include <clocale>
#include <bits/stdc++.h> 
#include <stdio.h>
#include <stdlib.h>

#include "config.h"
#include "mpvobject.h"
#ifdef QRC_SOURCE_PATH
#include "runtimeqml/runtimeqml.h"
#endif

#include <QApplication>

#include <QGuiApplication>
#include <QMainWindow>

#include <QQmlApplicationEngine>
#include <QObject>
#include <QWidget>
#include <QtGui/QOpenGLFramebufferObject>
#include <QQuickView>
#include <QProcessEnvironment>


int main( int argc, char *argv[] )
{
    QApplication app(argc, argv);
    app.setOrganizationName("KittehPlayer");
    app.setOrganizationDomain("namedkitten.pw");
    app.setApplicationName("KittehPlayer");

    for (int i = 1; i < argc; ++i) {
        if (!qstrcmp(argv[i], "--update")) {
            QString program = QProcessEnvironment::systemEnvironment().value("APPDIR", "") +  "/usr/bin/appimageupdatetool";
            QProcess updater;
            updater.setProcessChannelMode(QProcess::ForwardedChannels);
            updater.start(program, QStringList() << QProcessEnvironment::systemEnvironment().value("APPIMAGE", ""));
            updater.waitForFinished();
            qDebug() << program;
            exit(0);
        }
    }
    
    QProcess dpms;
    dpms.start("xset", QStringList() << "-dpms");


    

    setenv("QT_QUICK_CONTROLS_STYLE","Desktop",1);
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    qmlRegisterType<MpvObject>("player", 1, 0, "MpvObject");


    std::setlocale(LC_NUMERIC, "C");

/*QQuickView *view = new QQuickView();
view->setResizeMode(QQuickView::SizeRootObjectToView);
view->setSource(QUrl("qrc:///player/main.qml"));
view->show();*/

    QQmlApplicationEngine engine;
#ifdef QRC_SOURCE_PATH
RuntimeQML *rt = new RuntimeQML(&engine, QRC_SOURCE_PATH"/qml.qrc");

rt->setAutoReload(true);
rt->setMainQmlFilename("main.qml");
rt->reload();
#else
engine.load(QUrl(QStringLiteral("qrc:///player/main.qml")));
#endif

    return app.exec();
}
