#include <stdexcept>
#include <clocale>
#include <bits/stdc++.h> 
#include <stdio.h>
#include <stdlib.h>

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
#include <QProcessEnvironment>


int main( int argc, char *argv[] )
{
    QApplication app(argc, argv);

    for (int i = 1; i < argc; ++i) {
        if (!qstrcmp(argv[i], "--update")) {
            QString program = QProcessEnvironment::systemEnvironment().value("APPDIR", "/usr/bin") + "/appimageupdatetool";
            QProcess updater;
            updater.setProcessChannelMode(QProcess::ForwardedChannels);
            updater.start(program, QStringList() << QProcessEnvironment::systemEnvironment().value("APPIMAGE", ""));
            if(!updater.waitForStarted())
                qDebug() << "Failed to start updater.";
                qDebug() << updater.errorString();
            qDebug() << program;
            exit(0);
        }
    }
    

    setenv("QT_QUICK_CONTROLS_STYLE","Desktop",1);
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
