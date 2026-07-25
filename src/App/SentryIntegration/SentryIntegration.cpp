/*!
    \namespace SentryIntegration
    \inmodule PastViewer
    \brief Optional crash reporting via the Sentry SDK.

    Active only when the application is built with \c SENTRY_DSN defined.
 */

/*!
    \class SentryIntegration::ISentry
    \inmodule PastViewer
    \brief Platform abstraction for Sentry SDK operations.
 */
#include "SentryIntegration.h"

#include <cstdlib>
#include <exception>
#include <memory>

#include <QScopeGuard>
#include <QString>

#include <glog/logging.h>
#include <mutex>

namespace SentryIntegration {

namespace {

constexpr auto SeverityToLevel(google::LogSeverity severity) noexcept
{
	switch (severity)
	{
		case google::GLOG_INFO:
			return "info";
		case google::GLOG_WARNING:
			return "warning";
		case google::GLOG_ERROR:
		case google::GLOG_FATAL:
			return "error";
		default:
			return "debug";
	}
}

class BreadcrumbSink : public google::LogSink
{
public:
	void send(google::LogSeverity severity, const char * full_filename, const char * base_filename, int line, const struct ::tm * tm_time, const char * message, size_t message_len) override
	{
		if (message_len == 0 || message == nullptr)
			return;

		const std::string message_str(message, message_len);
		const auto level = SeverityToLevel(severity);
		const auto lock = std::lock_guard<std::mutex>(m_mtx);
		GetPlatform().AddBreadcrumb(message_str, level);
	}

private:
	std::mutex m_mtx;
};

std::unique_ptr<BreadcrumbSink> g_breadcrumbSink;
bool g_sentryInitialized = false;

void TerminateHandler()
{
	LOG(ERROR) << "Terminate handler called";

	const auto eptr = std::current_exception();

	if (eptr)
	{
		LOG(ERROR) << "Exception pointer is valid, attempting to extract exception";
		try
		{
			std::rethrow_exception(eptr);
		}
		catch (const std::exception & e)
		{
			const auto errorMsg = QString::fromStdString(e.what());
			const auto type = QString::fromStdString(typeid(e).name());
			LOG(ERROR) << "Caught std::exception: " << e.what() << " (type: " << type.toStdString() << ")";
			if (g_sentryInitialized)
			{
				GetPlatform().CaptureException(errorMsg, type);
				GetPlatform().Flush();
			}
		}
		catch (...)
		{
			LOG(ERROR) << "Caught non-std::exception in terminate handler";
			if (g_sentryInitialized)
			{
				GetPlatform().CaptureException("Uncaught exception of unknown type", "unknown");
				GetPlatform().Flush();
			}
		}
	}
	else
	{
		LOG(ERROR) << "std::terminate called but current_exception() returned null - exception may have been unwound";
		if (g_sentryInitialized)
		{
			GetPlatform().CaptureException("std::terminate called (exception unwound)", "std::terminate");
			GetPlatform().Flush();
		}
	}
}

} // namespace

/*!
    Initializes Sentry for \a release and installs the logging integrations.
    Returns \c true on success.
*/
bool InitSentry(const QString & release)
{
	if (g_sentryInitialized)
		return true;

	if (!GetPlatform().Initialize(release))
		return false;

	g_sentryInitialized = true;
	InstallBreadcrumbSink();
	InstallExceptionHandler();
	LOG(INFO) << "Sentry integration installed (breadcrumbs + exception handler)";
	return true;
}

/*!
    Routes glog messages to Sentry breadcrumbs.
*/
void InstallBreadcrumbSink()
{
	if (!g_breadcrumbSink)
	{
		g_breadcrumbSink = std::make_unique<BreadcrumbSink>();
		google::AddLogSink(g_breadcrumbSink.get());
	}
}

/*!
    Installs the process-wide uncaught C++ exception handler.
*/
void InstallExceptionHandler()
{
	std::set_terminate(TerminateHandler);
}

} // namespace SentryIntegration

/*!
    \fn bool SentryIntegration::ISentry::Initialize(const QString &release)

    Initializes the platform Sentry SDK with \a release. Returns \c true on
    success.
*/

/*!
    \fn void SentryIntegration::ISentry::Shutdown()

    Shuts down the platform Sentry SDK.
*/

/*!
    \fn void SentryIntegration::ISentry::AddBreadcrumb(const std::string &message, const std::string &level)

    Records \a message as a breadcrumb at severity \a level.
*/

/*!
    \fn void SentryIntegration::ISentry::CaptureException(const QString &message, const QString &type)

    Reports an exception with \a message and \a type.
*/

/*!
    \fn void SentryIntegration::ISentry::Flush()

    Flushes pending Sentry events.
*/

/*!
    \fn SentryIntegration::ISentry &SentryIntegration::GetPlatform()

    Returns the platform-specific Sentry implementation.
*/
