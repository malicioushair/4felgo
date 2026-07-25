#include <FelgoApplication>
#ifdef USE_FELGO_HOT_RELOAD
#include <FelgoHotReload>
#endif
#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QScopeGuard>
#include <QStandardPaths>
#include <QUrl>
#include <exception>
#include <iostream>
#include <stdexcept>

#include "Controllers/GuiController/GuiController.h"
#include "SentryIntegration/SentryIntegration.h"

#include "glog/logging.h"

#if defined(__ANDROID__)
extern "C" void android_backtrace_log_status();
#endif

using namespace PastViewer;

void InitLogging(const std::string & execName)
{
	const auto logDir = QDir(QString::fromStdString(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation).toStdString() + "/logs"));
	if (!logDir.exists())
	{
		if (!logDir.mkpath(logDir.absolutePath()))
		{
			LOG(WARNING) << "Failed to create log directory: " << logDir.absolutePath().toStdString();
			return;
		}
	}

	FLAGS_log_dir = logDir.absolutePath().toStdString();
	FLAGS_alsologtostderr = true;
	google::InitGoogleLogging(execName.data());
	google::InstallFailureSignalHandler();
}

int RunApplication(int argc, char * argv[])
{
#ifdef SENTRY_ENABLED
	const auto sentryInitialized = SentryIntegration::InitSentry(QString("PastViewer@%1.%2.%3")
			.arg(VERSION_MAJOR)
			.arg(VERSION_MINOR)
			.arg(VERSION_PATCH));

	auto sentryShutdown = qScopeGuard([sentryInitialized] {
		if (sentryInitialized)
			SentryIntegration::GetPlatform().Shutdown();
	});

	if (!sentryInitialized)
		std::cerr << "Warning: Sentry failed to initialize; continuing without crash reporting\n";
#endif

	QCoreApplication::setOrganizationName("MyOrg");
	QCoreApplication::setApplicationName("PastViewer");

	InitLogging(argv[0]);

// Log backtrace implementation status (after glog is initialized)
#if defined(__ANDROID__)
	android_backtrace_log_status();
#endif

	QQuickStyle::setStyle("Basic");

	QGuiApplication app(argc, argv);

	FelgoApplication felgo;
	QQmlApplicationEngine engine;
	felgo.initialize(&engine);

	GuiController guiController(engine);

#ifdef USE_FELGO_HOT_RELOAD
	FelgoHotReload felgoHotReload(&engine);
#else
	felgo.setMainQmlFileName(QStringLiteral("qml/Main.qml"));
	engine.load(QUrl(felgo.mainQmlFileName()));

	if (engine.rootObjects().isEmpty())
	{
		LOG(ERROR) << "Failed to load QML";
		throw std::runtime_error("Failed to load QML");
	}
#endif

	LOG(INFO) << "Starting PastViewer application";
	return QGuiApplication::exec();
}

int main(int argc, char * argv[]) noexcept
{
	try
	{
		return RunApplication(argc, argv);
	}
	catch (const std::exception & error)
	{
		std::cerr << "PastViewer failed to start: " << error.what() << '\n';
		return 1;
	}
	catch (...)
	{
		std::cerr << "PastViewer failed to start with an unknown error\n";
		return 1;
	}
}
